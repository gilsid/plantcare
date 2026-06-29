import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/plant.dart';
import '../../../models/enums.dart';
import '../../../providers/plant_provider.dart';
import '../../../widgets/health_bar.dart';
import '../../../widgets/plant_image.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const PlantCard({super.key, required this.plant, required this.onTap});

  String _getNextCareText(Plant plant, BuildContext context) {
    final provider = context.read<PlantProvider>();
    final tasks = provider.getCareTasksForPlant(plant.id);

    if (tasks.isEmpty) return 'Tidak ada jadwal perawatan';

    final overdueTasks = tasks.where((t) => t.isOverdue).toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    if (overdueTasks.isNotEmpty) {
      final urgent = overdueTasks.first;
      final daysLate = DateTime.now().difference(urgent.nextDueDate).inDays;
      if (daysLate == 0) return '${urgent.careType.displayName} hari ini!';
      return '${urgent.careType.displayName} terlambat $daysLate hari';
    }

    final upcoming = tasks.toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final next = upcoming.first;
    final hours = next.timeUntilDue.inHours;
    if (hours <= 1) return '${next.careType.displayName} sebentar lagi';
    if (hours < 24) return '${next.careType.displayName} dalam $hours jam';
    final days = hours ~/ 24;
    if (days == 1) return '${next.careType.displayName} besok';
    return '${next.careType.displayName} dalam $days hari';
  }

  Color _getStatusColor(Plant plant, BuildContext context) {
    final provider = context.read<PlantProvider>();
    final tasks = provider.getCareTasksForPlant(plant.id);
    if (tasks.any((t) => t.isOverdue)) return AppColors.error;

    final upcoming = tasks.toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    if (upcoming.isNotEmpty && upcoming.first.isDueSoon) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return isDark ? AppColors.primaryDark : AppColors.primaryLight;
    }
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Hero(
                  tag: 'plant_image_${plant.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 90,
                      height: 90,
                      color: isDark
                          ? const Color(0xFF252D2A)
                          : const Color(0xFFECECE5),
                      child: PlantImage(
                        photoPath: plant.photoPath,
                        fit: BoxFit.cover,
                        initials: plant.name,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 32);
                        },
                        placeholder: Icon(
                          Icons.local_florist,
                          size: 40,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.primaryLight.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plant.species,
                              style: textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (plant.location != null &&
                          plant.location!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                plant.location!,
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      HealthBar(
                        score: plant.healthScore,
                        showText: false,
                        height: 6,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getNextCareText(plant, context),
                        style: textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(plant, context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Consumer<PlantProvider>(
                      builder: (context, provider, child) {
                        final tasks = provider.getCareTasksForPlant(plant.id);
                        final wateringTask = tasks.where(
                          (t) => t.careType == CareType.watering,
                        ).firstOrNull;
                        final isWateringOverdue =
                            wateringTask?.isOverdue ?? false;
                        final totalOverdue = tasks.where((t) => t.isOverdue).length;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (totalOverdue > 1)
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$totalOverdue',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                isWateringOverdue
                                    ? Icons.water_drop
                                    : Icons.water_drop_outlined,
                                color: isWateringOverdue
                                    ? AppColors.error
                                    : (isDark
                                          ? AppColors.primaryDark
                                          : AppColors.primaryLight),
                                size: 28,
                              ),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final name = plant.name;
                                final success = await provider.completeCareTask(
                                  plant.id,
                                  CareType.watering,
                                );
                                if (success) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$name berhasil disiram!',
                                      ),
                                      duration: const Duration(seconds: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Tidak ada jadwal penyiraman untuk tanaman ini',
                                      ),
                                      duration: const Duration(seconds: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              tooltip: 'Siram Tanaman',
                            ),
                            Text(
                              'Siram',
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isWateringOverdue
                                    ? AppColors.error
                                    : (isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlantGridCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const PlantGridCard({super.key, required this.plant, required this.onTap});

  String _getStatusText(Plant plant, BuildContext context) {
    final provider = context.read<PlantProvider>();
    final tasks = provider.getCareTasksForPlant(plant.id);
    final overdue = tasks.where((t) => t.isOverdue);
    if (overdue.isNotEmpty) {
      return '${overdue.length} overdue';
    }
    return '${plant.healthScore.round()}% sehat';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'plant_image_${plant.id}',
                child: Container(
                  color: isDark ? const Color(0xFF252D2A) : const Color(0xFFECECE5),
                  child: PlantImage(
                    photoPath: plant.photoPath,
                    fit: BoxFit.cover,
                    initials: plant.name,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 32);
                    },
                    placeholder: Icon(
                      Icons.local_florist,
                      size: 40,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.primaryLight.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plant.species,
                    style: textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  HealthBar(score: plant.healthScore, showText: false, height: 4),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusText(plant, context),
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(plant, context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(Plant plant, BuildContext context) {
    final provider = context.read<PlantProvider>();
    final tasks = provider.getCareTasksForPlant(plant.id);
    if (tasks.any((t) => t.isOverdue)) return AppColors.error;
    return AppColors.success;
  }
}
