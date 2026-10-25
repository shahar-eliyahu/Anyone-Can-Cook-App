import 'dart:convert';
import 'dart:io';

import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/features/cooking/engine/action_dispatcher.dart';
import 'package:anyone_can_cook/features/cooking/engine/cooking_engine.dart';
import 'package:anyone_can_cook/features/cooking/guidance.dart';
import 'package:anyone_can_cook/models/cooking_plan.dart';
import 'package:anyone_can_cook/models/recipe_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/sample.dart';
import 'support/ui_helpers.dart';

/// Plan-ahead advice ("לנוח במקרר לילה שלם") is shown before cooking and with the step it is
/// about, never as a banner at the start of cooking (real-device feedback, 2026-10-25).
void main() {
  final template = loadSampleBundle().plan;
  final timed = template.steps.firstWhere((s) => s.timers.isNotEmpty);

  /// A plan from (title, instruction, timer minutes or null).
  CookingPlan planOf(String notice, List<(String, String, int?)> steps) => template.copyWith(
        advanceNoticeHe: notice,
        prepTasks: const [],
        steps: [
          for (final (i, (title, text, minutes)) in steps.indexed)
            timed.copyWith(
              id: 's${i + 1}',
              title: title,
              instructionHe: text,
              dependsOn: i == 0 ? const [] : ['s$i'],
              timers: minutes == null
                  ? const []
                  : [timed.timers.first.copyWith(id: 't${i + 1}', labelHe: title, seconds: minutes * 60)],
              actions: const [],
            ),
        ],
      );

  test('the biscuit cake: "לנוח במקרר לילה שלם" belongs to the chilling step, not to the cream', () {
    final plan = planOf('מומלץ לתת לעוגה לנוח במקרר לילה שלם.', [
      ('הכנת קרם וניל', 'מערבבים את אבקת הפודינג עם החלב והשמנת עד שמסמיך.', null),
      ('הרכבת העוגה', 'טובלים ביסקוויטים בחלב ומסדרים שכבות עם הקרם.', null),
      ('קירור', 'מכסים ומכניסים למקרר לפחות 6 שעות.', 360),
    ]);
    expect(advanceNoticeStepId(plan), 's3');
  });

  test('a notice matches its kind of waiting even without a shared word', () {
    final rise = planOf('צריך לתכנן מראש: הבצק תופח שעתיים.', [
      ('לישה', 'לשים את הבצק 10 דקות.', 10),
      ('התפחה', 'מכסים ומשאירים במקום חם.', 120),
      ('אפייה', 'אופים 30 דקות.', 30),
    ]);
    expect(advanceNoticeStepId(rise), 's2');
    final soak = planOf('את השעועית צריך להשרות לילה מראש.', [
      ('השריה', 'משרים את השעועית במים קרים.', 600),
      ('בישול', 'מבשלים שעה.', 60),
    ]);
    expect(advanceNoticeStepId(soak), 's1');
  });

  test('without a clear match: the longest wait of an hour or more, else the last step; no notice, no step', () {
    final long = planOf('המתכון לוקח זמן.', [('א', 'עבודה', 20), ('ב', 'המתנה', 240), ('ג', 'הגשה', null)]);
    expect(advanceNoticeStepId(long), 's2');
    final short = planOf('המתכון לוקח זמן.', [('א', 'עבודה', 20), ('ב', 'הגשה', null)]);
    expect(advanceNoticeStepId(short), 's2');
    expect(advanceNoticeStepId(template.copyWith(advanceNoticeHe: null)), isNull);
  });

  Future<String> saveWithNotice(AppHarness h, String notice) {
    final json = jsonDecode(File('../shared/fixtures/sample_recipe.json').readAsStringSync()) as Map<String, dynamic>;
    (json['plan'] as Map<String, dynamic>)['advance_notice_he'] = notice;
    return h.recipes.saveBundle(RecipeBundle.decode(jsonEncode(json)), sourceType: 'sample');
  }

  const notice = 'מומלץ לתת לעוף לנוח במקרר לפני ההגשה.';

  testApp('preparation shows the notice; cooking does not open with it', (tester, h) async {
    final recipeId = await saveWithNotice(h, notice);
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$recipeId'));
    await tester.pumpAndSettle();
    expect(find.text(notice), findsOneWidget); // planning ahead, before cooking

    await tapButton(tester, 'מתחילים לבשל');
    expect(find.text('הכנת תפוחי האדמה'), findsOneWidget);
    expect(find.text(notice), findsNothing); // not while preparing the potatoes
  });

  testApp('cooking shows the notice with the step it is about', (tester, h) async {
    final recipeId = await saveWithNotice(h, notice);
    final plan = (await h.recipes.latestApprovedPlan(recipeId))!;
    expect(advanceNoticeStepId(plan.plan), 's5'); // "מנוחה והגשה"
    final session = await h.sessions.startSession(recipeId: recipeId, planId: plan.id);
    final dispatcher = ActionDispatcher(
      state: CookingEngine.replay(plan.plan, await h.sessions.loadEvents(session.id)),
      store: h.sessions.eventStoreFor(session.id),
      onEffects: (_) async {},
      clock: h.clock.call,
    );
    for (final id in ['s1', 's2', 's3', 's4']) {
      // A timed step is finished after its timer was started (as the cook would).
      final start = plan.plan.stepById(id)!.actions.where((a) => a.startsTimer != null).firstOrNull;
      if (start != null) await dispatcher.confirmAction(id, start.id);
      expect((await dispatcher.completeStep(id)).status, DispatchStatus.applied, reason: id);
    }
    await tester.pumpWidget(h.build(initialLocation: '/cook/${session.id}'));
    await tester.pumpAndSettle();
    expect(find.text('מנוחה והגשה'), findsOneWidget);
    await expectSeen(tester, find.text(notice));
  });
}
