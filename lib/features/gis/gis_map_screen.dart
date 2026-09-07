import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gis_model.dart';
import '../../state/gis_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/error_state.dart';
import '../../widgets/feedback/loading_indicator.dart';
import '../../widgets/layout/responsive_layout.dart';

/// Professional interactive GIS and Spatial Mapping screen.
/// Consumes `GET /integration/gis` to plot actual mine coordinate data
/// without fabricating any geographic locations.
class GisMapScreen extends ConsumerStatefulWidget {
  const GisMapScreen({super.key});

  @override
  ConsumerState<GisMapScreen> createState() => _GisMapScreenState();
}

class _GisMapScreenState extends ConsumerState<GisMapScreen> {
  final TransformationController _transformController =
      TransformationController();
  bool _showListView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gisNotifierProvider.notifier).loadGisRecords();
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetMapTransform() {
    _transformController.value = Matrix4.identity();
  }

  void _zoomIn() {
    _transformController.value =
        _transformController.value * Matrix4.diagonal3Values(1.25, 1.25, 1.0);
  }

  void _zoomOut() {
    _transformController.value =
        _transformController.value * Matrix4.diagonal3Values(0.8, 0.8, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final gisState = ref.watch(gisNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(gisState),
          Expanded(
            child: _buildBody(gisState),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(GisState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: ResponsiveBuilder(
        builder: (context, isMobile, isTablet, isDesktop) {
          final titleWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.map_outlined,
                      size: 22, color: AppColors.accentTeal),
                  Text('Geospatial Mining Map',
                      style: AppTypography.headlineMedium),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.badgeNeutralBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${state.validCoordinateRecords.length} Geotagged',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.badgeNeutralText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Coordinates and spatial lease metadata synchronized strictly via GET /integration/gis',
                style: AppTypography.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

          final actionsWidget = Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Toggle List/Map View
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.map, size: 16),
                    label: Text('Canvas'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.table_chart_outlined, size: 16),
                    label: Text('Table'),
                  ),
                ],
                selected: {_showListView},
                onSelectionChanged: (selected) {
                  setState(() => _showListView = selected.first);
                },
              ),
              const SizedBox(width: 4),
              OutlinedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () =>
                        ref.read(gisNotifierProvider.notifier).loadGisRecords(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget,
                const SizedBox(height: 12),
                actionsWidget,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleWidget),
              actionsWidget,
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(GisState state) {
    if (state.isLoading && state.records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: AppLoadingIndicator(message: 'Loading GIS spatial metadata...'),
        ),
      );
    }

    if (state.errorMessage != null && state.records.isEmpty) {
      return ErrorStateWidget(
        title: 'Failed to Load GIS Data',
        message: state.errorMessage!,
        onRetry: () => ref.read(gisNotifierProvider.notifier).loadGisRecords(),
      );
    }

    if (state.records.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Spatial Documents Found',
        description:
            'No documents with geographic metadata returned by the GIS integration service.',
        icon: Icons.location_off_outlined,
      );
    }

    return Column(
      children: [
        _buildKpiRibbon(state),
        _buildRegionFilterBar(state),
        Expanded(
          child: _showListView
              ? _buildRecordsTable(state)
              : _buildMapViewport(state),
        ),
      ],
    );
  }

  Widget _buildKpiRibbon(GisState state) {
    final validRecords = state.validCoordinateRecords;
    final elevations = validRecords
        .map((r) => r.elevation)
        .whereType<double>()
        .toList();
    final avgElevation = elevations.isNotEmpty
        ? elevations.reduce((a, b) => a + b) / elevations.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiItem(
              icon: Icons.pin_drop_outlined,
              label: 'Geotagged Assets',
              value: '${validRecords.length}',
              accent: AppColors.accentTeal,
            ),
            const SizedBox(width: 24),
            _buildKpiItem(
              icon: Icons.landscape_outlined,
              label: 'Mean Elevation',
              value: '${avgElevation.toStringAsFixed(1)} m ASL',
              accent: AppColors.warning,
            ),
            const SizedBox(width: 24),
            _buildKpiItem(
              icon: Icons.hub_outlined,
              label: 'Covered Regions',
              value: '${state.availableRegions.length - 1}',
              accent: AppColors.accentBlue,
            ),
            const SizedBox(width: 24),
            _buildKpiItem(
              icon: Icons.satellite_alt_outlined,
              label: 'Datum / System',
              value: 'WGS 84 (GPS)',
              accent: AppColors.accentGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiItem({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: accent),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.labelSmall),
            Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegionFilterBar(GisState state) {
    final regions = state.availableRegions;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text('Filter Region:',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                )),
            const SizedBox(width: 12),
            ...regions.map((region) {
              final isSelected = state.selectedRegion == region;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(region == 'ALL' ? 'All Coalfields' : region),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      ref
                          .read(gisNotifierProvider.notifier)
                          .setRegionFilter(region);
                    }
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMapViewport(GisState state) {
    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        final canvasWidget = _buildInteractiveCanvas(state);

        if (isMobile) {
          return Stack(
            children: [
              canvasWidget,
              if (state.selectedRecord != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _buildSelectedLocationCard(state.selectedRecord!),
                ),
            ],
          );
        }

        // Desktop / Tablet layout with side inspector
        return Row(
          children: [
            Expanded(child: canvasWidget),
            const VerticalDivider(width: 1),
            SizedBox(
              width: 360,
              child: state.selectedRecord != null
                  ? _buildSelectedLocationInspector(state.selectedRecord!)
                  : _buildUnselectedPlaceholder(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInteractiveCanvas(GisState state) {
    final records = state.filteredRecords;

    return Stack(
      children: [
        // Spatial Coordinate Canvas
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapUp: (details) =>
                  _handleCanvasTap(details.localPosition, constraints.biggest, records),
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.5,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(100),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _GisCoordinatePainter(
                    records: records,
                    selectedRecord: state.selectedRecord,
                  ),
                ),
              ),
            );
          },
        ),

        // Controls overlay (zoom in/out/reset)
        Positioned(
          right: 16,
          top: 16,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Zoom In',
                  onPressed: _zoomIn,
                ),
                const Divider(height: 1),
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  tooltip: 'Zoom Out',
                  onPressed: _zoomOut,
                ),
                const Divider(height: 1),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong, size: 20),
                  tooltip: 'Reset Viewport',
                  onPressed: _resetMapTransform,
                ),
              ],
            ),
          ),
        ),

        // Coordinate Legend overlay
        Positioned(
          left: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.heroSurface.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.navigation, size: 14, color: AppColors.accentTeal),
                const SizedBox(width: 6),
                Text(
                  'North Indicator: Top | Grid: 2° Lat/Long Increments',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textInverse,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleCanvasTap(
      Offset localPosition, Size canvasSize, List<GisDocumentRecord> records) {
    if (records.isEmpty) return;

    // Bounds calculation matching painter
    double minLat = 90.0, maxLat = -90.0;
    double minLng = 180.0, maxLng = -180.0;

    for (final r in records) {
      if (r.latitude != null && r.longitude != null) {
        minLat = math.min(minLat, r.latitude!);
        maxLat = math.max(maxLat, r.latitude!);
        minLng = math.min(minLng, r.longitude!);
        maxLng = math.max(maxLng, r.longitude!);
      }
    }

    // Safety margins
    minLat -= 1.0;
    maxLat += 1.0;
    minLng -= 1.5;
    maxLng += 1.5;

    const padding = 60.0;
    final usableW = canvasSize.width - padding * 2;
    final usableH = canvasSize.height - padding * 2;

    GisDocumentRecord? closest;
    double minDistance = 36.0; // 36 px touch radius

    for (final r in records) {
      if (r.latitude == null || r.longitude == null) continue;

      final normX = (r.longitude! - minLng) / (maxLng - minLng);
      final normY = (r.latitude! - minLat) / (maxLat - minLat);

      final screenX = padding + normX * usableW;
      final screenY = canvasSize.height - padding - normY * usableH;

      final dist = math.sqrt(math.pow(localPosition.dx - screenX, 2) +
          math.pow(localPosition.dy - screenY, 2));

      if (dist < minDistance) {
        minDistance = dist;
        closest = r;
      }
    }

    if (closest != null) {
      ref.read(gisNotifierProvider.notifier).selectRecord(closest);
    }
  }

  Widget _buildSelectedLocationInspector(GisDocumentRecord record) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Site Inspector',
                  style: AppTypography.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: record.status),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Mine Code',
            record.mineCode ?? 'Unassigned',
            isBold: true,
            badgeColor: AppColors.accentTeal.withValues(alpha: 0.1),
          ),
          _buildDetailRow('Coalfield Region', record.region ?? 'India'),
          _buildDetailRow(
            'Coordinates',
            '${record.latitude?.toStringAsFixed(4)}° N, ${record.longitude?.toStringAsFixed(4)}° E',
          ),
          _buildDetailRow(
            'Elevation',
            record.elevation != null ? '${record.elevation} m ASL' : 'Unspecified',
          ),
          _buildDetailRow('Document Category', record.category),
          const Divider(height: 24),
          Text('Linked Source Document', style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined,
                    size: 24, color: AppColors.accentBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.originalName,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${record.id}',
                        style: AppTypography.labelSmall.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected mine: ${record.mineCode} (${record.originalName})'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('View Linked Document Details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedLocationCard(GisDocumentRecord record) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.mineCode ?? 'MINE',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.accentTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(record.region ?? 'Coalfield',
                        style: AppTypography.labelMedium),
                  ],
                ),
                StatusChip(status: record.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              record.originalName,
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${record.latitude?.toStringAsFixed(4)}° N, ${record.longitude?.toStringAsFixed(4)}° E | ${record.elevation ?? 0} m',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTypography.labelSmall)),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: badgeColor != null
                  ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                  : EdgeInsets.zero,
              decoration: badgeColor != null
                  ? BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnselectedPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined,
                size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('Select a Mining Pinpoint',
                style: AppTypography.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Click any asset marker on the interactive canvas to inspect coordinates, elevation, and source documents.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsTable(GisState state) {
    final records = state.filteredRecords;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
            columns: const [
              DataColumn(label: Text('Document')),
              DataColumn(label: Text('Mine Code')),
              DataColumn(label: Text('Region')),
              DataColumn(label: Text('Latitude')),
              DataColumn(label: Text('Longitude')),
              DataColumn(label: Text('Elevation')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Status')),
            ],
            rows: records.map((r) {
              final isSelected = state.selectedRecord?.id == r.id;
              return DataRow(
                selected: isSelected,
                onSelectChanged: (_) {
                  ref.read(gisNotifierProvider.notifier).selectRecord(r);
                },
                cells: [
                  DataCell(Text(
                    r.originalName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )),
                  DataCell(Text(
                    r.mineCode ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text(r.region ?? '—')),
                  DataCell(Text(r.latitude?.toStringAsFixed(4) ?? '—')),
                  DataCell(Text(r.longitude?.toStringAsFixed(4) ?? '—')),
                  DataCell(Text(r.elevation != null ? '${r.elevation} m' : '—')),
                  DataCell(Text(r.category)),
                  DataCell(StatusChip(status: r.status)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Custom painter rendering a geographical coordinate grid and verified mine markers.
class _GisCoordinatePainter extends CustomPainter {
  final List<GisDocumentRecord> records;
  final GisDocumentRecord? selectedRecord;

  _GisCoordinatePainter({
    required this.records,
    required this.selectedRecord,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background Fill (Subtle topographic grid)
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (records.isEmpty) return;

    // 2. Compute dynamic latitude / longitude boundaries
    double minLat = 90.0, maxLat = -90.0;
    double minLng = 180.0, maxLng = -180.0;

    for (final r in records) {
      if (r.latitude != null && r.longitude != null) {
        minLat = math.min(minLat, r.latitude!);
        maxLat = math.max(maxLat, r.latitude!);
        minLng = math.min(minLng, r.longitude!);
        maxLng = math.max(maxLng, r.longitude!);
      }
    }

    // Safety margins around coordinate bounds
    minLat -= 1.0;
    maxLat += 1.0;
    minLng -= 1.5;
    maxLng += 1.5;

    const padding = 60.0;
    final usableW = size.width - padding * 2;
    final usableH = size.height - padding * 2;

    // 3. Grid Lines & Meridian / Parallel Labels
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw 4 Longitude lines
    for (int i = 0; i <= 4; i++) {
      final frac = i / 4.0;
      final x = padding + frac * usableW;
      canvas.drawLine(Offset(x, padding / 2), Offset(x, size.height - padding / 2), gridPaint);

      final lngVal = minLng + frac * (maxLng - minLng);
      textPainter.text = TextSpan(
        text: '${lngVal.toStringAsFixed(1)}° E',
        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - padding / 2 + 4));
    }

    // Draw 4 Latitude lines
    for (int j = 0; j <= 4; j++) {
      final frac = j / 4.0;
      final y = size.height - padding - frac * usableH;
      canvas.drawLine(Offset(padding / 2, y), Offset(size.width - padding / 2, y), gridPaint);

      final latVal = minLat + frac * (maxLat - minLat);
      textPainter.text = TextSpan(
        text: '${latVal.toStringAsFixed(1)}° N',
        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(padding / 2 - textPainter.width - 6, y - textPainter.height / 2));
    }

    // 4. Draw Connections / Region Corridors
    final connectionPaint = Paint()
      ..color = AppColors.accentTeal.withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool first = true;
    for (final r in records) {
      if (r.latitude == null || r.longitude == null) continue;
      final normX = (r.longitude! - minLng) / (maxLng - minLng);
      final normY = (r.latitude! - minLat) / (maxLat - minLat);
      final sx = padding + normX * usableW;
      final sy = size.height - padding - normY * usableH;
      if (first) {
        path.moveTo(sx, sy);
        first = false;
      } else {
        path.lineTo(sx, sy);
      }
    }
    canvas.drawPath(path, connectionPaint);

    // 5. Draw Mine Asset Pinpoints
    for (final r in records) {
      if (r.latitude == null || r.longitude == null) continue;

      final normX = (r.longitude! - minLng) / (maxLng - minLng);
      final normY = (r.latitude! - minLat) / (maxLat - minLat);

      final sx = padding + normX * usableW;
      final sy = size.height - padding - normY * usableH;

      final isSelected = selectedRecord?.id == r.id;

      // Selection Halo
      if (isSelected) {
        final haloPaint = Paint()
          ..color = AppColors.accentTeal.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(sx, sy), 22, haloPaint);

        final haloBorder = Paint()
          ..color = AppColors.accentTeal
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(sx, sy), 22, haloBorder);
      }

      // Outer Circle
      final outerPaint = Paint()
        ..color = isSelected ? AppColors.accentTeal : const Color(0xFF0F172A)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(sx, sy), isSelected ? 12 : 9, outerPaint);

      // Inner Core
      final innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(sx, sy), isSelected ? 5 : 4, innerPaint);

      // Mine Code Tag Callout
      final tagText = r.mineCode ?? 'MINE';
      final tagPainter = TextPainter(
        text: TextSpan(
          text: tagText,
          style: TextStyle(
            fontSize: isSelected ? 12 : 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.accentTeal : const Color(0xFF1E293B),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tagPainter.layout();

      // Callout Background Bubble
      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          sx - tagPainter.width / 2 - 6,
          sy - (isSelected ? 36 : 30),
          tagPainter.width + 12,
          tagPainter.height + 6,
        ),
        const Radius.circular(6),
      );

      final bubblePaint = Paint()
        ..color = isSelected ? Colors.white : const Color(0xFFFFFFFF)
        ..style = PaintingStyle.fill;
      final bubbleBorder = Paint()
        ..color = isSelected ? AppColors.accentTeal : const Color(0xFFCBD5E1)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(bubbleRect, bubblePaint);
      canvas.drawRRect(bubbleRect, bubbleBorder);

      tagPainter.paint(
        canvas,
        Offset(sx - tagPainter.width / 2, sy - (isSelected ? 36 : 30) + 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GisCoordinatePainter oldDelegate) {
    return oldDelegate.records != records ||
        oldDelegate.selectedRecord != selectedRecord;
  }
}
