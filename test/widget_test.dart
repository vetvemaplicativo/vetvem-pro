import 'package:flutter_test/flutter_test.dart';
import 'package:vetvem_pro/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VetVemProApp());
    expect(find.byType(VetVemProApp), findsOneWidget);
  });
}
