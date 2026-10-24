"""Structural checks on a CookingPlan; mirrors app/lib/features/cooking/engine/plan_validator.dart."""

from app.schemas.plan import CookingPlan
from app.schemas.recipe import Recipe


def _depends_on(plan: CookingPlan, start: str, target: str) -> bool:
    deps = {s.id: s.depends_on for s in plan.steps}
    seen: set[str] = set()
    stack = [start]
    while stack:
        current = stack.pop()
        if current in seen:
            continue
        seen.add(current)
        for d in deps.get(current, []):
            if d == target:
                return True
            stack.append(d)
    return False


def _has_cycle(plan: CookingPlan) -> bool:
    deps = {s.id: s.depends_on for s in plan.steps}
    visiting: set[str] = set()
    done: set[str] = set()

    def visit(node: str) -> bool:
        if node in done:
            return False
        if node in visiting:
            return True
        visiting.add(node)
        if any(d in deps and visit(d) for d in deps[node]):
            return True
        visiting.discard(node)
        done.add(node)
        return False

    return any(visit(n) for n in deps)


def plan_problems(plan: CookingPlan, recipe: Recipe | None = None) -> list[str]:
    problems: list[str] = []
    step_ids: set[str] = set()
    timer_ids: set[str] = set()
    for s in plan.steps:
        if s.id in step_ids:
            problems.append(f"duplicate step id {s.id}")
        step_ids.add(s.id)
        for t in s.timers:
            if t.id in timer_ids:
                problems.append(f"duplicate timer id {t.id}")
            timer_ids.add(t.id)
    for p in plan.prep_tasks:
        if p.timer is not None:
            if p.timer.id in timer_ids:
                problems.append(f"duplicate timer id {p.timer.id}")
            timer_ids.add(p.timer.id)
    prep_ids = [p.id for p in plan.prep_tasks]
    if len(set(prep_ids)) != len(prep_ids):
        problems.append("duplicate prep task id")

    for s in plan.steps:
        action_ids = [a.id for a in s.actions]
        if len(set(action_ids)) != len(action_ids):
            problems.append(f"{s.id}: duplicate action id")
        completing = [a for a in s.actions if a.completes_step]
        if len(completing) != 1:
            problems.append(f"{s.id}: needs exactly one completing action")
        elif s.actions[-1] is not completing[0]:
            problems.append(f"{s.id}: completing action must be last")
        elif completing[0].starts_timer:
            problems.append(f"{s.id}: completing action cannot start a timer")
        own_timers = {t.id for t in s.timers}
        for a in s.actions:
            if a.starts_timer and a.starts_timer not in own_timers:
                problems.append(f"{s.id}.{a.id}: starts unknown timer {a.starts_timer}")
        for d in s.depends_on:
            if d == s.id:
                problems.append(f"{s.id}: depends on itself")
            elif d not in step_ids:
                problems.append(f"{s.id}: unknown dependency {d}")
        for t in s.timers:
            for sid in t.suggest_during:
                if sid in prep_ids:
                    continue
                if sid not in step_ids:
                    problems.append(f"{t.id}: suggests unknown {sid}")
                elif sid == s.id or _depends_on(plan, sid, s.id):
                    problems.append(f"{t.id}: suggests {sid}, which waits for {s.id}")
    if _has_cycle(plan):
        problems.append("dependency cycle")
    for p in plan.prep_tasks:
        for ref in (p.needed_by_step, p.surface.with_step):
            if ref and ref not in step_ids:
                problems.append(f"{p.id}: unknown step {ref}")

    if recipe is not None:
        ingredients = {i.id for i in recipe.ingredients}
        equipment = {e.id for e in recipe.equipment}
        sources = {s.id for s in recipe.source_steps}
        for s in plan.steps:
            for iid in [*s.ingredient_ids, *(u.ingredient_id for u in s.ingredient_uses)]:
                if iid not in ingredients:
                    problems.append(f"{s.id}: unknown ingredient {iid}")
            for eid in s.equipment_ids:
                if eid not in equipment:
                    problems.append(f"{s.id}: unknown equipment {eid}")
            for ref in s.source_refs:
                if ref not in sources:
                    problems.append(f"{s.id}: unknown source step {ref}")
    return problems
