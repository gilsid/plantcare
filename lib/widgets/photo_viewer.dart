import 'package:flutter/material.dart';
import 'plant_image.dart';

class PhotoViewer extends StatelessWidget {
  final String photoPath;
  final String? heroTag;

  const PhotoViewer({super.key, required this.photoPath, this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Center(
        child: Hero(
          tag: heroTag ?? photoPath,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: PlantImage(
              photoPath: photoPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
