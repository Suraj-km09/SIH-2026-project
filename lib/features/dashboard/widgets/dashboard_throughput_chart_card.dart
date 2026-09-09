import 'package:flutter/material.dart';
import '../../../widgets/cards/app_card.dart';

class ThroughputDataPoint {
  final String label;
  final double primaryValue;
  final double secondaryValue;

  const ThroughputDataPoint({
    required this.label,
    required this.primaryValue,
    required this.secondaryValue,
  });
}

/// Operational Throughput & Revenue Spline Chart for Executive Dashboard.
/// Implements period switcher pills (Monthly | Weekly | Today) and dual spline curves
/// matching the Screen 1 mobile mockup design.
class DashboardThroughputChartCard extends StatefulWidget {
  const DashboardThroughputChartCard({super.key});

  @override
  State<DashboardThroughputChartCard> createState() =>
      _DashboardThroughputChartCardState();
}

class _DashboardThroughputChartCardState
    extends State<DashboardThroughputChartCard> {
  int _selectedPeriodIndex = 1; // 0: Monthly, 1: Weekly, 2: Today

  List<ThroughputDataPoint> get _currentData {
    if (_selectedPeriodIndex == 0) {
      // Monthly operational revenue / throughput (Jan - Jun)
      return const [
        ThroughputDataPoint(label: 'Jan', primaryValue: 35, secondaryValue: 28),
        ThroughputDataPoint(label: 'Feb', primaryValue: 25, secondaryValue: 38),
        ThroughputDataPoint(label: 'Mar', primaryValue: 42, secondaryValue: 50),
        ThroughputDataPoint(label: 'Apr', primaryValue: 30, secondaryValue: 26),
        ThroughputDataPoint(label: 'May', primaryValue: 48, secondaryValue: 58),
        ThroughputDataPoint(label: 'Jun', primaryValue: 22, secondaryValue: 30),
      ];
    } else if (_selectedPeriodIndex == 1) {
      // Weekly (S M T W T F S) matching exact Screen 1 curve profile
      return const [
        ThroughputDataPoint(label: 'S', primaryValue: 40, secondaryValue: 28),
        ThroughputDataPoint(label: 'M', primaryValue: 25, secondaryValue: 36),
        ThroughputDataPoint(label: 'T', primaryValue: 30, secondaryValue: 56),
        ThroughputDataPoint(label: 'W', primaryValue: 18, secondaryValue: 30),
        ThroughputDataPoint(label: 'T', primaryValue: 40, secondaryValue: 58),
        ThroughputDataPoint(label: 'F', primaryValue: 18, secondaryValue: 28),
        ThroughputDataPoint(label: 'S', primaryValue: 19, secondaryValue: 30),
      ];
    } else {
      // Today (Hourly intervals)
      return const [
        ThroughputDataPoint(label: '08:00', primaryValue: 20, secondaryValue: 25),
        ThroughputDataPoint(label: '11:00', primaryValue: 32, secondaryValue: 42),
        ThroughputDataPoint(label: '14:00', primaryValue: 45, secondaryValue: 52),
        ThroughputDataPoint(label: '17:00', primaryValue: 28, secondaryValue: 34),
        ThroughputDataPoint(label: '20:00', primaryValue: 22, secondaryValue: 29),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Time Switcher Pills matching Screen 1
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final titleColor = isDark ? Colors.white : const Color(0xFF111827);
              final pillBg = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 10,
                spacing: 8,
                children: [
                  Text(
                    'Revenue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  // Segmented Pill Switcher: Monthly | Weekly | Today
                  Container(
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPeriodPill('Monthly', 0),
                          _buildPeriodPill('Weekly', 1),
                          _buildPeriodPill('Today', 2),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Custom Dual Spline Curve Chart
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _SplineDualChartPainter(dataPoints: _currentData),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodPill(String label, int index) {
    final isSelected = _selectedPeriodIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriodIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Builder(
        builder: (context) {
          final themeDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? (themeDark ? Colors.white : const Color(0xFF111827))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (themeDark ? const Color(0xFF111827) : Colors.white)
                    : const Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SplineDualChartPainter extends CustomPainter {
  final List<ThroughputDataPoint> dataPoints;

  _SplineDualChartPainter({required this.dataPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    const paddingLeft = 28.0;
    const paddingRight = 12.0;
    const paddingTop = 14.0;
    const paddingBottom = 26.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    const maxVal = 60.0;
    const minVal = 15.0;
    const range = maxVal - minVal;

    // Grid lines & labels (15, 20, 25, 30, 35, 40, 45, 50, 55, 60)
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final yValues = [15, 20, 25, 30, 35, 40, 45, 50, 55, 60];
    for (final v in yValues) {
      final y = paddingTop + (chartHeight * (1 - (v - minVal) / range));

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      // Only paint every other label or key steps to prevent vertical clutter
      if (v % 5 == 0) {
        textPainter.text = TextSpan(
          text: '$v',
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(paddingLeft - textPainter.width - 5, y - (textPainter.height / 2)),
        );
      }
    }

    // Compute x and y points
    final xStep = chartWidth / (dataPoints.length - 1 > 0 ? dataPoints.length - 1 : 1);
    final primaryPoints = <Offset>[];
    final secondaryPoints = <Offset>[];

    for (int i = 0; i < dataPoints.length; i++) {
      final x = paddingLeft + (i * xStep);
      final pY = paddingTop + (chartHeight * (1 - (dataPoints[i].primaryValue - minVal) / range));
      final sY = paddingTop + (chartHeight * (1 - (dataPoints[i].secondaryValue - minVal) / range));

      primaryPoints.add(Offset(x, pY.clamp(paddingTop, paddingTop + chartHeight)));
      secondaryPoints.add(Offset(x, sY.clamp(paddingTop, paddingTop + chartHeight)));

      // X-Axis labels
      textPainter.text = TextSpan(
        text: dataPoints[i].label,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - paddingBottom + 8),
      );
    }

    // Draw Smooth Splines
    _drawSpline(canvas, secondaryPoints, const Color(0xFFF9A8D4), 2.2); // Pink/Rose secondary curve
    _drawSpline(canvas, primaryPoints, const Color(0xFF111827), 2.4);   // Dark primary curve

    // Draw Markers
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < dataPoints.length; i++) {
      // Secondary pink dot
      dotPaint.color = const Color(0xFFF472B6);
      canvas.drawCircle(secondaryPoints[i], 3.5, dotPaint);
      canvas.drawCircle(secondaryPoints[i], 3.5, dotBorder);

      // Primary dark dot
      dotPaint.color = const Color(0xFF111827);
      canvas.drawCircle(primaryPoints[i], 4, dotPaint);
      canvas.drawCircle(primaryPoints[i], 4, dotBorder);
    }
  }

  void _drawSpline(Canvas canvas, List<Offset> points, Color color, double strokeWidth) {
    if (points.isEmpty) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(ctrlX, p0.dy, ctrlX, p1.dy, p1.dx, p1.dy);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SplineDualChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints;
  }
}
