from fastapi.testclient import TestClient

from app.main import app
from app.services.llm import get_llm_provider
from app.services.llm.mock import MockProvider


def test_health_reports_ok_and_provider():
    app.dependency_overrides[get_llm_provider] = MockProvider
    try:
        response = TestClient(app).get("/health")
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["ai_provider"] == "mock"
