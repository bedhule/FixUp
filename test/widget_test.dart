import 'package:flutter_test/flutter_test.dart';
import 'package:fixup_app/main.dart';

void main() {
  testWidgets('App renders PublikScreen as landing page', (WidgetTester tester) async {
    await tester.pumpWidget(const FixUpApp());
    expect(find.text('Papan Transparansi'), findsOneWidget);
    expect(find.text('Masuk ke Aplikasi'), findsOneWidget);
  });
}
