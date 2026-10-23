import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../timers/timer_notifier.dart';
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
          contentPadding: EdgeInsets.zero,
          leading: Icon(ok ? Icons.check_circle : Icons.warning_amber, color: ok ? Colors.green : Colors.orange),
          title: Text(ok ? okText : badText),
          trailing: ok || action == null ? null : TextButton(onPressed: onAction, child: Text(action)),
        );

    return AppScaffold(
      title: l10n.settings,
      actions: [
        IconButton(
          tooltip: l10n.refresh,
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(_reliabilityProvider),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle(l10n.settingsNotifications),
          if (status == null)
            const LinearProgressIndicator()
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
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(l10n.testNotification),
            onPressed: notifier == null
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await notifier.scheduleTest(const Duration(seconds: 10));
                    messenger.showSnackBar(SnackBar(content: Text(l10n.testNotificationScheduled)));
                  },
          ),
          SectionTitle(l10n.batteryTitle),
          if (status != null)
            statusTile(
              ok: !status.batteryRestricted,
              okText: l10n.batteryOk,
              badText: l10n.batteryRestricted,
            ),
          OutlinedButton(
            onPressed: BatteryOptimization.openSettings,
            child: Text(l10n.openBatterySettings),
          ),
          const SizedBox(height: 8),
          Text(l10n.batteryVendorHint, style: Theme.of(context).textTheme.bodySmall),
          SectionTitle(l10n.aboutTitle),
          Text(l10n.aboutBody),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Text(
              l10n.serverAddress(apiBaseUrl),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
