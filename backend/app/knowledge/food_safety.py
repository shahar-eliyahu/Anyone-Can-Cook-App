"""Curated food-safety reference values (deterministic, cited, never AI-generated).

Values are the USDA FSIS safe minimum internal temperatures, converted to °C and
rounded to the nearest degree. Verified on 2026-10-24 against search results that
quote the official FSIS chart (direct page fetches were blocked; re-check the live
chart before release). The Israeli Ministry of Health's general guidance (cook to
70 °C at the center, juices of meat and poultry run clear, use a thermometer) is
cited as a general reference; where FSIS is more specific and higher, FSIS is used.

Wording shown to users never claims a dish is guaranteed safe.
"""

from dataclasses import dataclass
from typing import Literal

from app.schemas.analysis import ReferenceSource

SafetyFood = Literal["poultry", "ground_meat", "whole_cut_meat", "fish", "egg_dish", "leftovers"]

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
    min_internal_c: int
    min_internal_f: int
    rest_minutes: int
    check_cue_he: str
    source_ids: tuple[str, ...]


REFERENCES: dict[SafetyFood, SafetyReference] = {
    r.food: r
    for r in (
        SafetyReference(
            "poultry", "עוף והודו (כולל טחון)", 74, 165, 0,
            "בדקו במדחום בחלק העבה ביותר: לפחות 74°C. הנוזלים שקופים ולא ורודים.",
            (FSIS_SOURCE.id, IL_MOH_SOURCE.id),
        ),
        SafetyReference(
            "ground_meat", "בשר טחון (בקר, טלה, חזיר)", 71, 160, 0,
            "בדקו במדחום במרכז: לפחות 71°C. הצבע לבדו אינו סימן אמין.",
            (FSIS_SOURCE.id, IL_MOH_SOURCE.id),
        ),
        SafetyReference(
            "whole_cut_meat", "נתחים שלמים: סטייק, צלעות, צלי", 63, 145, 3,
            "בדקו במדחום במרכז: לפחות 63°C, ואז מנוחה של 3 דקות לפחות.",
            (FSIS_SOURCE.id,),
        ),
        SafetyReference(
            "fish", "דגים", 63, 145, 0,
            "בדקו במדחום: לפחות 63°C, או עד שהבשר אטום ומתפרק בקלות במזלג.",
            (FSIS_SOURCE.id,),
        ),
        SafetyReference(
            "egg_dish", "מאכלי ביצים (פריטטה, קיש)", 71, 160, 0,
            "בדקו במדחום במרכז: לפחות 71°C. הביצים יציבות ולא נוזליות.",
            (FSIS_SOURCE.id,),
        ),
        SafetyReference(
            "leftovers", "שאריות ותבשילים מוכנים (חימום חוזר)", 74, 165, 0,
            "חממו עד שהמרכז מגיע ל-74°C לפחות.",
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
