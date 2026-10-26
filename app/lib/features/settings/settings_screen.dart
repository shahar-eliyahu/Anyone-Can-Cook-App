import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/components.dart';
import '../../l10n/app_localizations.dart';
import '../timers/timer_notifier.dart';
import '../assistant/hands_free_choice.dart';
import '../assistant/voice.dart';
import 'battery_optimization.dart';

class _Reliability {
  const _Reliability({
    required this.notificationsEnabled,
    required this.exactAlarms,
    required this.batteryRestricted,
  });
  final bool notificationsEnabled;
  final bool exactAlarms;
  final bool batteryRestricted;
}

final _reliabilityProvider = FutureProvider.autoDispose<_Reliability>((ref) async {
  final notifier = ref.watch(localTimerNotifierProvider);
  final perms = await notifier?.permissions();
  return _Reliability(
    notificationsEnabled: perms?.notificationsEnabled ?? true,
    exactAlarms: perms?.exactAlarmsAllowed ?? true,
    batteryRestricted: await BatteryOptimization.isRestricted(),
  );
});

/// Timer reliability checks (notifications, exact alarms, battery) and about.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Permissions are often changed in system settings; refresh on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(_reliabilityProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.watch(localTimerNotifierProvider);
    final status = ref.watch(_reliabilityProvider).value;

    Widget statusTile({required bool ok, required String okText, required String badText, String? action, VoidCallback? onAction}) =>
        ListTile(
          leading: Icon(
            ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: ok ? context.palette.success : context.palette.timerDone,
          ),
          title: Text(ok ? okText : badText),
          subtitle: ok || action == null
              ? null
              : Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(onPressed: onAction, child: Text(action)),
                ),
        );

    return AppScaffold(
      title: l10n.settings,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xxl),
        children: [
          SectionTitle(l10n.settingsNotifications),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (status == null)
                    const Padding(padding: EdgeInsets.all(Space.l), child: LinearProgressIndicator())
                  else ...[
                    statusTile(
                      ok: status.notificationsEnabled,
                      okText: l10n.notificationsOn,
                      badText: l10n.notificationsOff,
                      action: l10n.enableNotifications,
                      onAction: () async {
                        await notifier?.requestNotifications();
                        ref.invalidate(_reliabilityProvider);
                      },
                    ),
                    statusTile(
                      ok: status.exactAlarms,
                      okText: l10n.exactAlarmsOn,
                      badText: l10n.exactAlarmsOff,
                      action: l10n.enableExactAlarms,
                      onAction: () => notifier?.requestExactAlarms(),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text(l10n.testNotification),
                      onPressed: notifier == null
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await notifier.scheduleTest(const Duration(seconds: 10));
                              messenger.showMessage(l10n.testNotificationScheduled);
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (ref.watch(speechRecognizerProvider) != null) ...[
            SectionTitle(l10n.remySettingsSection),
            const Card(child: Padding(padding: EdgeInsets.symmetric(vertical: Space.xs), child: HandsFreeChoice(compact: true))),
          ],
          SectionTitle(l10n.batteryTitle),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (status != null)
                    statusTile(ok: !status.batteryRestricted, okText: l10n.batteryOk, badText: l10n.batteryRestricted),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.l),
                    child: Text(l10n.batteryVendorHint, style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.s),
                    child: OutlinedButton(onPressed: BatteryOptimization.openSettings, child: Text(l10n.openBatterySettings)),
                  ),
                ],
              ),
            ),
          ),
          SectionTitle(l10n.aboutTitle),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.l + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Space.m,
                children: [
                  Row(
                    spacing: Space.m,
                    children: [
                      const LogoMark(size: 48),
                      Expanded(child: Text(l10n.appTitle, style: Theme.of(context).textTheme.titleLarge)),
                    ],
                  ),
                  Text(l10n.settingsAboutVersionless),
                  Text(l10n.aboutBody),
                  Text(l10n.fontLicense, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
