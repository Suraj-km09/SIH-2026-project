import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/app.dart';

void main() {
  testWidgets('MineIntelApp mounts and renders foundation dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MineIntelApp(home: FoundationGalleryScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify title and key metric labels render
    expect(find.text('Executive Dashboard'), findsAtLeastNWidgets(1));
    expect(find.text('Ingested Documents'), findsOneWidget);
    expect(find.text('Extracted Records'), findsOneWidget);
    expect(find.text('Quality Score'), findsOneWidget);
  });
}
