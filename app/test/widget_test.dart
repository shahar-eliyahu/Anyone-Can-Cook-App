import 'dart:async';

import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/features/kitchen/kitchen_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/ui_helpers.dart';

void expectNoDeveloperText() {
  for (final word in developerWords) {
    expect(find.textContaining(word), findsNothing, reason: 'no "$word" on screen');
  }
}

void main() {
  testApp('home shows the Hebrew app name, RTL layout and no technical status', (tester, h) async {
    var calls = 0;
    await tester.pumpWidget(h.build(health: () async {
      calls++;
      return const HealthStatus(status: 'ok', version: '0.1.0', aiProvider: 'gemini');
    }));
    await tester.pumpAndSettle();

    expect(find.text('לבשל כל אחד יכול'), findsOneWidget);
    expect(find.text('מה מבשלים היום?'), findsOneWidget);
    expect(find.text('מתכון חדש'), findsOneWidget);
    expect(find.text('המתכונים שלי'), findsOneWidget);
    expect(find.text('לכל המתכונים'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing); // nothing floats over the list
    // No cooking in progress: no "continue" card at all.
    expect(find.text('מבשלים עכשיו'), findsNothing);
    expect(find.text('תפריט'), findsOneWidget);
    expectNoDeveloperText();
    expect(calls, 1); // the server is still woken quietly

    final context = tester.element(find.byType(KitchenScreen));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testApp('an unreachable server shows nothing and never blocks the app', (tester, h) async {
    await tester.pumpWidget(h.build(health: () async => throw Exception('offline')));
    await tester.pumpAndSettle();
    expectNoDeveloperText();
    await tester.tap(find.text('לכל המתכונים'));
    await tester.pumpAndSettle();
    expect(find.text('אין מתכונים עדיין'), findsOneWidget);
  });

  testApp('a slow server shows no waking-up message', (tester, h) async {
    final never = Completer<HealthStatus>();
    await tester.pumpWidget(h.build(health: () => never.future));
    await tester.pump(const Duration(seconds: 30));
    expectNoDeveloperText();
    expect(find.text('לבשל כל אחד יכול'), findsOneWidget);
  });
}
