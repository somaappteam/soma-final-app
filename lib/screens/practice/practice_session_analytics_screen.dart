import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PracticeSessionAnalyticsScreen extends StatelessWidget {
  final String modeName;
  final double? accuracy;
  final double averageResponseSeconds;
  final Duration duration;
  final List<String> weakAreas;
  final String recommendedNextMode;
  final String? adaptiveReason;

  const PracticeSessionAnalyticsScreen({
    super.key,
    required this.modeName,
    required this.accuracy,
    required this.averageResponseSeconds,
    required this.duration,
    required this.weakAreas,
    required this.recommendedNextMode,
    this.adaptiveReason,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Session Analytics', style: TextStyle(color: AppColors.textDark)),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(modeName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 16),
            _buildMetric('Accuracy', accuracy != null ? '${(accuracy! * 100).toStringAsFixed(0)}%' : 'Unavailable'),
            _buildMetric('Data quality', accuracy != null ? 'Measured' : 'Unavailable'),
            _buildMetric('Average response', '${averageResponseSeconds.toStringAsFixed(1)} sec'),
            _buildMetric('Session duration', '${duration.inMinutes}m ${duration.inSeconds % 60}s'),
            const SizedBox(height: 16),
            if (adaptiveReason != null) _buildAdaptiveReasonCard(adaptiveReason!),
            if (adaptiveReason != null) const SizedBox(height: 12),
            const Text('Focus areas', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            ...weakAreas.map((area) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.adjust, size: 16, color: AppColors.primaryTeal),
                      const SizedBox(width: 8),
                      Expanded(child: Text(area, style: const TextStyle(color: AppColors.textMedium))),
                    ],
                  ),
                )),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
              ),
              child: Text('Recommended next: $recommendedNextMode', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAdaptiveReasonCard(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primaryTeal, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(color: AppColors.textDark, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMedium)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }
}
