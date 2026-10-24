import '../../models/cooking_plan.dart';
import '../../models/recipe.dart';
import 'patch.dart';

enum ItemKind { ingredient, equipment }

enum ItemStatus { unknown, have, missing }

enum SubstitutionSource { local, ai }

/// An answer for a missing item, from the local table or the server (not yet accepted).
class SubstitutionProposal {
  const SubstitutionProposal({
    required this.verdict,
    required this.explanationHe,
    required this.source,
    this.replacementNameHe,
    this.effectsHe,
    this.ops = const [],
  });

  factory SubstitutionProposal.fromJson(Map<String, dynamic> j, SubstitutionSource source) => SubstitutionProposal(
        verdict: j['verdict'] as String,
        explanationHe: j['explanation_he'] as String,
        replacementNameHe: j['replacement_name_he'] as String?,
        effectsHe: j['effects_he'] as String?,
        ops: [for (final o in j['ops'] as List? ?? const []) Map<String, dynamic>.from(o as Map)],
        source: source,
      );

  /// works / changes_result / not_recommended / no_substitute
  final String verdict;
  final String explanationHe;
  final String? replacementNameHe;
  final String? effectsHe;
  final List<PatchOp> ops;
  final SubstitutionSource source;

  bool get canApply => ops.isNotEmpty && (verdict == 'works' || verdict == 'changes_result');
}

/// An accepted substitution: what it replaced and the operations it applied.
class Substitution {
  const Substitution({
    required this.id,
    required this.kind,
    required this.targetId,
    required this.targetName,
    required this.labelHe,
    required this.verdict,
    required this.source,
    required this.ops,
    this.effectsHe,
    this.locked = false,
  });

  factory Substitution.fromJson(Map<String, dynamic> j) => Substitution(
        id: j['id'] as String,
        kind: ItemKind.values.byName(j['kind'] as String),
        targetId: j['target_id'] as String,
        targetName: j['target_name'] as String,
        labelHe: j['label_he'] as String,
        verdict: j['verdict'] as String,
        source: SubstitutionSource.values.byName(j['source'] as String),
        ops: [for (final o in j['ops'] as List? ?? const []) Map<String, dynamic>.from(o as Map)],
        effectsHe: j['effects_he'] as String?,
        locked: j['locked'] as bool? ?? false,
      );

  final String id;
  final ItemKind kind;
  final String targetId;
  final String targetName;

  /// "חלב וחמאה" or "בלי פלפל שחור".
  final String labelHe;
  final String verdict;
  final SubstitutionSource source;
  final List<PatchOp> ops;
  final String? effectsHe;

  /// Baked into the recipe after advanced editing: shown, but no longer undoable.
  final bool locked;

  Substitution lock() => Substitution(
        id: id, kind: kind, targetId: targetId, targetName: targetName, labelHe: labelHe,
        verdict: verdict, source: source, ops: ops, effectsHe: effectsHe, locked: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'target_id': targetId,
        'target_name': targetName,
        'label_he': labelHe,
        'verdict': verdict,
        'source': source.name,
        'ops': ops,
        'effects_he': effectsHe,
        'locked': locked,
      };
}

/// The cook's preparation of one recipe: what they have, what is missing, accepted
/// substitutions, and the original recipe and plan they apply to. Stored in the
/// recipe's `analysis_json` under "preparation" (no database migration).
class Preparation {
  const Preparation({
    this.items = const {},
    this.substitutions = const [],
    this.baseRecipe,
    this.basePlan,
  });

  factory Preparation.fromJson(Map<String, dynamic> j) => Preparation(
        items: {
          for (final e in (j['items'] as Map? ?? const {}).entries)
            e.key as String: ItemStatus.values.byName(e.value as String),
        },
        substitutions: [
          for (final s in j['substitutions'] as List? ?? const []) Substitution.fromJson(Map<String, dynamic>.from(s as Map)),
        ],
        baseRecipe: j['base_recipe'] == null ? null : Recipe.fromJson(Map<String, dynamic>.from(j['base_recipe'] as Map)),
        basePlan: j['base_plan'] == null ? null : CookingPlan.fromJson(Map<String, dynamic>.from(j['base_plan'] as Map)),
      );

  final Map<String, ItemStatus> items;
  final List<Substitution> substitutions;

  /// The recipe and plan the unlocked substitutions apply to (null before the first one).
  final Recipe? baseRecipe;
  final CookingPlan? basePlan;

  ItemStatus statusOf(String itemId) => items[itemId] ?? ItemStatus.unknown;

  Substitution? substitutionFor(ItemKind kind, String targetId) {
    for (final s in substitutions.reversed) {
      if (s.kind == kind && s.targetId == targetId) return s;
    }
    return null;
  }

  Preparation copyWith({
    Map<String, ItemStatus>? items,
    List<Substitution>? substitutions,
    Recipe? baseRecipe,
    CookingPlan? basePlan,
    bool clearBase = false,
  }) =>
      Preparation(
        items: items ?? this.items,
        substitutions: substitutions ?? this.substitutions,
        baseRecipe: clearBase ? null : baseRecipe ?? this.baseRecipe,
        basePlan: clearBase ? null : basePlan ?? this.basePlan,
      );

  /// The recipe and plan with every unlocked substitution applied to the base.
  (Recipe, CookingPlan)? effective() {
    if (baseRecipe == null || basePlan == null) return null;
    return applyPatch(baseRecipe!, basePlan!, [
      for (final s in substitutions)
        if (!s.locked) ...s.ops,
    ]);
  }

  Map<String, dynamic> toJson() => {
        'items': {for (final e in items.entries) e.key: e.value.name},
        'substitutions': [for (final s in substitutions) s.toJson()],
        'base_recipe': baseRecipe?.toJson(),
        'base_plan': basePlan?.toJson(),
      };
}
