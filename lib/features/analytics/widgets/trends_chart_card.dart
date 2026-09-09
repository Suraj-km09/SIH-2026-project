import 'package:flutter/material.dart';
import '../../../models/analytics_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/cards/app_card.dart';

/// Responsive Production vs Dispatch Historical Time-Series Chart.
/// Employs dynamic dual-curve mountain wave area painter driven entirely by real data.
/// Zero hardcoded points or weekday placeholders.
class AnalyticsTrendsChartCard extends StatefulWidget {
  final List<TrendItemModel> trends;
  final List<PeriodSummaryModel>? periods;

  const AnalyticsTrendsChartCard({
    super.key,
    required this.trends,
    this.periods,
  });

  @override
  State<AnalyticsTrendsChartCard> createState() => _AnalyticsTrendsChartCardState();
}

class _AnalyticsTrendsChartCardState extends State<AnalyticsTrendsChartCard> {
  int _selectedFilterIndex = 0; // 0: All Periods, 1: Quarterly (FY26), 2: Annual

  List<TrendItemModel> get _allBaseTrends {
    // 1. If periods model from overview is available, use it as primary aggregated time-series
    if (widget.periods != null && widget.periods!.isNotEmpty) {
      final active = widget.periods!
          .where((p) => p.production > 0 || p.dispatch > 0)
          .map((p) => TrendItemModel(
                period: _cleanPeriodLabel(p.period),
                production: p.production,
                dispatch: p.dispatch,
                unit: p.unit,
              ))
          .toList();
      if (active.isNotEmpty) return active;
    }

    // 2. Otherwise use the provided trends list
    if (widget.trends.isNotEmpty) {
      return widget.trends.map((t) {
        return TrendItemModel(
          period: _cleanPeriodLabel(t.period),
          production: t.production,
          dispatch: t.dispatch,
          unit: t.unit,
        );
      }).toList();
    }

    return const [];
  }

  String _cleanPeriodLabel(String raw) {
    if (raw.contains('FY2026')) {
      return raw.replaceAll('FY2026', "'26").trim();
    }
    if (raw.contains('FY 2023')) {
      return raw.replaceAll('FY 2023', "'23").trim();
    }
    return raw.trim();
  }

  List<TrendItemModel> get _effectiveTrends {
    final base = _allBaseTrends;
    if (base.isEmpty) return const [];

    if (_selectedFilterIndex == 1) {
      // Quarterly filter: items containing 'Q'
      final quarterly = base.where((t) => t.period.toUpperCase().contains('Q')).toList();
      if (quarterly.isNotEmpty) return quarterly;
      // Fallback to second half of list if no quarterly keywords
      final mid = (base.length / 2).floor();
      return base.sublist(mid);
    } else if (_selectedFilterIndex == 2) {
      // Annual filter: 4-digit years or annual labels
      final annual = base
          .where((t) => RegExp(r'^\d{4}$').hasMatch(t.period) || t.period.contains('FY'))
          .toList();
      if (annual.isNotEmpty) return annual;
      // Fallback to first half
      final mid = (base.length / 2).ceil();
      return base.sublist(0, mid);
    }

    // Default: All Periods (limit to latest 8 to keep mobile X-axis clean)
    if (base.length > 8) {
      return base.sublist(base.length - 8);
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final trends = _effectiveTrends;

    double totalProd = 0;
    double totalDisp = 0;
    for (final t in trends) {
      totalProd += t.production;
      totalDisp += t.dispatch;
    }

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Dynamic Time Filter Pills
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            spacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Production vs Dispatch Trends',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Real-time extraction & evacuation volume curves',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Real Data Filter Pills
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPill('All Periods', 0),
                    _buildPill('Quarterly', 1),
                    _buildPill('Annual', 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Legend Indicators & Active Metrics Summary
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(0xFF111827),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Production',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(0xFF38BDF8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dispatch',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (trends.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_formatMetric(totalProd)} MT Prod · ${_formatMetric(totalDisp)} MT Disp',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Real Data Mountain Wave Area Painter Chart
          if (trends.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Text(
                'No production trend records available for selected filter.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            SizedBox(
              height: 220,
              width: double.infinity,
              child: CustomPaint(
                size: const Size(double.infinity, 220),
                painter: _MountainWaveChartPainter(trends: trends),
              ),
            ),
        ],
      ),
    );
  }

  String _formatMetric(double val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(1);
  }

  Widget _buildPill(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111827) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MountainWaveChartPainter extends CustomPainter {
  final List<TrendItemModel> trends;

  _MountainWaveChartPainter({required this.trends});

  @override
  void paint(Canvas canvas, Size size) {
    if (trends.isEmpty) return;

    const paddingLeft = 40.0;
    const paddingRight = 16.0;
    const paddingTop = 16.0;
    const paddingBottom = 26.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;
    final bottomY = paddingTop + chartHeight;

    double maxVal = 0.0;
    for (final t in trends) {
      if (t.production > maxVal) maxVal = t.production;
      if (t.dispatch > maxVal) maxVal = t.dispatch;
    }
    if (maxVal <= 0.0) maxVal = 100.0;
    maxVal = maxVal * 1.15; // 15% top margin
    const minVal = 0.0;
    final range = maxVal - minVal;

    // Grid lines & labels
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final numSteps = 4;
    for (int i = 0; i <= numSteps; i++) {
      final v = minVal + (range * i / numSteps);
      final y = paddingTop + (chartHeight * (1 - i / numSteps));

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final label = _formatAxis(v);
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - (textPainter.height / 2)),
      );
    }

    // Coordinates mapping
    final xStep = chartWidth / (trends.length - 1 > 0 ? trends.length - 1 : 1);
    final prodPoints = <Offset>[];
    final dispPoints = <Offset>[];

    for (int i = 0; i < trends.length; i++) {
      final x = paddingLeft + (i * xStep);
      final pVal = trends[i].production;
      final dVal = trends[i].dispatch;

      final prodY = paddingTop + (chartHeight * (1 - (pVal - minVal) / range));
      final dispY = paddingTop + (chartHeight * (1 - (dVal - minVal) / range));

      prodPoints.add(Offset(x, prodY.clamp(paddingTop, bottomY)));
      dispPoints.add(Offset(x, dispY.clamp(paddingTop, bottomY)));

      // X-Axis labels
      textPainter.text = TextSpan(
        text: trends[i].period,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - paddingBottom + 8),
      );
    }

    // 1. Draw Dispatch Mountain Wave Area (Cool Sky/Slate gradient)
    _drawMountainArea(
      canvas,
      dispPoints,
      bottomY,
      const Color(0xFF38BDF8).withValues(alpha: 0.35),
      const Color(0xFF38BDF8).withValues(alpha: 0.05),
    );

    // Stroke for Dispatch curve
    _drawCurveStroke(canvas, dispPoints, const Color(0xFF0284C7), 2.0);

    // 2. Draw Production Mountain Wave Area (Dark Charcoal/Navy gradient)
    _drawMountainArea(
      canvas,
      prodPoints,
      bottomY,
      const Color(0xFF1E232E).withValues(alpha: 0.85),
      const Color(0xFF1E232E).withValues(alpha: 0.40),
    );

    // Stroke for Production curve
    _drawCurveStroke(canvas, prodPoints, const Color(0xFF0F172A), 2.5);

    // 3. Draw Peak Markers for both metrics
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < prodPoints.length; i++) {
      // Production node: Charcoal
      dotPaint.color = const Color(0xFF0F172A);
      canvas.drawCircle(prodPoints[i], 4.0, dotPaint);

      // Dispatch node: Sky Blue with white outline
      dotPaint.color = Colors.white;
      canvas.drawCircle(dispPoints[i], 4.0, dotPaint);
      dotPaint.color = const Color(0xFF0284C7);
      canvas.drawCircle(dispPoints[i], 2.5, dotPaint);
    }
  }

  String _formatAxis(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  void _drawCurveStroke(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(ctrlX, p0.dy, ctrlX, p1.dy, p1.dx, p1.dy);
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  void _drawMountainArea(
    Canvas canvas,
    List<Offset> points,
    double bottomY,
    Color topColor,
    Color bottomColor,
  ) {
    if (points.isEmpty) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(ctrlX, p0.dy, ctrlX, p1.dy, p1.dx, p1.dy);
    }

    path
      ..lineTo(points.last.dx, bottomY)
      ..lineTo(points.first.dx, bottomY)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, bottomColor],
      ).createShader(Rect.fromLTWH(0, 0, points.last.dx, bottomY));

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _MountainWaveChartPainter oldDelegate) {
    return oldDelegate.trends != trends;
  }
}
