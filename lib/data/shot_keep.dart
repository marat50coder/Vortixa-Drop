import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

enum FaceSource { camera, gallery }

/// One local profile shot. Stays in app documents, never leaves the device.
class ShotKeep {
  ShotKeep(this._folder);

  static const String _fileName = 'vx_face.jpg';

  final Directory _folder;
  final ImagePicker _picker = ImagePicker();

  static Future<ShotKeep> open() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    return ShotKeep(docs);
  }

  File get file => File('${_folder.path}/$_fileName');

  bool get hasShot => file.existsSync();

  String? get path => hasShot ? file.path : null;

  Future<String?> take(FaceSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source == FaceSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1400,
      maxHeight: 1400,
      imageQuality: 86,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return path;
    if (hasShot) {
      PaintingBinding.instance.imageCache.evict(FileImage(file));
    }
    await file.writeAsBytes(await picked.readAsBytes(), flush: true);
    return file.path;
  }

  Future<void> wipe() async {
    if (!hasShot) return;
    PaintingBinding.instance.imageCache.evict(FileImage(file));
    await file.delete();
  }
}
