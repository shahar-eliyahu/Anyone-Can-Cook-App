"""URL import: recipe extraction and SSRF protection, with no network access."""

import asyncio
import json

import httpx
import pytest

from app.config import Settings
from app.errors import ApiError
from app.services.url_fetcher import extract_recipe, fetch_recipe_page

SETTINGS = Settings(_env_file=None, url_max_bytes=50_000)

JSONLD_PAGE = """<html><head><title>עוגה | אתר מתכונים</title>
<meta property="og:site_name" content="אתר מתכונים">
<script type="application/ld+json">{data}</script></head>
<body><div class="ad">קנו עכשיו! מבצע!</div><p>סיפור ארוך על סבתא</p></body></html>"""

RECIPE_LD = {
    "@context": "https://schema.org",
    "@graph": [
        {"@type": "WebPage", "name": "עמוד"},
        {
            "@type": "Recipe",
            "name": "עוגת שוקולד",
            "recipeYield": "12 פרוסות",
            "cookTime": "PT35M",
            "recipeIngredient": ["200 גרם שוקולד", "3 ביצים", "1 כוס סוכר"],
            "recipeInstructions": [
                {"@type": "HowToStep", "text": "ממיסים את השוקולד."},
                {"@type": "HowToSection", "name": "אפייה", "itemListElement": [
                    {"@type": "HowToStep", "text": "אופים 35 דקות ב-180 מעלות."},
                ]},
            ],
        },
    ],
}

PLAIN_PAGE = "<html><head><title>מרק עדשים</title></head><body><nav>תפריט</nav><article><h1>מרק עדשים</h1>" + (
    "<p>משרים כוס עדשים כתומות במים קרים שעה. מטגנים בצל קצוץ בשתי כפות שמן עד שהוא שקוף. "
    "מוסיפים את העדשים, שישה כוסות מים וכפית כמון, ומבשלים חצי שעה על אש קטנה עד שהעדשים מתפרקות.</p>"
) * 2 + "</article><footer>כל הזכויות שמורות</footer></body></html>"


def public(host):
    async def resolve(_):
        return ["93.184.216.34"]
    return resolve


def resolver(ip):
    async def resolve(_):
        return [ip]
    return resolve


def transport(routes: dict[str, httpx.Response]):
    def handler(request: httpx.Request) -> httpx.Response:
        return routes.get(str(request.url), httpx.Response(404))
    return httpx.MockTransport(handler)


def fetch(url, routes, res=None):
    return asyncio.run(fetch_recipe_page(url, settings=SETTINGS, transport=transport(routes), resolver=res or public(url)))


def html(body: str, status=200):
    return httpx.Response(status, headers={"content-type": "text/html; charset=utf-8"}, content=body.encode())


def test_structured_recipe_is_extracted_without_ads():
    page = fetch("https://recipes.example/cake", {"https://recipes.example/cake": html(JSONLD_PAGE.format(data=json.dumps(RECIPE_LD, ensure_ascii=False)))})
    assert page.from_structured_data and page.title == "עוגת שוקולד" and page.site_name == "אתר מתכונים"
    for expected in ("200 גרם שוקולד", "אופים 35 דקות ב-180 מעלות.", "זמן בישול: 35 דקות", "12 פרוסות", "אפייה"):
        assert expected in page.text
    assert "קנו עכשיו" not in page.text and "סבתא" not in page.text


def test_plain_page_uses_main_text_extraction():
    page = fetch("https://blog.example/soup", {"https://blog.example/soup": html(PLAIN_PAGE)})
    assert not page.from_structured_data
    assert "עדשים" in page.text and "כל הזכויות שמורות" not in page.text


def test_page_without_recipe_content():
    with pytest.raises(ApiError) as e:
        fetch("https://x.example/", {"https://x.example/": html("<html><body>שלום</body></html>")})
    assert e.value.code == "no_recipe_found"


@pytest.mark.parametrize(
    "url",
    ["ftp://x.example/r", "file:///etc/passwd", "https://user:pw@x.example/", "https://x.example:8080/", "not a url"],
)
def test_bad_urls_are_rejected(url):
    with pytest.raises(ApiError) as e:
        fetch(url, {})
    assert e.value.code == "invalid_url"


@pytest.mark.parametrize("ip", ["127.0.0.1", "10.1.2.3", "192.168.1.5", "169.254.169.254", "::1", "fd00::1"])
def test_private_and_metadata_addresses_are_blocked(ip):
    with pytest.raises(ApiError) as e:
        fetch("https://internal.example/", {}, res=resolver(ip))
    assert e.value.code == "invalid_url"


def test_redirect_to_a_private_address_is_blocked():
    routes = {"https://ok.example/r": httpx.Response(302, headers={"location": "http://evil.example/admin"})}

    async def res(host):
        return ["93.184.216.34"] if host == "ok.example" else ["10.0.0.5"]

    with pytest.raises(ApiError) as e:
        fetch("https://ok.example/r", routes, res=res)
    assert e.value.code == "invalid_url"


def test_redirect_limit():
    routes = {f"https://a.example/{i}": httpx.Response(302, headers={"location": f"/{i + 1}"}) for i in range(10)}
    with pytest.raises(ApiError) as e:
        fetch("https://a.example/0", routes)
    assert e.value.code == "fetch_failed"


def test_size_and_type_limits():
    with pytest.raises(ApiError) as e:
        fetch("https://big.example/", {"https://big.example/": html("x" * 60_000)})
    assert e.value.code == "too_large"
    with pytest.raises(ApiError) as e:
        fetch("https://pdf.example/", {"https://pdf.example/": httpx.Response(200, headers={"content-type": "application/pdf"}, content=b"%PDF")})
    assert e.value.code == "fetch_failed"


def test_blocking_sites_are_reported():
    with pytest.raises(ApiError) as e:
        fetch("https://blocked.example/", {"https://blocked.example/": html("no", status=403)})
    assert e.value.code == "site_blocked"


def test_extract_recipe_handles_string_instructions():
    ld = {"@type": "Recipe", "name": "סלט", "recipeIngredient": ["מלפפון"], "recipeInstructions": "חותכים.\nמערבבים."}
    page = extract_recipe(JSONLD_PAGE.format(data=json.dumps(ld, ensure_ascii=False)), "https://s.example", max_chars=1000)
    assert "חותכים." in page.text and "מערבבים." in page.text


# ---- connect-time checks (DNS rebinding), with real sockets on 127.0.0.1 only -------------

import http.server
import threading

import httpcore

from app.services import url_fetcher
from app.services.url_fetcher import _PinnedBackend

PAGE = JSONLD_PAGE.format(data=json.dumps(RECIPE_LD, ensure_ascii=False)).encode()


class LocalServer:
    """A throwaway HTTP server on 127.0.0.1 that records every request it gets."""

    def __init__(self, routes: dict[str, tuple[int, dict, bytes]]):
        seen = self.requests = []

        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(self):
                seen.append((self.headers["Host"], self.path))
                status, headers, body = routes.get(self.path, (404, {}, b""))
                self.send_response(status)
                for k, v in headers.items():
                    self.send_header(k, v)
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def log_message(self, *args):
                pass

        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.port = self.server.server_address[1]
        threading.Thread(target=self.server.serve_forever, daemon=True).start()

    def close(self):
        self.server.shutdown()
        self.server.server_close()


@pytest.fixture
def server():
    s = LocalServer({
        "/cake": (200, {"Content-Type": "text/html; charset=utf-8"}, PAGE),
        "/to-internal": (302, {"Location": "http://internal.test/admin"}, b""),
        "/to-metadata": (302, {"Location": "http://169.254.169.254/latest/meta-data/"}, b""),
    })
    yield s
    s.close()


def real_fetch(url, res, port):
    """The production path (no mock transport). Port 80 in URLs is mapped to the test server."""
    original = httpcore.AnyIOBackend.connect_tcp

    async def to_test_port(self, host, _port, **kwargs):
        return await original(self, host, port, **kwargs)

    httpcore.AnyIOBackend.connect_tcp = to_test_port
    try:
        return asyncio.run(fetch_recipe_page(url, settings=SETTINGS, resolver=res))
    finally:
        httpcore.AnyIOBackend.connect_tcp = original


@pytest.fixture
def loopback_allowed(monkeypatch):
    """Treat 127.0.0.1 (the test server) as public; everything else keeps the real rules."""
    real = url_fetcher._is_public
    monkeypatch.setattr(url_fetcher, "_is_public", lambda a: a == "127.0.0.1" or real(a))


def test_dns_rebinding_is_blocked_at_connect_time(server):
    # First answer public (passes the early check), second answer the internal server.
    answers = iter([["93.184.216.34"], ["127.0.0.1"]])

    async def rebinding(_host):
        return next(answers)

    with pytest.raises(ApiError) as e:
        real_fetch("http://rebind.test/cake", rebinding, server.port)
    assert e.value.code == "invalid_url"
    assert server.requests == []  # never connected to the internal address


def test_connection_goes_to_the_checked_ip_and_keeps_the_host_header(server, loopback_allowed):
    calls = []

    async def res(host):
        calls.append(host)
        return ["127.0.0.1"]

    page = real_fetch("http://recipes.test/cake", res, server.port)
    assert page.title == "עוגת שוקולד"
    assert server.requests == [("recipes.test", "/cake")]
    assert calls == ["recipes.test", "recipes.test"]  # early check + the connect-time resolution


@pytest.mark.parametrize("path, target", [("/to-internal", "10.0.0.5"), ("/to-metadata", None)])
def test_redirects_to_internal_addresses_are_blocked_on_the_real_stack(server, loopback_allowed, path, target):
    async def res(host):
        return ["127.0.0.1"] if host == "recipes.test" else [target or host]

    with pytest.raises(ApiError) as e:
        real_fetch(f"http://recipes.test{path}", res, server.port)
    assert e.value.code == "invalid_url"
    assert server.requests == [("recipes.test", path)]  # only the first, public hop was fetched


class FakeStream(httpcore.AsyncNetworkStream):
    def __init__(self, peer):
        self.peer, self.closed = peer, False

    def get_extra_info(self, info):
        return self.peer if info == "server_addr" else None

    async def aclose(self):
        self.closed = True


class FakeBackend(httpcore.AsyncNetworkBackend):
    def __init__(self, peer):
        self.peer, self.connected_to, self.stream = peer, [], None

    async def connect_tcp(self, host, port, **kwargs):
        self.connected_to.append(host)
        self.stream = FakeStream(self.peer)
        return self.stream


def test_backend_connects_to_the_ip_literal_not_the_hostname():
    inner = FakeBackend(("93.184.216.34", 443))
    backend = _PinnedBackend(resolver("93.184.216.34"), inner)
    stream = asyncio.run(backend.connect_tcp("recipes.example", 443))
    assert inner.connected_to == ["93.184.216.34"] and stream is inner.stream


@pytest.mark.parametrize("peer", [("10.0.0.7", 443), ("93.184.216.99", 443), None])
def test_a_connected_peer_that_differs_or_is_private_is_refused(peer):
    inner = FakeBackend(peer)
    backend = _PinnedBackend(resolver("93.184.216.34"), inner)
    with pytest.raises(ApiError) as e:
        asyncio.run(backend.connect_tcp("recipes.example", 443))
    assert e.value.code == "invalid_url" and inner.stream.closed


def test_any_private_answer_blocks_the_host():
    async def mixed(_host):
        return ["93.184.216.34", "127.0.0.1"]

    inner = FakeBackend(("93.184.216.34", 443))
    with pytest.raises(ApiError):
        asyncio.run(_PinnedBackend(mixed, inner).connect_tcp("recipes.example", 443))
    assert inner.connected_to == []


@pytest.mark.parametrize(
    "ip", ["::ffff:127.0.0.1", "::ffff:10.0.0.1", "64:ff9b::a00:1", "100.64.0.1", "0.0.0.0", "224.0.0.1", "::"]
)
def test_mapped_nat64_cgnat_and_unspecified_addresses_are_blocked(ip):
    with pytest.raises(ApiError) as e:
        fetch("https://internal.example/", {}, res=resolver(ip))
    assert e.value.code == "invalid_url"


def test_slow_drip_pages_hit_the_total_deadline():
    async def drip():
        for _ in range(100):
            await asyncio.sleep(0.05)
            yield b"<p>x</p>"

    routes = {"https://slow.example/": httpx.Response(200, headers={"content-type": "text/html"}, content=drip())}
    settings = Settings(_env_file=None, url_fetch_timeout_seconds=0.1)
    with pytest.raises(ApiError) as e:
        asyncio.run(fetch_recipe_page("https://slow.example/", settings=settings, transport=transport(routes),
                                      resolver=public(None)))
    assert e.value.code == "timeout"


def test_proxy_environment_variables_are_ignored(server, monkeypatch):
    monkeypatch.setenv("HTTP_PROXY", f"http://127.0.0.1:{server.port}")
    monkeypatch.setenv("HTTPS_PROXY", f"http://127.0.0.1:{server.port}")
    with pytest.raises(ApiError):
        real_fetch("http://internal.test/cake", resolver("10.0.0.5"), server.port)
    assert server.requests == []


# --- Shared links: redirects, wrappers, refresh pages, bot checks (docs/DECISIONS.md #76) ---

RECIPE_HTML = JSONLD_PAGE.format(data=json.dumps(RECIPE_LD, ensure_ascii=False))
CHEF_URL = "https://chef.example/%D7%A2%D7%95%D7%92%D7%94/"
IMPERVA_PAGE = """<html><head><META NAME="robots" CONTENT="noindex,nofollow">
<script src="/_Incapsula_Resource?SWJIYLWA=5074a744e2e3d891814e9a2dace20bd4"></script>
<body></body></html>"""


def fetch_error(url, routes, res=None) -> ApiError:
    with pytest.raises(ApiError) as e:
        fetch(url, routes, res)
    return e.value


def test_a_google_share_link_is_followed_to_the_recipe():
    routes = {
        "https://share.google/abc123": httpx.Response(302, headers={"location": "https://www.google.com/share.google?q=abc123"}),
        "https://www.google.com/share.google?q=abc123": httpx.Response(301, headers={"location": CHEF_URL + "?shem=aimgspe,"}),
        CHEF_URL + "?shem=aimgspe,": html(RECIPE_HTML),
    }
    page = fetch("https://share.google/abc123", routes)
    assert page.title == "עוגת שוקולד" and page.final_url.startswith(CHEF_URL)


def test_five_hops_are_followed_and_a_sixth_is_refused():
    chain = {f"https://a.example/{i}": httpx.Response(302, headers={"location": f"/{i + 1}"}) for i in range(5)}
    assert fetch("https://a.example/0", {**chain, "https://a.example/5": html(RECIPE_HTML)}).title == "עוגת שוקולד"
    longer = {f"https://a.example/{i}": httpx.Response(302, headers={"location": f"/{i + 1}"}) for i in range(6)}
    assert fetch_error("https://a.example/0", {**longer, "https://a.example/6": html(RECIPE_HTML)}).code == "fetch_failed"


def test_a_bot_check_page_is_reported_as_blocked_with_where_the_link_led():
    routes = {
        "https://share.google/abc123": httpx.Response(302, headers={"location": CHEF_URL + "?shem=x&id=7"}),
        CHEF_URL + "?shem=x&id=7": html(IMPERVA_PAGE),
    }
    e = fetch_error("https://share.google/abc123", routes)
    assert e.code == "site_blocked" and "imperva" in e.detail
    assert e.extra == {"site": "chef.example", "resolved_url": CHEF_URL + "?id=7"}  # tracking dropped


@pytest.mark.parametrize("page,status", [
    ("<html><head><title>Just a moment...</title></head><body><script>cf_chl_opt={}</script></body></html>", 200),
    ("<html><body>blocked</body></html>", 403),
    ('<html><body><script src="https://geo.captcha-delivery.com/c.js"></script></body></html>', 200),
    ('<html><head><meta name="robots" content="noindex"></head><body><script src="/gate.js"></script></body></html>', 200),
])
def test_other_bot_checks_are_reported_as_blocked(page, status):
    e = fetch_error("https://site.example/r", {"https://site.example/r": html(page, status=status)})
    assert e.code == "site_blocked" and e.extra["site"] == "site.example"
    assert "resolved_url" not in e.extra  # the cook's own link


def test_a_real_recipe_page_with_protection_scripts_is_still_read():
    page = RECIPE_HTML.replace("</head>", '<script src="/cdn-cgi/challenge-platform/scripts/x.js"></script>'
                                          '<script>var incap_ses_1=1;</script></head>')
    assert fetch("https://site.example/r", {"https://site.example/r": html(page)}).title == "עוגת שוקולד"


def test_a_short_link_that_needs_a_browser_is_reported_as_unresolved():
    page = "<html><body><script>location.href='https://real.example/r'</script></body></html>"
    e = fetch_error("https://bit.ly/xyz", {"https://bit.ly/xyz": html(page)})
    assert e.code == "link_unresolved" and e.extra["site"] == "bit.ly"
    loop = {"https://share.google/x": httpx.Response(302, headers={"location": "https://share.google/x"})}
    assert fetch_error("https://share.google/x", loop).code == "link_unresolved"


def test_link_wrappers_are_unwrapped_without_a_request():
    wrapped = "https://www.google.com/url?q=https%3A%2F%2Fchef.example%2Fcake&sa=D"
    page = fetch(wrapped, {"https://chef.example/cake": html(RECIPE_HTML)})  # no route for google.com
    assert page.final_url == "https://chef.example/cake"
    fb = "https://l.facebook.com/l.php?u=https%3A%2F%2Fchef.example%2Fcake&h=AT0"
    assert fetch(fb, {"https://chef.example/cake": html(RECIPE_HTML)}).title == "עוגת שוקולד"


def test_unwrapped_and_refreshed_targets_keep_every_safety_check():
    async def res(host):
        return ["10.0.0.5"] if host == "internal.example" else ["93.184.216.34"]

    wrapped = "https://www.google.com/url?q=http%3A%2F%2Finternal.example%2Fadmin"
    assert fetch_error(wrapped, {}, res=res).code == "invalid_url"
    assert fetch_error("https://www.google.com/url?q=file:///etc/passwd", {}).code == "fetch_failed"  # not unwrapped
    refresh = '<html><head><meta http-equiv="refresh" content="0; url=http://internal.example/admin"></head></html>'
    assert fetch_error("https://r.example/", {"https://r.example/": html(refresh)}, res=res).code == "invalid_url"


def test_a_meta_refresh_redirect_page_is_followed_once_per_hop():
    refresh = "<html><head><meta content=\"0;URL='https://chef.example/cake'\" http-equiv=\"refresh\"></head></html>"
    page = fetch("https://r.example/", {"https://r.example/": html(refresh), "https://chef.example/cake": html(RECIPE_HTML)})
    assert page.final_url == "https://chef.example/cake"
    loop = '<html><head><meta http-equiv="refresh" content="0;url=/again"></head></html>'
    assert fetch_error("https://r.example/again", {"https://r.example/again": html(loop)}).code == "fetch_failed"


def test_a_big_page_with_an_auto_reload_is_not_treated_as_a_redirect():
    page = RECIPE_HTML.replace("</head>", '<meta http-equiv="refresh" content="300;url=/other">' + "<!-- x -->" * 3000 + "</head>")
    assert fetch("https://site.example/r", {"https://site.example/r": html(page)}).title == "עוגת שוקולד"
