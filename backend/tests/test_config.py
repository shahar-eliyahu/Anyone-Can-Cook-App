from app.config import Settings


def test_per_endpoint_models_fall_back_to_ai_model():
    settings = Settings(_env_file=None, ai_model="base-model")
    assert settings.effective_parse_model == "base-model"
    assert settings.effective_plan_model == "base-model"
    assert settings.effective_chat_model == "base-model"


def test_per_endpoint_models_override_ai_model():
    settings = Settings(
        _env_file=None,
        ai_model="base-model",
        parse_model="parse-model",
        plan_model="plan-model",
        chat_model="chat-model",
    )
    assert settings.effective_parse_model == "parse-model"
    assert settings.effective_plan_model == "plan-model"
    assert settings.effective_chat_model == "chat-model"


def test_unknown_env_vars_are_ignored(monkeypatch):
    # e.g. a leftover AI_CHECK_TOKEN on Render must not break startup
    monkeypatch.setenv("AI_CHECK_TOKEN", "leftover")
    Settings(_env_file=None)
