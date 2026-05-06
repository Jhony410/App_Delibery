// Smoke test placeholder. The admin panel boots from `main()` which requires
// Firebase initialisation, so we only assert that the theme builder works.

import 'package:flutter_test/flutter_test.dart';

import 'package:app_delivery_administrator/theme.dart';

void main() {
  test('admin theme builds without error', () {
    final theme = buildAdminTheme();
    expect(theme.scaffoldBackgroundColor, AdminColors.bg);
  });
}
