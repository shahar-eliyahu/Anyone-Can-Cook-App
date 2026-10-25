import '../../models/cooking_plan.dart';
import '../assistant/command_parser.dart';

/// Waiting words by kind, as roots matched inside words ("התפח" finds התפחה and התפחות): a
/// notice and the step it is about share a kind even when they share no word ("לנוח במקרר"
/// and "קירור").
const _concepts = [
  ['מקרר', 'קירור', 'לקרר', 'צינון', 'לצנן', 'צונן', 'להצטנן'],
  ['לנוח', 'מנוחה', 'ינוח', 'תנוח'],
  ['מקפיא', 'הקפא'],
  ['להשרות', 'השרי', 'משרים'],
  ['התפח', 'לתפוח', 'תופח', 'תתפח'],
  ['מרינד'],
];

int _maxTimer(PlanStep s) => s.timers.fold(0, (m, t) => t.seconds > m ? t.seconds : m);

/// The step a plan's advance notice is about ("מומלץ לתת לעוגה לנוח במקרר לילה שלם" → the
/// chilling step), so cooking shows it when that step comes, not at the start. Before cooking
/// the notice is shown in preparation. Null when the plan has no notice.
String? advanceNoticeStepId(CookingPlan plan) {
  final notice = plan.advanceNoticeHe;
  if (notice == null || notice.trim().isEmpty || plan.steps.isEmpty) return null;
  final noticeStems = stemsOf(notice).toSet();
  final kinds = [for (final c in _concepts) if (c.any(notice.contains)) c];

  PlanStep? best;
  var bestScore = 0;
  for (final step in plan.steps) {
    final text = '${step.title} ${step.instructionHe} ${step.timers.map((t) => t.labelHe).join(' ')}';
    final score = 3 * kinds.where((c) => c.any(text.contains)).length + stemsOf(text).where(noticeStems.contains).length;
    // Ties go to the later step: resting and chilling come after the work.
    if (score > 0 && score >= bestScore) {
      best = step;
      bestScore = score;
    }
  }
  if (best != null && bestScore >= 3) return best.id;
  // No clear match: the longest wait (an overnight chill is the longest timer), else the end.
  final timed = [...plan.steps.where((s) => _maxTimer(s) >= 3600)]..sort((a, b) => _maxTimer(b).compareTo(_maxTimer(a)));
  return timed.isNotEmpty ? timed.first.id : best?.id ?? plan.steps.last.id;
}
