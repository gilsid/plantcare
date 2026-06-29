import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/plant.dart';
import '../../../providers/plant_provider.dart';
import '../../../services/image_service.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/photo_viewer.dart';
import '../../../widgets/plant_image.dart';

class GrowthTimeline extends StatefulWidget {
  final Plant plant;

  const GrowthTimeline({super.key, required this.plant});

  @override
  State<GrowthTimeline> createState() => _GrowthTimelineState();
}

class _GrowthTimelineState extends State<GrowthTimeline> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addDiaryEntry(ImageSource source) async {
    final path = await context.read<ImageService>().pickAndSaveImage(source);
    if (path == null) return;

    // Show text dialog to enter an optional note
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _noteController.clear();

    final String? note = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Tambah Catatan Pertumbuhan'),
          content: TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Misal: Tunas baru mulai tumbuh, daun semakin lebar...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Lewati', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, _noteController.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.primaryDark
                    : AppColors.primaryLight,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (note != null && mounted) {
      await context.read<PlantProvider>().addGrowthEntry(
        plantId: widget.plant.id,
        photoPath: path,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto perkembangan ditambahkan! 🌱'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImagePickerSheet() {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tambah Foto Perkembangan',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.camera_alt, color: Colors.white),
                  ),
                  title: const Text('Ambil Foto Baru (Kamera)'),
                  onTap: () => _addDiaryEntry(ImageSource.camera),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.photo_library, color: Colors.white),
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () => _addDiaryEntry(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(String entryId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(
        title: 'Hapus Foto Diary',
        message:
            'Apakah Anda yakin ingin menghapus foto perkembangan ini dari diary?',
        confirmColor: AppColors.error,
        confirmLabel: 'Hapus',
      ),
    );

    if (confirm == true && mounted) {
      await context.read<PlantProvider>().deleteGrowthEntry(
        plantId: widget.plant.id,
        entryId: entryId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto diary berhasil dihapus.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.plant.growthDiary.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada diary pertumbuhan',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Abadikan foto tanaman Anda dari waktu ke waktu untuk melihat perkembangannya di sini.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _showImagePickerSheet,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Tambah Foto Pertama'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        itemCount:
            widget.plant.growthDiary.length + 1, // +1 for the top add button
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: OutlinedButton.icon(
                onPressed: _showImagePickerSheet,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Tambah Foto Perkembangan'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            );
          }

          final entry = widget.plant.growthDiary[index - 1];
          final formattedDate = DateFormat('dd MMMM yyyy').format(entry.date);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline vertical line and dot
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                        width: 2.5,
                      ),
                    ),
                  ),
                  if (index != widget.plant.growthDiary.length)
                    Container(
                      width: 2.5,
                      height: 200,
                      color: isDark
                          ? const Color(0xFF252D2A)
                          : const Color(0xFFE2E2DC),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Timeline Card Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF252D2A)
                          : const Color(0xFFE2E2DC),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Entry Image
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PhotoViewer(photoPath: entry.photoPath),
                            ),
                          );
                        },
                        child: PlantImage(
                          photoPath: entry.photoPath,
                          fit: BoxFit.cover,
                          initials: widget.plant.name,
                          height: 140,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image, size: 36),
                            );
                          },
                        ),
                      ),
                      // Text Description
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formattedDate,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.primaryDark
                                        : AppColors.primaryLight,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => _confirmDelete(entry.id),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Hapus Foto',
                                ),
                              ],
                            ),
                            if (entry.note != null &&
                                entry.note!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                entry.note!,
                                style: textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
