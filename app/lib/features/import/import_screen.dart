import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../data/settings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/recipe_analysis.dart';
import 'drafts_card.dart';
import 'image_store.dart';
import 'import_errors.dart';
import 'import_service.dart';

/// Import a recipe from pasted text, a photo, or a link (docs/PLAN.md, Phase 2).
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this)..addListener(() => setState(() {}));
  final _text = TextEditingController();
  final _url = TextEditingController();
  String? _imagePath;
  Uint8List? _imageBytes;
  ImportStage? _stage;
  bool _slow = false;
  Timer? _slowTimer;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePrivacyNotice());
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    // A photo picked but never analyzed is not kept.
    if (_imagePath != null) unawaited(ref.read(imageStoreProvider).delete(_imagePath));
    _tabs.dispose();
    _text.dispose();
    _url.dispose();
    super.dispose();
  }

  bool get _busy => _stage != null;

  /// Shown once, before the first import: what is sent to the AI service.
  Future<void> _ensurePrivacyNotice() async {
    final settings = ref.read(settingsRepositoryProvider);
    if (await settings.get(SettingKeys.importPrivacyAccepted) == 'true' || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.privacyTitle),
        content: Text(l10n.privacyBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.privacyAccept)),
        ],
      ),
    );
    if (ok == true) {
      await settings.set(SettingKeys.importPrivacyAccepted, 'true');
    } else if (mounted) {
      context.pop();
    }
  }

  Future<void> _pickPhoto({required bool camera}) async {
    final picked = await ref.read(photoPickerProvider)(camera: camera);
    if (picked == null) return;
    final images = ref.read(imageStoreProvider);
    final (path, bytes) = await images.saveCompressed(picked);
    await images.delete(_imagePath);
    if (!mounted) return;
    setState(() {
      _imagePath = path;
      _imageBytes = bytes;
      _message = null;
    });
  }

  Future<void> _removePhoto() async {
    await ref.read(imageStoreProvider).delete(_imagePath);
    setState(() => _imagePath = _imageBytes = null);
  }

  ImportSource? get _source => switch (_tabs.index) {
        0 when _text.text.trim().isNotEmpty => ImportSource.text(_text.text.trim()),
        1 when _imagePath != null => ImportSource.image(_imagePath!, _imageBytes!),
        2 when _url.text.trim().isNotEmpty => ImportSource.url(_url.text.trim()),
        _ => null,
      };

  Future<void> _analyze() async {
    final l10n = AppLocalizations.of(context);
    final source = _source;
    if (source == null) return;
    if (source.type == SourceType.url && Uri.tryParse(source.url!)?.hasScheme != true) {
      setState(() => _message = l10n.errInvalidUrl);
      return;
    }
    final service = ref.read(importServiceProvider);

    final duplicate = await service.findDuplicate(source);
    if (duplicate != null && mounted) {
      final again = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.importDuplicateTitle),
          content: Text(l10n.importDuplicateBody(duplicate.displayTitle)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.importAgain)),
            FilledButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.importOpenExisting)),
          ],
        ),
      );
      if (again == null || !mounted) return;
      if (!again) {
        if (duplicate.isDraft) {
          await openDraft(context, ref, duplicate.id, replace: true);
        } else {
          context.pushReplacement('/recipes/${duplicate.id}');
        }
        return;
      }
    }

    setState(() {
      _stage = ImportStage.reading;
      _message = null;
      _slow = false;
    });
    _slowTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _slow = true);
    });
    try {
      final outcome = await service.analyze(source, onStage: (s) {
        if (mounted) setState(() => _stage = s);
      });
      _imagePath = _imageBytes = null; // now owned by the draft (or already deleted)
      if (!mounted) return;
      switch (outcome) {
        case ImportNotRecipe(:final reasonHe):
          setState(() => _message = [l10n.importNotRecipe, ?reasonHe].join('\n'));
        case ImportNeedsAnswers(:final draftId):
          context.pushReplacement('/drafts/$draftId/clarify');
        case ImportPlanReady(:final draftId):
          context.pushReplacement('/drafts/$draftId/review');
      }
    } catch (e) {
      if (source.type == SourceType.image) _imagePath = _imageBytes = null; // a failed photo import keeps nothing
      if (mounted) setState(() => _message = importErrorText(l10n, e));
    } finally {
      _slowTimer?.cancel();
      if (mounted) setState(() => _stage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppScaffold(
      title: l10n.importTitle,
      body: Column(
        children: [
          IgnorePointer(
            ignoring: _busy,
            child: TabBar(
              controller: _tabs,
              tabs: [
                Tab(icon: const Icon(Icons.notes), text: l10n.importTabText),
                Tab(icon: const Icon(Icons.photo_camera_outlined), text: l10n.importTabPhoto),
                Tab(icon: const Icon(Icons.link), text: l10n.importTabUrl),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                switch (_tabs.index) {
                  0 => TextField(
                      controller: _text,
                      enabled: !_busy,
                      minLines: 8,
                      maxLines: 16,
                      maxLength: 20000,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(hintText: l10n.importTextHint, border: const OutlineInputBorder()),
                    ),
                  1 => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8,
                      children: [
                        if (_imagePath != null)
                          Stack(
                            children: [
                              if (File(_imagePath!).existsSync())
                                Image.file(
                                  File(_imagePath!),
                                  height: 260,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  errorBuilder: (_, _, _) => const SizedBox(height: 260, child: Icon(Icons.broken_image)),
                                )
                              else
                                const SizedBox(height: 260, child: Center(child: Icon(Icons.image_outlined, size: 48))),
                              if (!_busy)
                                IconButton.filledTonal(
                                  tooltip: l10n.delete,
                                  onPressed: _removePhoto,
                                  icon: const Icon(Icons.close),
                                ),
                            ],
                          ),
                        Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : () => _pickPhoto(camera: true),
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: Text(l10n.importTakePhoto),
                              ),
                            ),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : () => _pickPhoto(camera: false),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: Text(l10n.importPickPhoto),
                              ),
                            ),
                          ],
                        ),
                        Text(l10n.importPhotoNote, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  _ => TextField(
                      controller: _url,
                      enabled: !_busy,
                      keyboardType: TextInputType.url,
                      textDirection: TextDirection.ltr,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(hintText: l10n.importUrlHint, border: const OutlineInputBorder()),
                    ),
                },
                const SizedBox(height: 16),
                if (_busy)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        spacing: 16,
                        children: [
                          const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_stage == ImportStage.planning ? l10n.importStagePlanning : l10n.importStageReading),
                                if (_slow) Text(l10n.importStageSlow, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: _source == null ? null : _analyze,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(l10n.importAnalyze),
                  ),
                if (_message case final m?) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(m, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
