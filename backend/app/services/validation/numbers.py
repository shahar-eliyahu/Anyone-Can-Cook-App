"""Finds the numbers a recipe text states, including Hebrew number words and fractions.

Used to verify that a value tagged "original" really appears in the source.
"""

import re

_UNICODE_FRACTIONS = {"½": 0.5, "¼": 0.25, "¾": 0.75, "⅓": 1 / 3, "⅔": 2 / 3, "⅛": 0.125}

_HEBREW_WORDS = {
    "חצי": 0.5, "רבע": 0.25, "שליש": 1 / 3,
    "אחד": 1, "אחת": 1, "שניים": 2, "שתיים": 2, "שני": 2, "שתי": 2,
    "שלוש": 3, "שלושה": 3, "ארבע": 4, "ארבעה": 4, "חמש": 5, "חמישה": 5,
    "שש": 6, "שישה": 6, "שבע": 7, "שבעה": 7, "שמונה": 8, "תשע": 9, "תשעה": 9,
    "עשר": 10, "עשרה": 10, "עשרים": 20, "שלושים": 30, "ארבעים": 40, "חמישים": 50,
    "שישים": 60, "תשעים": 90, "מאה": 100, "מאתיים": 200,
}

# Time words that imply a number of minutes.
_TIME_WORDS_MINUTES = {
    "חצי שעה": 30, "רבע שעה": 15, "שלושת רבעי שעה": 45, "שעה וחצי": 90, "שעתיים": 120,
    "שעה ורבע": 75, "דקה": 1, "שעה": 60,
}

_NUMBER = re.compile(r"(\d+)\s*([½¼¾⅓⅔⅛])|(\d+)\s+(\d+)/(\d+)|(\d+)/(\d+)|(\d+(?:[.,]\d+)?)|([½¼¾⅓⅔⅛])")


def numbers_in(text: str) -> set[float]:
    """Every number stated in [text], as floats rounded to 3 decimals."""
    found: set[float] = set()
    for m in _NUMBER.finditer(text):
        if m.group(1):
            found.add(int(m.group(1)) + _UNICODE_FRACTIONS[m.group(2)])
        elif m.group(3):
            found.add(int(m.group(3)) + int(m.group(4)) / int(m.group(5)))
        elif m.group(6):
            if int(m.group(7)):
                found.add(int(m.group(6)) / int(m.group(7)))
        elif m.group(8):
            found.add(float(m.group(8).replace(",", ".")))
        elif m.group(9):
            found.add(_UNICODE_FRACTIONS[m.group(9)])
    words = re.findall(r"[֐-׿]+", text)
    for i, w in enumerate(words):
        base = w[1:] if w.startswith(("ו", "ב", "ל", "כ")) and w[1:] in _HEBREW_WORDS else w
        if base in _HEBREW_WORDS:
            found.add(_HEBREW_WORDS[base])
        # "כוס וחצי", "שעה וחצי": one and a half
        if w == "וחצי":
            found.add(1.5)
            prev = words[i - 1] if i else ""
            if prev in _HEBREW_WORDS:
                found.add(_HEBREW_WORDS[prev] + 0.5)
    for d in re.findall(r"(\d+)\s*(?:\S+\s+)?וחצי", text):
        found.add(int(d) + 0.5)
    return {round(n, 3) for n in found}


def minutes_in(text: str) -> set[float]:
    """Durations in minutes the text states, from numbers and time words."""
    result = set(numbers_in(text))
    hours = {round(n * 60, 3) for n in numbers_in(text)}
    result |= hours  # "2 שעות" → 120 minutes
    for phrase, minutes in _TIME_WORDS_MINUTES.items():
        if phrase in text:
            result.add(float(minutes))
    return result


def states_number(text: str, value: float) -> bool:
    return round(value, 3) in numbers_in(text)


def states_duration(text: str, seconds: int) -> bool:
    return round(seconds / 60, 3) in minutes_in(text)


def states_temperature(text: str, celsius: int) -> bool:
    """True if [celsius] is written, or is a conversion of a written °F value
    (recipes round conversions differently: 350°F → 175/177/180°C)."""
    nums = numbers_in(text)
    if float(celsius) in nums:
        return True
    return any(n >= 200 and abs((n - 32) * 5 / 9 - celsius) <= 3 for n in nums)
