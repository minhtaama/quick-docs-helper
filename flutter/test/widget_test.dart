import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('QuickDocsApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QuickDocsApp());
    expect(find.text('QUICK DOCS HELPER (FLUTTER)'), findsOneWidget);
  });
}
