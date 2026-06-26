import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlantImage extends StatelessWidget {
  final String? photoPath;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final double? width;
  final double? height;
  final Widget? placeholder;

  const PlantImage({
    super.key,
    required this.photoPath,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.width,
    this.height,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final Widget fallback = placeholder ??
        Container(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF252D2A)
              : const Color(0xFFECECE5),
          child: const Icon(Icons.broken_image),
        );

    if (photoPath == null || photoPath!.isEmpty) {
      return placeholder ?? const SizedBox.shrink();
    }

    if (photoPath!.startsWith('data:image/') && photoPath!.contains(';base64,')) {
      try {
        final String base64Data = photoPath!.split(';base64,').last;
        final Uint8List bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder ?? (context, error, stackTrace) => fallback,
        );
      } catch (e) {
        return fallback;
      }
    }

    if (kIsWeb) {
      if (photoPath!.startsWith('http') || photoPath!.startsWith('blob:')) {
        return Image.network(
          photoPath!,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder ?? (context, error, stackTrace) => fallback,
        );
      }
      return fallback;
    }

    return Image.file(
      File(photoPath!),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder ?? (context, error, stackTrace) => fallback,
    );
  }
}

ImageProvider? getPlantImageProvider(String? photoPath) {
  if (photoPath == null || photoPath.isEmpty) return null;

  if (photoPath.startsWith('data:image/') && photoPath.contains(';base64,')) {
    try {
      final String base64Data = photoPath.split(';base64,').last;
      return MemoryImage(base64Decode(base64Data));
    } catch (e) {
      return null;
    }
  }

  if (kIsWeb) {
    if (photoPath.startsWith('http') || photoPath.startsWith('blob:')) {
      return NetworkImage(photoPath);
    }
    return null;
  }

  return FileImage(File(photoPath));
}
