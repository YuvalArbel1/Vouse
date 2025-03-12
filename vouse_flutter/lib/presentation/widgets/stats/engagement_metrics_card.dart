// lib/presentation/widgets/stats/engagement_metrics_card.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/presentation/providers/filter/post_filtered_provider.dart';

/// A card widget displaying engagement metrics with visualizations.
///
/// Features:
/// - Grid layout of various metrics
/// - Custom styling for each metric
/// - Mini chart visualization using actual metric data
/// - Time period indicator
class EngagementMetricsCard extends ConsumerWidget {
  /// Engagement data to display
  final Map<String, int> metrics;

  /// Active time filter
  final String timeFilter;

  /// Creates an [EngagementMetricsCard] widget.
  const EngagementMetricsCard({
    super.key,
    required this.metrics,
    required this.timeFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the engagementMetricsProvider to get real data
    final realMetrics = ref.watch(engagementMetricsProvider);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '✨ Engagement Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: vPrimaryColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    timeFilter,
                    style: TextStyle(
                      fontSize: 12,
                      color: vPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Engagement metrics grid with emojis
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildMetricItem('❤️ Likes', realMetrics['Likes'] ?? 0,
                    Icons.favorite, Colors.red),
                _buildMetricItem('💬 Comments', realMetrics['Comments'] ?? 0,
                    Icons.chat_bubble, Colors.blue),
                _buildMetricItem('🔄 Reposts', realMetrics['Reposts'] ?? 0,
                    Icons.repeat, Colors.green),
                _buildMetricItem('👁️ Views', realMetrics['Impressions'] ?? 0,
                    Icons.visibility, Colors.purple),
              ],
            ),

            const SizedBox(height: 16),

            // Mini chart using actual data
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: vPrimaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                painter: MiniChartPainter(
                  color: vPrimaryColor,
                  metrics: realMetrics, // Use real metrics for the chart
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an individual metric item tile
  Widget _buildMetricItem(String title, int value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: vBodyGrey,
                ),
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the mini engagement chart that uses actual metric data
class MiniChartPainter extends CustomPainter {
  final Color color;
  final Map<String, int> metrics;

  MiniChartPainter({
    required this.color,
    required this.metrics,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final path = Path();

    // Check if all metrics are zero or metrics are empty
    final allZeros =
        metrics.isEmpty || metrics.values.every((value) => value == 0);

    // Define the metrics we want to display in order
    final metricKeys = ['Likes', 'Comments', 'Reposts', 'Impressions'];

    // Calculate the maximum value for scaling (or use 1 if all are zero)
    final maxValue = allZeros
        ? 1
        : metrics.values
            .fold<int>(0, (max, value) => value > max ? value : max);

    // Generate points based on actual data
    final points = <Offset>[];

    if (allZeros) {
      // If all zeros, draw a flat line in the middle
      for (var i = 0; i < 10; i++) {
        final x = i * size.width / 9;
        final y = size.height * 0.5; // Middle of the chart
        points.add(Offset(x, y));
      }
    } else {
      // Use the actual metric values
      final usableMetrics =
          metricKeys.where((key) => metrics.containsKey(key)).toList();
      final segmentWidth =
          size.width / (usableMetrics.length - 1).clamp(1, double.infinity);

      for (var i = 0; i < usableMetrics.length; i++) {
        final key = usableMetrics[i];
        final value = metrics[key] ?? 0;

        // Normalize value between 0 and 1, then invert for y-coordinate (0 = bottom)
        final normalizedValue = value / maxValue;

        // Convert to y position (higher values = lower y position)
        final y = size.height -
            (normalizedValue * size.height * 0.8) -
            (size.height * 0.1);
        final x = i * segmentWidth;

        points.add(Offset(x, y));
      }

      // If we have less than 2 points, add some fake ones to make a visible line
      if (points.length < 2) {
        points.add(Offset(size.width, points.first.dy));
      }
    }

    // Move to starting point
    path.moveTo(points.first.dx, points.first.dy);

    // Add points with a smooth curve
    for (var i = 1; i < points.length; i++) {
      final p0 = i > 0 ? points[i - 1] : points[0];
      final p1 = points[i];

      path.cubicTo(
        p0.dx + (p1.dx - p0.dx) / 2,
        p0.dy,
        p0.dx + (p1.dx - p0.dx) / 2,
        p1.dy,
        p1.dx,
        p1.dy,
      );
    }

    // Draw the line
    canvas.drawPath(path, paint);

    // Draw dots at data points
    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }

    // Draw a filled gradient area
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withAlpha(100),
          color.withAlpha(10),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
