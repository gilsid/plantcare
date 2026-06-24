import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../models/plant.dart';
import '../../models/care_task.dart';
import '../../models/care_history.dart';
import '../../models/enums.dart';
import '../../providers/plant_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/health_bar.dart';
import 'widgets/watering_history.dart';
import 'widgets/growth_timeline.dart';

class PlantDetailScreen extends StatelessWidget {
  final String plantId;

  const PlantDetailScreen({super.key, required this.plantId});

  Future<void> _confirmDelete(BuildContext context, Plant plant) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Hapus Tanaman',
        message:
            'Apakah Anda yakin ingin menghapus ${plant.name} dan seluruh riwayat perawatannya?',
        confirmColor: AppColors.error,
        confirmLabel: 'Hapus',
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<PlantProvider>().deletePlant(plant.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanaman berhasil dihapus.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  String _getCareStatusText(CareTask task) {
    if (task.isOverdue) {
      final diff = DateTime.now().difference(task.nextDueDate);
      final hours = diff.inHours;
      if (hours < 24) return 'Terlambat $hours jam!';
      return 'Terlambat ${diff.inDays} hari!';
    }
    final hours = task.timeUntilDue.inHours;
    if (hours <= 1) return 'Sebentar lagi';
    if (hours < 24) return 'Dalam $hours jam';
    final days = hours ~/ 24;
    if (days == 0) return 'Hari ini';
    if (days == 1) return 'Besok';
    return '$days hari lagi';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<PlantProvider>(
      builder: (context, provider, child) {
        final plantIndex = provider.plants.indexWhere((p) => p.id == plantId);
        if (plantIndex == -1) {
          return const Scaffold(
            body: Center(
              child: Text('Tanaman tidak ditemukan atau telah dihapus.'),
            ),
          );
        }

        final plant = provider.plants[plantIndex];
        final careTasks = provider.getCareTasksForPlant(plant.id);
        final careHistories = provider.getCareHistoriesForPlant(plant.id);
        final String addedDateFormatted = DateFormat(
          'dd MMMM yyyy',
        ).format(plant.dateAdded);

        return Scaffold(
          body: DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    backgroundColor: isDark
                        ? AppColors.backgroundDark
                        : AppColors.primaryLight,
                    iconTheme: const IconThemeData(color: Colors.white),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/add-edit-plant',
                            arguments: plant.id,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, plant),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'plant_image_${plant.id}',
                            child:
                                plant.photoPath != null &&
                                    plant.photoPath!.isNotEmpty
                                ? Image.file(
                                    File(plant.photoPath!),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: isDark
                                        ? const Color(0xFF1E2421)
                                        : const Color(0xFFECECE5),
                                    child: Icon(
                                      Icons.local_florist,
                                      size: 110,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.primaryLight.withValues(
                                              alpha: 0.4,
                                            ),
                                    ),
                                  ),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black45],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.name,
                              style: textTheme.titleLarge?.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plant.species,
                              style: textTheme.bodyLarge?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight,
                              ),
                            ),
                            if (plant.location != null &&
                                plant.location!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    plant.location!,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.surfaceDark
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF252D2A)
                                            : const Color(0xFFE2E2DC),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Kesehatan',
                                          style: textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 8),
                                        HealthBar(
                                          score: plant.healthScore,
                                          height: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.surfaceDark
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF252D2A)
                                            : const Color(0xFFE2E2DC),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Perawatan',
                                          style: textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${careTasks.length} jadwal',
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.primaryDark
                                                : AppColors.primaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            ...careTasks.map((task) => _buildCareTaskCard(
                              context,
                              task,
                              provider,
                              plant,
                              isDark,
                              textTheme,
                            )),

                            const SizedBox(height: 8),
                            Text(
                              'Ditambahkan pada $addedDateFormatted',
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ]),
                  ),

                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        indicatorColor: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                        labelColor: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                        unselectedLabelColor: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        labelStyle: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelStyle: textTheme.bodyMedium,
                        tabs: const [
                          Tab(text: 'Riwayat Perawatan'),
                          Tab(text: 'Riwayat Siram'),
                          Tab(text: 'Diary Tumbuh'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _CareHistoryTab(histories: careHistories),
                  WateringHistory(plant: plant),
                  GrowthTimeline(plant: plant),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCareTaskCard(
    BuildContext context,
    CareTask task,
    PlantProvider provider,
    Plant plant,
    bool isDark,
    TextTheme textTheme,
  ) {
    final isOverdue = task.isOverdue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppColors.error.withValues(alpha: 0.08)
            : (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.3)
              : (isDark ? const Color(0xFF252D2A) : const Color(0xFFE2E2DC)),
        ),
      ),
      child: Row(
        children: [
          _getCareIcon(task.careType, isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.careType.displayName,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Setiap ${task.intervalValue} ${task.intervalUnit.displayNamePlural}',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  _getCareStatusText(task),
                  style: textTheme.bodySmall?.copyWith(
                    color: isOverdue ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(
              _getCompleteIcon(task.careType),
              size: 16,
            ),
            label: Text(
              _getCompleteLabel(task.careType),
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isOverdue ? AppColors.error : AppColors.primaryLight,
              foregroundColor:
                  isOverdue ? Colors.white : (isDark ? Colors.black : Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () async {
              final success = await provider.completeCareTask(plant.id, task.careType);
              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${task.careType.displayName} untuk ${plant.name} selesai!',
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _getCareIcon(CareType type, bool isDark) {
    IconData icon;
    switch (type) {
      case CareType.watering:
        icon = Icons.water_drop;
      case CareType.fertilizing:
        icon = Icons.science;
      case CareType.pruning:
        icon = Icons.content_cut;
      case CareType.pestCheck:
        icon = Icons.bug_report;
      case CareType.repotting:
        icon = Icons.replay;
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor:
          isDark
              ? AppColors.primaryDark.withValues(alpha: 0.15)
              : AppColors.primaryLight.withValues(alpha: 0.1),
      child: Icon(
        icon,
        size: 18,
        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
      ),
    );
  }

  IconData _getCompleteIcon(CareType type) {
    return Icons.check;
  }

  String _getCompleteLabel(CareType type) {
    switch (type) {
      case CareType.watering:
        return 'Siram';
      case CareType.fertilizing:
        return 'Pupuk';
      case CareType.pruning:
        return 'Pangkas';
      case CareType.pestCheck:
        return 'Cek';
      case CareType.repotting:
        return 'Ganti';
    }
  }
}

class _CareHistoryTab extends StatelessWidget {
  final List<CareHistory> histories;

  const _CareHistoryTab({required this.histories});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (histories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_outlined,
                size: 48,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada riwayat perawatan',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Riwayat akan muncul saat Anda menyelesaikan perawatan.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: histories.length,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemBuilder: (context, index) {
        final history = histories[index];
        final formattedDate = DateFormat(
          'dd MMMM yyyy, HH:mm',
        ).format(history.completedAt);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDark ? const Color(0xFF252D2A) : const Color(0xFFE2E2DC),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.success.withValues(alpha: 0.12),
                radius: 20,
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✓ ${history.careType.displayName}',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(formattedDate, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
