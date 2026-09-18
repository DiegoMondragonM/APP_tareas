import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerHelper {
  static final _picker = ImagePicker();

  static Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt >= 33) {
        final status = await Permission.photos.request();
        return status.isGranted || status.isLimited;
      }
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  static Future<ImageSource?> _elegirFuente(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Tomar foto'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Elegir de galería'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );
  }

  static Future<String?> pickAndSaveImage(
    BuildContext context, {
    required String prefix,
  }) async {
    final source = await _elegirFuente(context);
    if (source == null) return null;

    final permitido =
        source == ImageSource.camera
            ? await _requestCameraPermission()
            : await _requestGalleryPermission();

    if (!permitido) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? 'Se necesita permiso de cámara'
                  : 'Se necesita permiso para acceder a fotos',
            ),
            action: SnackBarAction(
              label: 'Ajustes',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
      return null;
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return null;

      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(dir.path, 'imagenes'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final ext = p.extension(picked.path);
      final fileName =
          '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final saved = File(p.join(imagesDir.path, fileName));
      await File(picked.path).copy(saved.path);
      return saved.path;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener la imagen: $e')),
        );
      }
      return null;
    }
  }

  static Future<void> deleteImageIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
