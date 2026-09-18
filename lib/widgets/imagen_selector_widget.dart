import 'dart:io';

import 'package:flutter/material.dart';
import 'package:aptar/core/image_picker_helper.dart';

class ImagenSelectorWidget extends StatelessWidget {
  final String? imagenRuta;
  final String prefix;
  final double height;
  final String etiqueta;
  final ValueChanged<String?> onChanged;

  const ImagenSelectorWidget({
    super.key,
    this.imagenRuta,
    required this.prefix,
    this.height = 160,
    this.etiqueta = 'Imagen (opcional)',
    required this.onChanged,
  });

  Future<void> _seleccionar(BuildContext context) async {
    final ruta = await ImagePickerHelper.pickAndSaveImage(
      context,
      prefix: prefix,
    );
    if (ruta != null) {
      final anterior = imagenRuta;
      if (anterior != null && anterior != ruta) {
        await ImagePickerHelper.deleteImageIfExists(anterior);
      }
      onChanged(ruta);
    }
  }

  Future<void> _quitar() async {
    await ImagePickerHelper.deleteImageIfExists(imagenRuta);
    onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tieneImagen = imagenRuta != null && File(imagenRuta!).existsSync();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              etiqueta,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _seleccionar(context),
                child: Container(
                  height: height,
                  color: cs.surfaceContainerHighest,
                  child:
                      tieneImagen
                          ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(imagenRuta!),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: IconButton.filledTonal(
                                  style: IconButton.styleFrom(
                                    backgroundColor: cs.surface.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                  onPressed: _quitar,
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Quitar imagen',
                                ),
                              ),
                            ],
                          )
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Toca para agregar imagen',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cámara o galería',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
