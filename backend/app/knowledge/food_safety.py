"""Curated food-safety reference values (deterministic, cited, never AI-generated).

Values are the USDA FSIS safe minimum internal temperatures, converted to °C and
rounded to the nearest degree. Verified on 2026-10-24 against search results that
quote the official FSIS chart (direct page fetches were blocked; re-check the live
chart before release). The Israeli Ministry of Health's general guidance (cook to
70 °C at the center, juices of meat and poultry run clear, use a thermometer) is
cited as a general reference; where FSIS is more specific and higher, FSIS is used.

Wording shown to users never claims a dish is guaranteed safe. Cues are short and
practical (docs/DECISIONS.md #37): observable signs first; a thermometer is mentioned
only for high-risk foods (poultry, ground meat), as the accurate check, and appearance is
never presented as reliable where it isn't. Stovetop eggs (omelette, scrambled, fried)
are cooked "until set" (FSIS: until yolk and white are firm); the 160 °F / 71 °C value is
for baked egg dishes (casseroles, quiche).
"""

from dataclasses import dataclass
from typing import Literal

from app.schemas.analysis import ReferenceSource

SafetyFood = Literal[
    "poultry", "ground_meat", "whole_cut_meat", "fish", "egg_dish", "eggs_stovetop", "leftovers"
]

FSIS_SOURCE = ReferenceSource(
    id="ref_fsis_temps",
    title="USDA FSIS — Safe Minimum Internal Temperature Chart",
    url="https://www.fsis.usda.gov/food-safety/safe-food-handling-and-preparation/food-safety-basics/safe-temperature-chart",
    kind="food_safety_reference",
)

IL_MOH_SOURCE = ReferenceSource(
    id="ref_il_moh_5keys",
    title="משרד הבריאות — חמשת המפתחות לבטיחות מזון",
    url="https://www.gov.il/BlobFolder/reports/safetyfood-5keys/he/files_publications_MISC_Safetyfood_5keys.pdf",
    kind="food_safety_reference",
)


@dataclass(frozen=True)
class SafetyReference:
    food: SafetyFood
    label_he: str
    min_internal_c: int | None  # None: no temperature check for this food (stovetop eggs)
    min_internal_f: int | None
    rest_minutes: int
    check_cue_he: str  # one short, practical sentence shown to the cook
    source_ids: tuple[str, ...]
    # High risk: the cue is shown as a short warning and the cook confirms doneness.
    high_risk: bool = False


REFERENCES: dict[SafetyFood, SafetyReference] = {
    r.food: r
    for r in (
        SafetyReference(
            "poultry", "עוף והודו (כולל טחון)", 74, 165, 0,
            "חתכו בחלק העבה: אין ורוד והנוזלים שקופים. הבדיקה המדויקת: מדחום, לפחות 74°C.",
            (FSIS_SOURCE.id, IL_MOH_SOURCE.id),
            high_risk=True,
        ),
        SafetyReference(
            "ground_meat", "בשר טחון (בקר, טלה, חזיר)", 71, 160, 0,
            "מבשלים עד שאין ורוד בפנים; הצבע לבדו לא תמיד אמין, ולכן הכי בטוח מדחום: לפחות 71°C במרכז.",
            (FSIS_SOURCE.id, IL_MOH_SOURCE.id),
            high_risk=True,
        ),
        SafetyReference(
            "whole_cut_meat", "נתחים שלמים: סטייק, צלעות, צלי", 63, 145, 3,
            "לפני ההגשה נותנים לבשר לנוח כ-3 דקות.",
            (FSIS_SOURCE.id,),
        ),
        SafetyReference(
            "fish", "דגים", 63, 145, 0,
            "הדג מוכן כשהוא אטום ומתפרק בקלות במזלג.",
            (FSIS_SOURCE.id,),
        ),
        SafetyReference(
            "egg_dish", "מאכלי ביצים אפויים (קיש, פשטידה, פריטטה בתנור)", 71, 160, 0,
            "המרכז יציב, וסכין שננעצת במרכז יוצאת נקייה.",
            (FSIS_SOURCE.id,),
        ),
        SafetyReference(
            "eggs_stovetop", "ביצים במחבת (חביתה, ביצה מקושקשת, ביצת עין)", None, None, 0,
            "מבשלים עד שהביצה יציבה ואין חלקים נוזליים.",
            (FSIS_SOURCE.id,),
        ),
        SafetyReference(
            "leftovers", "שאריות ותבשילים מוכנים (חימום חוזר)", 74, 165, 0,
            "מחממים עד שהכול חם מאוד ומהביל, גם במרכז.",
            (FSIS_SOURCE.id,),
        ),
    )
}

SOURCES = {s.id: s for s in (FSIS_SOURCE, IL_MOH_SOURCE)}

# Home preserving needs tested, validated recipes; the app never schedules it from estimates.
UNSCHEDULABLE_HE = (
    "שימורים ביתיים (צנצנות, ריבות לשימור ארוך, כבישה לאחסון ממושך) דורשים מתכון בדוק ומאומת. "
    "לא נבנה עבור זה תזמון על סמך הערכה."
)


def reference_for(food: str | None) -> SafetyReference | None:
    return REFERENCES.get(food) if food else None  # type: ignore[arg-type]
