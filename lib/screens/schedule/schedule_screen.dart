import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../models/care_task.dart';
import '../../providers/plant_provider.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jadwal Mingguan',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<PlantProvider>(
        builder: (context, provider, child) {
          if (provider.plants.isEmpty) {
            return const Center(child: Text('Belum ada tanaman.'));
          }

          final days = List.generate(7, (i) => now.add(Duration(days: i)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isToday = index == 0;
              final dayName = isToday
                  ? 'Hari Ini'
                  : index == 1
                      ? 'Besok'
                      : DateFormat('EEEE', 'id').format(day);
              final dateStr = DateFormat('d MMMM', 'id').format(day);

              final dayTasks = <({String plantName, String plantId, CareTask task})>[];
              for (final plant in provider.plants) {
                final tasks = provider.getCareTasksForPlant(plant.id);
                for (final task in tasks) {
                  final dueDate = DateTime(
                    task.nextDueDate.year,
                    task.nextDueDate.month,
                    task.nextDueDate.day,
                  );
                  final dayStart = DateTime(day.year, day.month, day.day);
                  if (dueDate.isAtSameMomentAs(dayStart)) {
                    dayTasks.add((
                      plantName: plant.name,
                      plantId: plant.id,
                      task: task,
                    ));
                  }
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isToday
                      ? (isDark
                          ? AppColors.primaryDark.withValues(alpha: 0.1)
                          : AppColors.primaryLight.withValues(alpha: 0.05))
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isToday
                        ? (isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight)
                        : (isDark
                            ? const Color(0xFF252D2A)
                            : const Color(0xFFE2E2DC)),
                    width: isToday ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            dayName,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isToday
                                  ? (isDark
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          if (dayTasks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Tidak ada jadwal',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (dayTasks.isNotEmpty)
                      ...dayTasks.map((item) => _buildTaskItem(
                        context,
                        item.plantName,
                        item.plantId,
                        item.task,
                        isDark,
                        textTheme,
                        provider,
                      )),
                    const SizedBox(height: 4),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    String plantName,
    String plantId,
    CareTask task,
    bool isDark,
    TextTheme textTheme,
    PlantProvider provider,
  ) {
    final isOverdue = task.isOverdue;
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/plant-detail', arguments: plantId);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isOverdue
                  ? AppColors.error.withValues(alpha: 0.15)
                  : (isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.15)
                      : AppColors.primaryLight.withValues(alpha: 0.1)),
              child: Icon(
                _getCareIcon(task.careType),
                size: 16,
                color: isOverdue
                    ? AppColors.error
                    : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plantName,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    task.careType.displayName,
                    style: textTheme.bodySmall?.copyWith(
                      color: isOverdue ? AppColors.error : null,
                    ),
                  ),
                ],
              ),
            ),
            if (isOverdue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Terlambat',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getCareIcon(CareType type) {
    switch (type) {
      case CareType.watering:
        return Icons.water_drop;
      case CareType.fertilizing:
        return Icons.science;
      case CareType.pruning:
        return Icons.content_cut;
      case CareType.pestCheck:
        return Icons.bug_report;
      case CareType.repotting:
        return Icons.change_circle_outlined;
    }
  }
}
