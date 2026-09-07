import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/analytics_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/cards/app_card.dart';

/// Responsive Production vs Dispatch Historical Time-Series Chart.
/// Employs a custom painter with restrained color palette, subtle gridlines,
/// and horizontal scrolling on compact mobile viewports to prevent clipping.
class AnalyticsTrendsChartCard extends StatelessWidget {
  final List<TrendItemModel> trends;

  const AnalyticsTrendsChartCard({super.key, required this.trends});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Legend
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 460;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.show_chart_outlined,
                          size: 20,
                          color: AppColors.accentTeal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Production vs Dispatch Trends',
                              style: AppTypography.headlineSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Historical trajectory by operational period',
                              style: AppTypography.labelSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLegendItem('Production', AppColors.accentTeal),
                            const SizedBox(width: 16),
                            _buildLegendItem('Dispatch', AppColors.accentBlue),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (isCompact) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildLegendItem('Production', AppColors.accentTeal),
                        const SizedBox(width: 16),
                        _buildLegendItem('Dispatch', AppColors.accentBlue),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          if (trends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No historical time-series data available.', style: AppTypography.bodySmall),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // Minimum width per data point to guarantee readability on mobile
                final pointSpacing = 70.0;
                final requiredWidth = max(constraints.maxWidth, trends.length * pointSpacing + 60);

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: constraints.maxWidth >= requiredWidth
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    width: requiredWidth,
                    height: 240,
                    child: CustomPaint(
                      size: Size(requiredWidth, 240),
                      painter: _TrendsChartPainter(trends: trends),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TrendsChartPainter extends CustomPainter {
  final List<TrendItemModel> trends;

  _TrendsChartPainter({required this.trends});

  @override
  void paint(Canvas canvas, Size size) {
    if (trends.isEmpty) return;

    final paddingLeft = 55.0;
    final paddingRight = 20.0;
    final paddingTop = 20.0;
    final paddingBottom = 35.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // Find min and max for both production and dispatch
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;

    for (final t in trends) {
      if (t.production < minVal) minVal = t.production;
      if (t.dispatch < minVal) minVal = t.dispatch;
      if (t.production > maxVal) maxVal = t.production;
      if (t.dispatch > maxVal) maxVal = t.dispatch;
    }

    // Add padding to range
    final range = maxVal - minVal;
    final effectiveMin = max(0.0, minVal - (range > 0 ? range * 0.15 : minVal * 0.1));
    final effectiveMax = maxVal + (range > 0 ? range * 0.15 : maxVal * 0.1);
    final valRange = effectiveMax - effectiveMin > 0 ? effectiveMax - effectiveMin : 1.0;

    // Grid lines & Y-Axis labels (4 horizontal lines)
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final gridSteps = 4;
    for (int i = 0; i <= gridSteps; i++) {
      final y = paddingTop + (chartHeight * (1 - i / gridSteps));
      final val = effectiveMin + (valRange * (i / gridSteps));

      // Draw dashed / subtle grid line
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      // Y-axis label
      textPainter.text = TextSpan(
        text: _formatYLabel(val),
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 8, y - (textPainter.height / 2)),
      );
    }

    // Coordinates mapping
    final xStep = chartWidth / (trends.length - 1 > 0 ? trends.length - 1 : 1);

    final prodPoints = <Offset>[];
    final dispPoints = <Offset>[];

    for (int i = 0; i < trends.length; i++) {
      final x = paddingLeft + (i * xStep);
      final prodY = paddingTop + (chartHeight * (1 - (trends[i].production - effectiveMin) / valRange));
      final dispY = paddingTop + (chartHeight * (1 - (trends[i].dispatch - effectiveMin) / valRange));

      prodPoints.add(Offset(x, prodY));
      dispPoints.add(Offset(x, dispY));

      // X-Axis label
      textPainter.text = TextSpan(
        text: trends[i].period,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - paddingBottom + 10),
      );
    }

    // Draw Production line & subtle area
    _drawSeries(
      canvas,
      prodPoints,
      AppColors.accentTeal,
      paddingTop + chartHeight,
    );

    // Draw Dispatch line & subtle area
    _drawSeries(
      canvas,
      dispPoints,
      AppColors.accentBlue,
      paddingTop + chartHeight,
    );

    // Draw point markers
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < trends.length; i++) {
      // Production marker
      dotPaint.color = AppColors.accentTeal;
      canvas.drawCircle(prodPoints[i], 4, dotPaint);
      canvas.drawCircle(prodPoints[i], 4, dotBorderPaint);

      // Dispatch marker
      dotPaint.color = AppColors.accentBlue;
      canvas.drawCircle(dispPoints[i], 4, dotPaint);
      canvas.drawCircle(dispPoints[i], 4, dotBorderPaint);
    }
  }

  void _drawSeries(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double bottomY,
  ) {
    if (points.isEmpty) return;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    final areaPath = Path()..moveTo(points.first.dx, bottomY)..lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
      areaPath.lineTo(points[i].dx, points[i].dy);
    }

    areaPath
      ..lineTo(points.last.dx, bottomY)
      ..close();

    // Fill subtle gradient area
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, points.last.dx, bottomY));

    canvas.drawPath(areaPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);
  }

  String _formatYLabel(double val) {
    if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}k';
    }
    return val.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _TrendsChartPainter oldDelegate) {
    return oldDelegate.trends != trends;
  }
}
