import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/widgets/badges/status_chip.dart';
import 'package:mineintel_ai/widgets/buttons/app_button.dart';
import 'package:mineintel_ai/widgets/cards/app_card.dart';
import 'package:mineintel_ai/widgets/feedback/error_state.dart';
import 'package:mineintel_ai/widgets/inputs/app_text_field.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('Reusable UI Widgets Tests', () {
    testWidgets('AppButton renders text and triggers callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          AppButton(
            text: 'Test Button',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.text('Test Button'));
      expect(tapped, true);
    });

    testWidgets('StatusChip renders formatted status label', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const StatusChip(status: 'unit_mismatch'),
        ),
      );

      expect(find.text('Unit Mismatch'), findsOneWidget);
    });

    testWidgets('MetricCard renders title and numeric KPI', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const MetricCard(
            title: 'Extracted Metrics',
            value: '4,200',
            progress: 0.75,
          ),
        ),
      );

      expect(find.text('Extracted Metrics'), findsOneWidget);
      expect(find.text('4,200'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('AppTextField renders label and hint', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const AppTextField(
            label: 'Username',
            hint: 'Enter your username',
          ),
        ),
      );

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Enter your username'), findsOneWidget);
    });

    testWidgets('ErrorBanner renders message', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const ErrorBanner(
            message: 'Critical server error occurred',
          ),
        ),
      );

      expect(find.text('Critical server error occurred'), findsOneWidget);
    });
  });
}
