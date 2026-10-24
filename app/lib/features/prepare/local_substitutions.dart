import '../../models/cooking_plan.dart';
import '../../models/recipe.dart';
import 'patch.dart';
import 'preparation.dart';

/// Straightforward substitutions answered on the device, offline and free (docs/DECISIONS.md
/// #40, #41). Deliberately small and conservative: a rule applies only when the recipe's
/// context allows it (e.g. no butter → oil in pastry); anything else goes to the server,
/// which reasons about the specific recipe. Instructions are not rewritten here — Hebrew
/// prefixes make text replacement unreliable — so every affected step gets a clear note.
class _IngredientRule {
  const _IngredientRule({
    required this.names,
    required this.to,
    required this.offered,
    this.ratio = 1,
    this.plusName,
    this.plusRatio,
    this.unitOverride,
    this.extraHe,
    this.effectHe,
    this.verdict = 'works',
    this.notIfName = const [],
    this.notIfContext = const [],
  });

  /// The missing ingredient's name contains one of these.
  final List<String> names;
  final String to;

  /// What the cook may say they have ("יש לי חלב").
  final List<String> offered;
  final double ratio;
  final String? plusName;
  final double? plusRatio;
  final String? unitOverride;
  final String? extraHe;
  final String? effectHe;
  final String verdict;
  final List<String> notIfName;

  /// The rule doesn't apply when the recipe mentions any of these (the item's role differs).
  final List<String> notIfContext;
}

const _whipping = ['להקציף', 'קצפת', 'מוקצפת', 'קצף'];
const _pastry = ['בצק', 'עוגה', 'עוגת', 'עוגיות', 'מאפה', 'קרם', 'ציפוי', 'פאי', 'טארט'];

const _rules = <_IngredientRule>[
  _IngredientRule(
    names: ['שמנת חמוצה'], to: 'יוגורט טבעי', offered: ['יוגורט'],
    effectHe: 'הטעם יהיה מעט חמצמץ יותר.',
  ),
  _IngredientRule(
    names: ['שמנת מתוקה', 'שמנת לבישול', 'שמנת'], to: 'חלב וחמאה', offered: ['חלב'],
    ratio: 0.75, plusName: 'חמאה מומסת', plusRatio: 0.25, notIfName: ['חמוצה'], notIfContext: _whipping,
    verdict: 'changes_result', effectHe: 'הרוטב יהיה מעט פחות סמיך ועשיר.',
  ),
  _IngredientRule(names: ['יוגורט'], to: 'שמנת חמוצה', offered: ['שמנת חמוצה']),
  _IngredientRule(
    names: ['רויון', 'בטר מילק', 'חלב חמוץ'], to: 'חלב עם מיץ לימון', offered: ['חלב'],
    extraHe: 'כף מיץ לימון לכל כוס חלב, ומחכים 5 דקות לפני השימוש.',
  ),
  _IngredientRule(names: ['חמאה'], to: 'מרגרינה', offered: ['מרגרינה'], notIfName: ['בוטנים']),
  _IngredientRule(
    names: ['חמאה'], to: 'שמן', offered: ['שמן'], ratio: 0.75, notIfName: ['בוטנים'], notIfContext: _pastry,
    verdict: 'changes_result', effectHe: 'פחות טעם חמאתי.',
  ),
  _IngredientRule(
    names: ['קמח תופח'], to: 'קמח לבן ואבקת אפייה', offered: ['קמח'],
    extraHe: '1½ כפיות אבקת אפייה לכל כוס קמח.',
  ),
  _IngredientRule(
    names: ['סוכר חום'], to: 'סוכר לבן', offered: ['סוכר'],
    verdict: 'changes_result', effectHe: 'פחות טעם קרמלי.',
  ),
  _IngredientRule(names: ['דבש'], to: 'סילאן', offered: ['סילאן']),
  _IngredientRule(names: ['דבש'], to: 'סירופ מייפל', offered: ['מייפל']),
  _IngredientRule(
    names: ['חלב'], to: 'משקה צמחי', offered: ['סויה', 'שקדים', 'שיבולת', 'צמחי', 'אורז'],
    notIfName: ['קוקוס', 'מרוכז', 'חמוץ', 'אבקת'],
    effectHe: 'הטעם יהיה מעט שונה.',
  ),
  _IngredientRule(
    names: ['שן שום', 'שיני שום', 'שום טרי'], to: 'אבקת שום', offered: ['אבקת שום'],
    ratio: 0.125, unitOverride: 'כפית',
    verdict: 'changes_result', effectHe: 'טעם שום עדין יותר.',
  ),
  _IngredientRule(
    names: ['ציר עוף', 'ציר ירקות', 'ציר בקר'], to: 'מים ואבקת מרק', offered: ['אבקת מרק', 'מים'],
    extraHe: 'כמות אבקת המרק לפי ההוראות על האריזה.',
  ),
];

/// A local answer for a missing ingredient or piece of equipment, or null (ask the server).
SubstitutionProposal? localSubstitution({
  required Recipe recipe,
  required CookingPlan plan,
  required ItemKind kind,
  required String targetId,
  String? userNoteHe,
}) {
  final note = (userNoteHe ?? '').trim();
  final context = [
    recipe.title,
    for (final s in recipe.sourceSteps) s.text,
    for (final s in plan.steps) s.instructionHe,
  ].join(' ');
  if (kind == ItemKind.ingredient) {
    final ing = recipe.ingredients.where((i) => i.id == targetId).firstOrNull;
    if (ing == null) return null;
    for (final rule in _rules) {
      if (!rule.names.any(ing.name.contains) || rule.notIfName.any(ing.name.contains)) continue;
      if (rule.notIfContext.any(context.contains)) continue;
      if (note.isNotEmpty && !rule.offered.any(note.contains)) continue;
      return _ingredientProposal(rule, ing, plan);
    }
    return null;
  }
  final eq = recipe.equipment.where((e) => e.id == targetId).firstOrNull;
  if (eq == null) return null;
  if (eq.name.contains('מדחום')) return _noThermometer(eq, plan);
  if (eq.name.contains('משקל') || eq.name.contains('מאזני')) return _noScale(eq, recipe, plan);
  if (eq.name.contains('מיקסר') || eq.name.contains('מקציף חשמלי')) return _noMixer(eq, plan, context);
  return null;
}

// ---- ingredients ------------------------------------------------------------------------------

SubstitutionProposal _ingredientProposal(_IngredientRule rule, Ingredient ing, CookingPlan plan) {
  Quantity? scaled(Quantity? q) {
    if (q == null || q.amount == null) return q;
    final unit = rule.unitOverride ?? q.unit;
    final main = '${formatAmount(q.amount! * rule.ratio)}${unit == null ? '' : ' $unit'}';
    final plus = rule.plusName == null
        ? ''
        : ' + ${formatAmount(q.amount! * rule.plusRatio!)}${unit == null ? '' : ' $unit'} ${rule.plusName}';
    return Quantity(
      amount: q.amount! * rule.ratio,
      unit: unit,
      display: rule.plusName == null ? main : '$main ${_firstWord(rule.to)}$plus',
      provenance: q.provenance,
      noteHe: 'תחליף',
    );
  }

  final ops = <PatchOp>[
    {
      'op': 'replace_ingredient',
      'ingredient_id': ing.id,
      'name': rule.to,
      if (scaled(ing.quantity) case final q?) 'quantity': q.toJson(),
    },
  ];
  final noteHe = 'במקום ${ing.name}: ${rule.to}${rule.extraHe == null ? '' : '. ${rule.extraHe}'}';
  for (final s in plan.steps) {
    final use = s.ingredientUses.where((u) => u.ingredientId == ing.id).firstOrNull;
    if (use?.quantity != null) {
      ops.add({'op': 'set_ingredient_use', 'step_id': s.id, 'ingredient_id': ing.id, 'quantity': scaled(use!.quantity)!.toJson()});
    }
    if (use != null || s.ingredientIds.contains(ing.id)) {
      ops.add({'op': 'add_step_note', 'step_id': s.id, 'note_he': noteHe});
    }
  }
  return SubstitutionProposal(
    verdict: rule.verdict,
    explanationHe: [
      'אפשר להשתמש ב${rule.to} במקום ${ing.name}.',
      ?rule.extraHe,
    ].join(' '),
    replacementNameHe: rule.to,
    effectsHe: rule.effectHe,
    ops: ops,
    source: SubstitutionSource.local,
  );
}

String _firstWord(String s) => s.split(RegExp(r'\s+|ו')).first;

// ---- equipment --------------------------------------------------------------------------------

List<PatchOp> _notes(Equipment eq, CookingPlan plan, String noteHe, {bool onlyUsing = true}) => [
      for (final s in plan.steps)
        if (!onlyUsing || s.equipmentIds.contains(eq.id)) {'op': 'add_step_note', 'step_id': s.id, 'note_he': noteHe},
    ];

SubstitutionProposal _noMixer(Equipment eq, CookingPlan plan, String context) {
  final whipping = _whipping.any(context.contains);
  return SubstitutionProposal(
    verdict: whipping ? 'changes_result' : 'works',
    explanationHe: 'אפשר להסתדר בלי מיקסר: טורפים ביד במטרפה או במזלג.',
    replacementNameHe: 'מטרפה ידנית',
    effectsHe: whipping ? 'להגיע לקצף יציב ביד דורש סבלנות — כ-5 עד 10 דקות של טריפה נמרצת.' : null,
    ops: [
      {'op': 'replace_equipment', 'equipment_id': eq.id, 'name': 'מטרפה ידנית'},
      ..._notes(eq, plan, 'בלי מיקסר: טורפים ביד במטרפה. זה לוקח יותר זמן ומאמץ, אבל עובד.'),
    ],
    source: SubstitutionSource.local,
  );
}

/// Poultry / ground meat lines that mention a thermometer become signs-only wording that
/// says honestly it is less exact (decision #47); the cook still confirms doneness.
SubstitutionProposal _noThermometer(Equipment eq, CookingPlan plan) {
  String signsOnly(String line) {
    if (line.contains('טחון') || line.contains('71')) {
      return 'בלי מדחום: מבשלים עד שאין ורוד בפנים והנוזלים שקופים. הצבע לבדו לא תמיד אמין — אם יש ספק, עוד כמה דקות.';
    }
    if (line.contains('עוף') || line.contains('74')) {
      return 'בלי מדחום: חותכים בחלק העבה — אין ורוד והנוזלים שקופים. אם יש ספק, עוד כמה דקות בישול.';
    }
    return 'בלי מדחום: סומכים על הסימנים שבמתכון, ואם יש ספק — עוד כמה דקות בישול.';
  }

  final ops = <PatchOp>[{'op': 'omit_equipment', 'equipment_id': eq.id}];
  for (final s in plan.steps) {
    final lines = [...s.warningsHe, ?s.donenessCueHe];
    if (!lines.any((l) => l.contains('מדחום'))) continue;
    ops.add({
      'op': 'set_step_safety',
      'step_id': s.id,
      'warnings_he': [for (final w in s.warningsHe) w.contains('מדחום') ? signsOnly(w) : w],
      'doneness_cue_he': s.donenessCueHe == null || !s.donenessCueHe!.contains('מדחום') ? s.donenessCueHe : signsOnly(s.donenessCueHe!),
      'confirm_completion': s.actions.any((a) => a.completesStep && a.confirmPolicy == ConfirmPolicy.alwaysAsk),
    });
  }
  final needed = ops.length > 1;
  return SubstitutionProposal(
    verdict: needed ? 'changes_result' : 'works',
    explanationHe: needed
        ? 'אפשר לבשל בלי מדחום ולבדוק לפי הסימנים שבשלבים.'
        : 'המתכון לא צריך מדחום.',
    effectsHe: needed ? 'הבדיקה פחות מדויקת — אם יש ספק, בשלו עוד מעט.' : null,
    ops: ops,
    source: SubstitutionSource.local,
  );
}

/// Grams per cup for common ingredients (US cup, 240 ml); used without a kitchen scale.
const _gramsPerCup = <String, double>{
  'קמח מלא': 130, 'קמח': 140, 'אבקת סוכר': 120, 'סוכר חום': 220, 'סוכר': 200, 'אורז': 200,
  'קקאו': 100, 'שיבולת שועל': 90, 'קוקוס': 80, 'שקדים': 140, 'אגוזים': 120, 'חמאה': 225,
  'שמן': 220, 'יוגורט': 245, 'שמנת': 240, 'דבש': 340, 'חלב': 240, 'מים': 240,
};

const _gramUnits = {'גרם', 'גר\'', 'גר', 'ג\'', 'ג', 'g', 'gr'};
const _mlUnits = {'מ"ל', 'מ״ל', 'מל', 'ml'};

String? _cups(double cups) {
  if (cups >= 0.25) return 'כ-${formatAmount(_quarter(cups))} ${cups <= 1 ? 'כוס' : 'כוסות'}';
  final tbsp = cups * 16;
  if (tbsp >= 1) return 'כ-${formatAmount(_half(tbsp))} ${tbsp < 1.5 ? 'כף' : 'כפות'}';
  return null;
}

double _quarter(double v) => (v * 4).round() / 4;
double _half(double v) => (v * 2).round() / 2;

SubstitutionProposal _noScale(Equipment eq, Recipe recipe, CookingPlan plan) {
  Quantity? convert(Ingredient ing, Quantity? q) {
    if (q?.amount == null || q!.unit == null) return null;
    final unit = q.unit!.trim();
    double? cups;
    if (_mlUnits.contains(unit)) {
      cups = q.amount! / 240;
    } else if (_gramUnits.contains(unit)) {
      final density = _gramsPerCup.entries.where((e) => ing.name.contains(e.key)).firstOrNull?.value;
      if (density == null) return null;
      cups = q.amount! / density;
    } else {
      return null;
    }
    final text = _cups(cups);
    if (text == null) return null;
    return q.copyWith(display: '$text (${q.display})', noteHe: 'המרה משוערת בלי משקל');
  }

  final ops = <PatchOp>[{'op': 'replace_equipment', 'equipment_id': eq.id, 'name': 'כוסות וכפות מדידה'}];
  final leftInGrams = <String>[];
  for (final ing in recipe.ingredients) {
    final converted = convert(ing, ing.quantity);
    if (converted != null) {
      ops.add({'op': 'replace_ingredient', 'ingredient_id': ing.id, 'name': ing.name, 'quantity': converted.toJson()});
      for (final s in plan.steps) {
        for (final u in s.ingredientUses) {
          if (u.ingredientId != ing.id) continue;
          if (convert(ing, u.quantity) case final cu?) {
            ops.add({'op': 'set_ingredient_use', 'step_id': s.id, 'ingredient_id': ing.id, 'quantity': cu.toJson()});
          }
        }
      }
    } else if (ing.quantity?.unit case final u? when _gramUnits.contains(u.trim())) {
      leftInGrams.add(ing.name);
    }
  }
  final converted = ops.length > 1;
  return SubstitutionProposal(
    verdict: leftInGrams.isEmpty ? 'works' : 'changes_result',
    explanationHe: converted
        ? 'המרנו את הכמויות לכוסות ולכפות. 1 כוס = 240 מ"ל.'
        : 'אין במתכון כמויות שצריך לשקול.',
    effectsHe: leftInGrams.isEmpty
        ? (converted ? 'במדידה בכוסות הכמויות פחות מדויקות — מלאו את הכוס בלי לדחוס.' : null)
        : 'לא הצלחנו להמיר: ${leftInGrams.join(', ')}. אפשר להיעזר בסימון על האריזה.',
    ops: converted ? ops : [{'op': 'omit_equipment', 'equipment_id': eq.id}],
    source: SubstitutionSource.local,
  );
}

/// 0.75 → "¾", 1.5 → "1½", 2 → "2", 0.3 → "0.3".
String formatAmount(double v) {
  final fractions = {0.25: '¼', 0.5: '½', 0.75: '¾', 0.33: '⅓', 0.67: '⅔', 0.125: '⅛'};
  final whole = v.floor();
  final rest = double.parse((v - whole).toStringAsFixed(3));
  if (rest == 0) return '$whole';
  for (final e in fractions.entries) {
    if ((rest - e.key).abs() < 0.02) return whole == 0 ? e.value : '$whole${e.value}';
  }
  final rounded = double.parse(v.toStringAsFixed(1));
  return rounded == rounded.roundToDouble() ? '${rounded.toInt()}' : '$rounded';
}
