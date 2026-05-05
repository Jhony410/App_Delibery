import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_delivery_repartidor/screens/login_screen.dart';
import 'package:app_delivery_repartidor/theme.dart';

void main() {
  testWidgets('LoginScreen renders the courier hero copy',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCourierTheme(),
        home: const LoginScreen(),
      ),
    );
    expect(find.text('Hola repartidor'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
