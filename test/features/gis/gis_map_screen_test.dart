import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/features/gis/gis_map_screen.dart';
import 'package:mineintel_ai/repositories/gis_repository.dart';

void main() {
  group('Phase 10 GisMapScreen Widget Tests', () {
    setUp(() {
      EnvConfig.useMockData = true;
    });

    tearDown(() {
      EnvConfig.useMockData = false;
    });

    testWidgets('Renders GIS Map Screen header, KPI ribbon, and region filters', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockGisRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gisRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: GisMapScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Geospatial Mining Map'), findsOneWidget);
      expect(find.text('Geotagged Assets'), findsOneWidget);
      expect(find.text('Mean Elevation'), findsOneWidget);
      expect(find.text('WGS 84 (GPS)'), findsOneWidget);

      // Filters
      expect(find.text('All Coalfields'), findsOneWidget);
      expect(find.text('Chhattisgarh'), findsOneWidget);

      // Map Viewport or Canvas is active
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('Toggles between Map View and List View', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockGisRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gisRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: GisMapScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find List View button and tap
      final listViewBtn = find.text('Table');
      expect(listViewBtn, findsOneWidget);
      await tester.tap(listViewBtn);
      await tester.pumpAndSettle();

      // Records table should now be rendered
      expect(find.text('ECL_Rajmahal_Production_Report_Aug_2026.pdf'), findsOneWidget);
      expect(find.text('BCCL_Dhanbad_Safety_Audit_Q2_2026.docx'), findsOneWidget);
      expect(find.text('ECL-04'), findsOneWidget);
    });
  });
}
