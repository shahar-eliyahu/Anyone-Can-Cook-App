import pytest

from app.services.validation.numbers import (
    numbers_in,
    states_duration,
    states_number,
    states_temperature,
)


@pytest.mark.parametrize(
    "text,value",
    [
        ("500 גרם קמח", 500),
        ("1.5 כוסות", 1.5),
        ("1,5 כוסות", 1.5),
        ("1½ כפיות", 1.5),
        ("2 1/2 cups", 2.5),
        ("1/2 כוס", 0.5),
        ("½ כפית", 0.5),
        ("חצי כוס סוכר", 0.5),
        ("שתי ביצים", 2),
        ("שלוש כפות", 3),
        ("כוס וחצי מים", 1.5),
        ("2 כוסות וחצי", 2.5),
        ("ורבע כפית", 0.25),
    ],
)
def test_finds_stated_numbers(text, value):
    assert states_number(text, value), numbers_in(text)


def test_does_not_find_absent_numbers():
    assert not states_number("אופים עד שמזהיב", 35)
    assert not states_number("500 גרם קמח", 50)


@pytest.mark.parametrize(
    "text,seconds",
    [
        ("אופים 35 דקות", 35 * 60),
        ("מתפיחים שעה עד שעה וחצי", 3600),
        ("מתפיחים שעה עד שעה וחצי", 5400),
        ("מצננים 2 שעות", 7200),
        ("חצי שעה במקרר", 1800),
        ("שעתיים בתנור", 7200),
    ],
)
def test_finds_stated_durations(text, seconds):
    assert states_duration(text, seconds)


def test_duration_not_stated():
    assert not states_duration("אופים עד שמזהיב", 2100)


def test_temperature_in_celsius_or_fahrenheit():
    assert states_temperature("תנור שחומם ל-200 מעלות", 200)
    assert states_temperature("bake at 350°F", 177)
    assert not states_temperature("bake until golden", 180)
