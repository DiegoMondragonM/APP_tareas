import 'dart:io';

import 'package:flutter/material.dart';

class LocalImage extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const LocalImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  bool get _exists =>
      path != null && path!.isNotEmpty && File(path!).existsSync();

  @override
  Widget build(BuildContext context) {
    if (!_exists) {
      return placeholder ?? const SizedBox.shrink();
    }

    final image = Image.file(
      File(path!),
      width: width,
      height: height,
      fit: fit,
    );

    if (borderRadius == null) return image;

    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
