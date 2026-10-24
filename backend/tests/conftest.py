"""Guards for every test: no real Gemini client and no network beyond this machine.

Automated tests must never spend Gemini quota (docs/DECISIONS.md #27). Tests use
FakeProvider/MockProvider; these guards turn any slip into a loud failure.
"""

import ipaddress
import socket

import pytest


class RealNetworkUsed(AssertionError):
    pass


def _loopback(address) -> bool:
    host = address[0] if isinstance(address, tuple) else address
    try:
        return ipaddress.ip_address(str(host).split("%")[0]).is_loopback
    except ValueError:
        return str(host) == "localhost"


@pytest.fixture(autouse=True)
def no_real_ai_or_network(monkeypatch):
    from google import genai

    def no_client(*args, **kwargs):
        raise RealNetworkUsed("a real Gemini client was created in a test")

    monkeypatch.setattr(genai, "Client", no_client)

    real_connect, real_connect_ex = socket.socket.connect, socket.socket.connect_ex

    def connect(self, address):
        if self.family in (socket.AF_INET, socket.AF_INET6) and not _loopback(address):
            raise RealNetworkUsed(f"network connection attempted to {address!r}")
        return real_connect(self, address)

    def connect_ex(self, address):
        if self.family in (socket.AF_INET, socket.AF_INET6) and not _loopback(address):
            raise RealNetworkUsed(f"network connection attempted to {address!r}")
        return real_connect_ex(self, address)

    monkeypatch.setattr(socket.socket, "connect", connect)
    monkeypatch.setattr(socket.socket, "connect_ex", connect_ex)

