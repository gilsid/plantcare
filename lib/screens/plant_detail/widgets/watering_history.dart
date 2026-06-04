import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/plant.dart';

class WateringHistory extends StatelessWidget {
  final Plant plant;

  const WateringHistory({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (plant.wateringHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 48,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada riwayat penyiraman',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tekan tombol "Sudah Disiram" jika Anda baru saja menyiram tanaman ini.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: plant.wateringHistory.length,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemBuilder: (context, index) {
        final log = plant.wateringHistory[index];
        final formattedDate = DateFormat(
          'dd MMM yyyy, HH:mm',
        ).format(log.wateredAt);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF252D2A) : const Color(0xFFE2E2DC),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: log.wasOnTime
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12),
                    child: Icon(
                      log.wasOnTime
                          ? Icons.check_rounded
                          : Icons.priority_high_rounded,
                      color: log.wasOnTime
                          ? AppColors.success
                          : AppColors.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.wasOnTime ? 'Tepat Waktu' : 'Terlambat',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: log.wasOnTime
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(formattedDate, style: textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              Icon(
                Icons.check_circle_outline,
                color: isDark ? Colors.white24 : Colors.black12,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }
}
