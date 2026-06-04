import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

class HealthBar extends StatelessWidget {
  final double score;
  final bool showText;
  final double height;

  const HealthBar({
    super.key,
    required this.score,
    this.showText = true,
    this.height = 8.0,
  });

  Color _getColor(double score) {
    if (score >= 80.0) return AppColors.success;
    if (score >= 40.0) return AppColors.warning;
    return AppColors.error;
  }

  String _getStatusText(double score) {
    if (score >= 80.0) return 'Sangat Sehat';
    if (score >= 60.0) return 'Cukup Sehat';
    if (score >= 40.0) return 'Perlu Perhatian';
    return 'Butuh Perawatan';
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _getColor(score);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showText)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStatusText(score),
                style: textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        if (showText) const SizedBox(height: 6),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: LinearProgressIndicator(
            value: score / 100.0,
            backgroundColor: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFECECE5)
                : const Color(0xFF252D2A),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: height,
          ),
        ),
      ],
    );
  }
}
