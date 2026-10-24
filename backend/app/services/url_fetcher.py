"""Fetches a user-provided recipe page safely and extracts only the recipe.

A plain function, reusable by future recipe discovery (docs/PLAN.md, "Later").

Safety (SSRF): http/https on default ports only, no credentials in URLs, and every
address a host resolves to must be public (blocks private, loopback, link-local,
carrier-grade NAT, metadata and IPv4-mapped/NAT64 forms of those). The check happens
where the connection is made: `_PinnedBackend` resolves the host once, connects to that
checked IP itself (so a second, different DNS answer can't redirect the connection:
DNS rebinding), and then verifies the socket's actual peer address. TLS still uses the
hostname for SNI and certificate checks. Redirects are followed manually (max 3); each
hop is a new origin, re-checked and connected the same way. Environment proxies are
ignored, and the body is capped in size and in total time.
"""

import asyncio
import ipaddress
import json
import re
import socket
from dataclasses import dataclass
from urllib.parse import SplitResult, urljoin, urlsplit

import httpcore
import httpx

from app.config import Settings
from app.errors import ApiError

MAX_REDIRECTS = 3
MIN_TEXT_CHARS = 120
_USER_AGENT = "Mozilla/5.0 (compatible; AnyoneCanCookRecipeImport/1.0)"


@dataclass
class FetchedPage:
    final_url: str
    site_name: str | None
    title: str | None
    text: str
    from_structured_data: bool



_NAT64 = ipaddress.ip_network("64:ff9b::/96")


def _is_public(address: str) -> bool:
    ip = ipaddress.ip_address(address.split("%")[0])
    if ip.version == 6:
        if ip.ipv4_mapped is not None:
            ip = ip.ipv4_mapped
        elif ip in _NAT64:  # translated to the embedded IPv4 address by a NAT64 gateway
            ip = ipaddress.ip_address(int(ip) & 0xFFFFFFFF)
    return ip.is_global and not ip.is_multicast


async def _resolve(host: str) -> list[str]:
    infos = await asyncio.get_running_loop().getaddrinfo(host, None, type=socket.SOCK_STREAM)
    return sorted({info[4][0] for info in infos})


def _check_url(url: str) -> SplitResult:
    try:
        parts = urlsplit(url.strip())
    except ValueError as e:
        raise ApiError(422, "invalid_url") from e
    if parts.scheme not in ("http", "https") or not parts.hostname:
        raise ApiError(422, "invalid_url")
    if parts.username or parts.password:
        raise ApiError(422, "invalid_url", "credentials in URL")
    if parts.port not in (None, 80, 443):
        raise ApiError(422, "invalid_url", "non-default port")
    return parts


async def _checked_addresses(host: str, resolver) -> list[str]:
    try:
        addresses = await resolver(host)
    except OSError as e:
        raise ApiError(422, "fetch_failed", "host not found") from e
    if not addresses:
        raise ApiError(422, "fetch_failed", "host not found")
    if not all(_is_public(a) for a in addresses):
        raise ApiError(422, "invalid_url", "address not allowed")
    return addresses


class _PinnedBackend(httpcore.AsyncNetworkBackend):
    """Connects only to addresses checked at connect time, and verifies the real peer."""

    def __init__(self, resolver, inner: httpcore.AsyncNetworkBackend | None = None) -> None:
        self._resolver = resolver
        self._inner = inner or httpcore.AnyIOBackend()

    async def connect_tcp(self, host, port, timeout=None, local_address=None, socket_options=None):
        error: Exception | None = None
        for address in await _checked_addresses(host, self._resolver):
            try:
                stream = await self._inner.connect_tcp(
                    address, port, timeout=timeout, local_address=local_address, socket_options=socket_options
                )
            except httpcore.ConnectError as e:
                error = e
                continue
            peer = stream.get_extra_info("server_addr")
            peer_ip = peer[0] if isinstance(peer, tuple) and peer else None
            if (
                peer_ip is None
                or ipaddress.ip_address(peer_ip.split("%")[0]) != ipaddress.ip_address(address.split("%")[0])
                or not _is_public(peer_ip)
            ):
                await stream.aclose()
                raise ApiError(422, "invalid_url", "connected address not allowed")
            return stream
        raise error or httpcore.ConnectError("no address to connect to")

    async def sleep(self, seconds: float) -> None:
        await self._inner.sleep(seconds)


def _pinned_transport(resolver) -> httpx.AsyncHTTPTransport:
    transport = httpx.AsyncHTTPTransport(trust_env=False, retries=0)
    # httpx has no public hook for the network backend; its transport wraps this pool.
    transport._pool = httpcore.AsyncConnectionPool(
        ssl_context=httpx.create_ssl_context(trust_env=False),
        max_connections=4,
        network_backend=_PinnedBackend(resolver),
    )
    return transport


async def fetch_recipe_page(
    url: str,
    *,
    settings: Settings,
    transport: httpx.AsyncBaseTransport | None = None,
    resolver=_resolve,
) -> FetchedPage:
    """`transport` is for tests only; production connections go through `_PinnedBackend`."""
    try:
        async with asyncio.timeout(settings.url_fetch_timeout_seconds * 2):  # total, against slow drip
            return await _fetch(url.strip(), settings, transport or _pinned_transport(resolver), resolver)
    except TimeoutError as e:
        raise ApiError(504, "timeout", "page fetch timed out") from e


async def _fetch(current: str, settings: Settings, transport: httpx.AsyncBaseTransport, resolver) -> FetchedPage:
    async with httpx.AsyncClient(
        transport=transport,
        trust_env=False,
        follow_redirects=False,
        timeout=settings.url_fetch_timeout_seconds,
        headers={"User-Agent": _USER_AGENT, "Accept": "text/html,application/xhtml+xml"},
    ) as client:
        for _ in range(MAX_REDIRECTS + 1):
            parts = _check_url(current)
            # Early, friendly rejection; the binding check is at connect time (_PinnedBackend).
            await _checked_addresses(parts.hostname, resolver)
            try:
                async with client.stream("GET", current) as response:
                    if response.is_redirect:
                        location = response.headers.get("location")
                        if not location:
                            raise ApiError(422, "fetch_failed", "redirect without location")
                        current = urljoin(current, location)
                        continue
                    if response.status_code in (401, 403, 429, 451, 503):
                        raise ApiError(422, "site_blocked", f"http {response.status_code}")
                    if response.status_code >= 400:
                        raise ApiError(422, "fetch_failed", f"http {response.status_code}")
                    ctype = response.headers.get("content-type", "")
                    if "html" not in ctype:
                        raise ApiError(422, "fetch_failed", "not an html page")
                    body = bytearray()
                    async for chunk in response.aiter_bytes():
                        body.extend(chunk)
                        if len(body) > settings.url_max_bytes:
                            raise ApiError(413, "too_large", "page too large")
                    html = body.decode(response.encoding or "utf-8", errors="replace")
            except httpx.TimeoutException as e:
                raise ApiError(504, "timeout", "page fetch timed out") from e
            except httpx.HTTPError as e:
                raise ApiError(422, "fetch_failed", type(e).__name__) from e
            return extract_recipe(html, current, max_chars=settings.max_text_chars)
    raise ApiError(422, "fetch_failed", "too many redirects")


def extract_recipe(html: str, url: str, *, max_chars: int) -> FetchedPage:
    """schema.org Recipe JSON-LD first; otherwise the page's main text."""
    site = _meta(html, "og:site_name") or urlsplit(url).hostname
    recipe = _jsonld_recipe(html)
    # Structured data is trusted when it has ingredients and instructions, however short.
    if recipe is not None and (recipe.get("recipeIngredient") or recipe.get("ingredients")) and _instructions(
        recipe.get("recipeInstructions")
    ):
        text = _recipe_text(recipe)
        return FetchedPage(url, site, _clean(recipe.get("name")) or _title(html), text[:max_chars], True)
    import trafilatura

    text = trafilatura.extract(html, include_comments=False, include_tables=True, favor_precision=True) or ""
    if len(text) < MIN_TEXT_CHARS:
        raise ApiError(422, "no_recipe_found", "no recipe content on the page")
    return FetchedPage(url, site, _meta(html, "og:title") or _title(html), text[:max_chars], False)


def _meta(html: str, prop: str) -> str | None:
    m = re.search(
        rf'<meta[^>]+(?:property|name)=["\']{re.escape(prop)}["\'][^>]*content=["\']([^"\']+)', html, re.I
    )
    return _clean(m.group(1)) if m else None


def _title(html: str) -> str | None:
    m = re.search(r"<title[^>]*>(.*?)</title>", html, re.I | re.S)
    return _clean(m.group(1)) if m else None


def _clean(value) -> str | None:
    if not isinstance(value, str):
        return None
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", value)).strip() or None


def _jsonld_recipe(html: str) -> dict | None:
    for block in re.findall(r'<script[^>]+type=["\']application/ld\+json["\'][^>]*>(.*?)</script>', html, re.I | re.S):
        try:
            data = json.loads(block.strip())
        except json.JSONDecodeError:
            continue
        stack = [data]
        while stack:
            node = stack.pop()
            if isinstance(node, list):
                stack.extend(node)
            elif isinstance(node, dict):
                kind = node.get("@type")
                kinds = kind if isinstance(kind, list) else [kind]
                if "Recipe" in kinds:
                    return node
                stack.extend(v for k, v in node.items() if k in ("@graph", "mainEntity", "itemListElement"))
    return None


_ISO_DURATION = re.compile(r"P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?")


def _duration_he(value) -> str | None:
    m = _ISO_DURATION.fullmatch(value) if isinstance(value, str) else None
    if not m or not any(m.groups()):
        return None
    days, hours, minutes = (int(g or 0) for g in m.groups())
    total = days * 1440 + hours * 60 + minutes
    return f"{total} דקות"


def _recipe_text(r: dict) -> str:
    lines: list[str] = []
    if name := _clean(r.get("name")):
        lines.append(name)
    yld = r.get("recipeYield")
    if yld:
        lines.append(f"כמות: {_clean(yld if isinstance(yld, str) else ' '.join(map(str, yld if isinstance(yld, list) else [yld])))}")
    for key, label in (("prepTime", "זמן הכנה"), ("cookTime", "זמן בישול"), ("totalTime", "זמן כולל")):
        if d := _duration_he(r.get(key)):
            lines.append(f"{label}: {d}")
    ingredients = r.get("recipeIngredient") or r.get("ingredients") or []
    if ingredients:
        lines.append("מצרכים:")
        lines += [f"- {_clean(i)}" for i in ingredients if _clean(i)]
    lines.append("הוראות:")
    lines += _instructions(r.get("recipeInstructions"))
    return "\n".join(lines)


def _instructions(node) -> list[str]:
    if isinstance(node, str):
        return [t for t in (_clean(x) for x in re.split(r"\n+", node)) if t]
    if isinstance(node, list):
        return [line for item in node for line in _instructions(item)]
    if isinstance(node, dict):
        if node.get("@type") == "HowToSection":
            head = [_clean(node.get("name"))] if _clean(node.get("name")) else []
            return head + _instructions(node.get("itemListElement"))
        text = _clean(node.get("text")) or _clean(node.get("name"))
        return [text] if text else []
    return []
