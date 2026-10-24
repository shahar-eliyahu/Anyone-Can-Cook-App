import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/ids.dart';

/// Temporary storage for imported recipe photos. Photos are kept only until the
/// plan is approved or the draft is discarded (docs/DECISIONS.md #22).
abstract interface class ImageStore {
  /// Compresses a picked photo (≈1600 px, JPEG, no metadata such as GPS), stores
  /// it, deletes the picker's own copy, and returns the stored path and bytes.
  Future<(String path, Uint8List bytes)> saveCompressed(String pickedPath);

  Future<void> delete(String? path);

  /// Deletes stored photos not in [keep].
  Future<void> deleteAllExcept(Set<String> keep);
}

class FileImageStore implements ImageStore {
  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/import_images').create(recursive: true);
  }

  @override
  Future<(String, Uint8List)> saveCompressed(String pickedPath) async {
    final bytes = await FlutterImageCompress.compressWithFile(
      pickedPath,
      minWidth: 1600,
      minHeight: 1600,
      quality: 80,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (bytes == null) throw const FileSystemException('image compression failed');
    final file = File('${(await _dir()).path}/${newId()}.jpg');
    await file.writeAsBytes(bytes, flush: true);
    await delete(pickedPath);
    return (file.path, bytes);
  }

  @override
  Future<void> delete(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  @override
  Future<void> deleteAllExcept(Set<String> keep) async {
    final dir = await _dir();
    await for (final f in dir.list()) {
      if (f is File && !keep.contains(f.path)) await f.delete();
    }
  }
}

final imageStoreProvider = Provider<ImageStore>((ref) => FileImageStore());

/// Opens the camera or gallery and returns the picked file's path (null if cancelled).
typedef PhotoPicker = Future<String?> Function({required bool camera});

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => ({required bool camera}) async => (await ImagePicker()
          .pickImage(source: camera ? ImageSource.camera : ImageSource.gallery, requestFullMetadata: false))
      ?.path,
);
