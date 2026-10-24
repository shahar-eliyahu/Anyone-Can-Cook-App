import 'dart:convert';

import 'package:anyone_can_cook/features/cooking/engine/action_dispatcher.dart';
import 'package:anyone_can_cook/features/cooking/engine/cooking_engine.dart';
import 'package:anyone_can_cook/features/cooking/engine/events.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample.dart';

/// Phase 3B: approved changes to steps not started yet, as a replayable event.
void main() {
  late EngineHarness h;
  setUp(() => h = EngineHarness());

  Map<String, dynamic> note(String step) => {'op': 'add_step_note', 'step_id': step, 'note_he': 'על אש נמוכה.'};

  test('a pending step can change; the plan and the patch list follow', () async {
    final r = await h.dispatcher.applyPlanPatch([note('s4')], summaryHe: 'אש נמוכה');
    expect(r.isApplied, isTrue);
    expect(h.state.plan.stepById('s4')!.notesHe, ['על אש נמוכה.']);
    expect(h.state.patches.single.summaryHe, 'אש נמוכה');
  });

  test('steps with progress, started timers, unknown ids and invalid plans are refused', () async {
    await h.dispatcher.completeStep('s1');
    expect((await h.dispatcher.applyPlanPatch([note('s1')], summaryHe: 'x')).reason, 'step_started');
    await h.dispatcher.completePrepTask('p1');
    expect((await h.dispatcher.applyPlanPatch([{'op': 'set_timer_seconds', 'timer_id': 'tp1', 'seconds': 60}], summaryHe: 'x')).reason,
        'timer_started');
    expect((await h.dispatcher.applyPlanPatch([note('s99')], summaryHe: 'x')).reason, 'unknown_step');
    expect((await h.dispatcher.applyPlanPatch([], summaryHe: 'x')).reason, 'empty_patch');
    expect(h.state.patches, isEmpty);
    expect(h.store.events.whereType<PlanPatched>(), isEmpty);
  });

  test('a timer that hasn\'t started can be changed and then starts with the new time', () async {
    await h.dispatcher.applyPlanPatch([{'op': 'set_timer_seconds', 'timer_id': 't1', 'seconds': 3000}], summaryHe: 'עוד זמן בתנור');
    await h.dispatcher.completeStep('s1');
    await h.dispatcher.completeStep('s2');
    final r = await h.confirm('s3', 'a1');
    expect(r.startedTimer!.totalSeconds, 3000);
  });

  test('the stored event round-trips through JSON and replays to the same state; duplicates are ignored', () async {
    await h.dispatcher.applyPlanPatch([note('s4')], summaryHe: 'אש נמוכה', proposalId: 'p-1');
    expect((await h.dispatcher.applyPlanPatch([note('s4')], summaryHe: 'אש נמוכה', proposalId: 'p-1')).status,
        DispatchStatus.alreadyDone);
    final e = h.store.events.whereType<PlanPatched>().single;
    final decoded = CookingEvent.decode(e.type, jsonDecode(jsonEncode(e.toPayload())) as Map<String, dynamic>, e.at);
    final replayed = CookingEngine.replay(loadSampleBundle().plan, [...h.store.events.where((x) => x is! PlanPatched), decoded]);
    expect(replayed.plan, h.state.plan);
    expect(replayed.patches.single.proposalId, 'p-1');
  });

  test('sessions without patches replay exactly as before', () async {
    await h.dispatcher.completeStep('s1');
    final replayed = CookingEngine.replay(loadSampleBundle().plan, h.store.events);
    expect(replayed.plan, loadSampleBundle().plan);
    expect(replayed.patches, isEmpty);
  });
}
