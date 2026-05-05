import 'package:flutter_test/flutter_test.dart';
import 'package:app_delibery/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DeliPunoApp());
    await tester.pump();
  });
}
