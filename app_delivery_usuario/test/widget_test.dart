import 'package:flutter_test/flutter_test.dart';
import 'package:app_delibery/main.dart';
import 'package:app_delibery/services/cart_service.dart';
import 'package:app_delibery/models/product_model.dart';
import 'package:app_delibery/delivery_config.dart';
import 'package:app_delibery/screens/home_screen.dart';
import 'package:app_delibery/screens/login_screen.dart';
import 'package:app_delibery/screens/main_shell.dart';
import 'package:app_delibery/screens/profile_screen.dart';
import 'package:app_delibery/screens/register_screen.dart';
import 'package:app_delibery/services/auth_service.dart';
import 'package:app_delibery/theme.dart';
import 'package:app_delibery/theme_controller.dart';
import 'package:app_delibery/cart_checkout_sheet.dart';
import 'package:app_delibery/widgets.dart';
import 'package:flutter/material.dart';

void main() {
  test('theme storage values map to all supported modes', () {
    expect(ThemeController.modeFromStorage(null), ThemeMode.system);
    expect(ThemeController.modeFromStorage('system'), ThemeMode.system);
    expect(ThemeController.modeFromStorage('light'), ThemeMode.light);
    expect(ThemeController.modeFromStorage('dark'), ThemeMode.dark);
    expect(ThemeController.modeFromStorage('invalid'), ThemeMode.system);
  });

  test('DeliPuno exposes complete light and dark color schemes', () {
    expect(AppTheme.lightScheme.brightness, Brightness.light);
    expect(AppTheme.darkScheme.brightness, Brightness.dark);
    expect(AppTheme.lightScheme.primary, AppColors.primary);
    expect(AppTheme.darkScheme.primary, AppColors.darkPrimary);
    expect(
      _contrastRatio(
        AppTheme.darkScheme.onSurface,
        AppTheme.darkScheme.surfaceContainerLowest,
      ),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(
        AppTheme.lightScheme.onSurface,
        AppTheme.lightScheme.surfaceContainerLowest,
      ),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DeliPunoApp());
    await tester.pump();
  });

  testWidgets('disabled AppButton does not invoke its action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Continuar',
            onTap: () => taps++,
            isLoading: true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AppButton));
    expect(taps, 0);
  });

  testWidgets('combined login keeps Google and password without OTP', (
    tester,
  ) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(theme: theme, home: const LoginScreen()),
      );
      await tester.pump();

      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Ingresar'), findsOneWidget);
      expect(find.textContaining('código'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('email registration goes directly without an OTP step', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const RegisterScreen()),
    );
    await tester.pump();

    expect(find.text('Crear cuenta'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.textContaining('código'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('Google authentication errors have user-facing messages', () {
    expect(
      AuthService.firebaseErrorMessage('network-request-failed'),
      'Sin conexión a internet.',
    );
    expect(
      AuthService.firebaseErrorMessage(
        'account-exists-with-different-credential',
      ),
      contains('otro método'),
    );
    expect(AuthService.firebaseErrorMessage('unknown'), isNotEmpty);
  });

  testWidgets('home category grid has no overflow on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeCategoryGrid(onSelected: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('fixed delivery notice fits narrow screens', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FixedDeliveryNotice())),
    );

    expect(find.text('Delivery a cualquier local por S/ 9.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back from a secondary main tab returns to home', (tester) async {
    var returnedToHome = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MainTabBackHandler(
          activeIndex: 2,
          onBackToHome: () => returnedToHome = true,
          child: const Scaffold(body: Text('Pedidos')),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(returnedToHome, isTrue);
    expect(find.text('Pedidos'), findsOneWidget);
  });

  test('delivery time labels are not duplicated', () {
    expect(formatDeliveryTime('15-20'), '15-20 min');
    expect(formatDeliveryTime('15-20 min'), '15-20 min');
    expect(formatDeliveryTime('24h'), '24h');
  });

  test('cart total uses one fixed delivery fee', () {
    CartService.clear();
    CartService.addOrIncrement(
      CartEntry(
        productId: 'product-1',
        name: 'Producto',
        tone: 'cool',
        unitPrice: 10,
        qty: 2,
        storeId: 'store-1',
        storeName: 'Comercio',
        storeTone: 'cool',
        deliveryFee: 4,
      ),
    );

    expect(CartService.subtotal, 20);
    expect(CartService.deliveryFee, DeliveryConfig.fixedFee);
    expect(CartService.total, 29);
    CartService.clear();
  });

  test('cart mutations notify listeners and count total units', () {
    CartService.clear();
    var notifications = 0;
    void listener() => notifications++;
    CartService.revision.addListener(listener);
    addTearDown(() => CartService.revision.removeListener(listener));

    final item = CartEntry(
      productId: 'product-1',
      name: 'Producto',
      tone: 'cool',
      unitPrice: 8,
      qty: 2,
      storeId: 'store-1',
      storeName: 'Comercio',
      storeTone: 'cool',
      deliveryFee: 3.5,
    );
    CartService.addOrIncrement(item);
    CartService.incrementEntry(item);
    CartService.decrementEntry(item);

    expect(CartService.itemCount, 2);
    expect(CartService.total, 25);
    expect(notifications, 3);
    CartService.clear();
  });

  testWidgets('cart badge caps its visible count at 99+', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CartCountBadge(count: 120))),
    );

    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('cart floating bar reacts to cart content', (tester) async {
    CartService.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox(),
          bottomNavigationBar: CartFloatingBar(onTap: () {}),
        ),
      ),
    );
    expect(find.text('Ver carrito'), findsNothing);

    CartService.addOrIncrement(
      CartEntry(
        productId: 'product-1',
        name: 'Producto',
        tone: 'cool',
        unitPrice: 10,
        storeId: 'store-1',
        storeName: 'Comercio',
        storeTone: 'cool',
        deliveryFee: 4,
      ),
    );
    await tester.pump();

    expect(find.text('Ver carrito'), findsOneWidget);
    expect(find.text('S/ 19.00'), findsOneWidget);
    CartService.clear();
  });

  testWidgets('cart sheet has no overflow on a small screen', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    CartService.clear();
    CartService.setDeliveryAddress(street: 'Jr. Puno 123');
    CartService.addOrIncrement(
      CartEntry(
        productId: 'product-1',
        name: 'Producto de prueba con nombre largo',
        tone: 'cool',
        unitPrice: 10,
        storeId: 'store-1',
        storeName: 'Comercio',
        storeTone: 'cool',
        deliveryFee: 3.5,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CartCheckoutSheet())),
    );
    await tester.pump();

    expect(find.text('Confirmar pedido'), findsWidgets);
    expect(tester.takeException(), isNull);
    CartService.clear();
  });

  testWidgets('bottom navigation exposes one selected tab', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNavBar(activeIndex: 1, onTap: (_) {}),
        ),
      ),
    );

    final selected = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((widget) => widget.properties.selected == true);
    expect(selected.length, 1);
  });

  test('requiresCustomization follows real product option fields', () {
    const simple = ProductModel(
      id: 'simple',
      storeId: 'store',
      name: 'Simple',
      description: '',
      price: 10,
      category: 'General',
    );
    const withSize = ProductModel(
      id: 'size',
      storeId: 'store',
      name: 'Con tamaño',
      description: '',
      price: 10,
      category: 'General',
      sizes: [ProductVariant(name: 'Personal', price: 10)],
    );
    const withExtra = ProductModel(
      id: 'extra',
      storeId: 'store',
      name: 'Con extra',
      description: '',
      price: 10,
      category: 'General',
      extras: [ProductExtra(name: 'Queso', price: 2)],
    );
    const withCutlery = ProductModel(
      id: 'cutlery',
      storeId: 'store',
      name: 'Con cubiertos',
      description: '',
      price: 10,
      category: 'General',
      cutlery: [ProductExtra(name: 'Cubiertos', price: 0)],
    );

    expect(simple.requiresCustomization, isFalse);
    expect(withSize.requiresCustomization, isTrue);
    expect(withExtra.requiresCustomization, isTrue);
    expect(withCutlery.requiresCustomization, isTrue);
  });

  test(
    'simple products merge but different configurations remain separate',
    () {
      CartService.clear();
      CartEntry entry({required String name, String? note, double price = 10}) {
        return CartEntry(
          productId: 'product-1',
          name: name,
          note: note,
          tone: 'cool',
          unitPrice: price,
          storeId: 'store-1',
          storeName: 'Comercio',
          storeTone: 'cool',
          deliveryFee: 3.5,
        );
      }

      CartService.addOrIncrement(entry(name: 'Producto'));
      CartService.addOrIncrement(entry(name: 'Producto'));
      expect(CartService.items, hasLength(1));
      expect(CartService.itemCount, 2);

      CartService.addOrIncrement(
        entry(name: 'Producto (Familiar)', note: 'Queso', price: 15),
      );
      expect(CartService.items, hasLength(2));
      expect(CartService.itemCount, 3);
      CartService.clear();
    },
  );

  test('a S/ 10.00 product totals S/ 19.00 with fixed delivery', () {
    CartService.clear();
    CartService.addOrIncrement(
      CartEntry(
        productId: 'product-10',
        name: 'Producto',
        tone: 'cool',
        unitPrice: 10,
        storeId: 'store-1',
        storeName: 'Comercio',
        storeTone: 'cool',
        deliveryFee: 0,
      ),
    );

    expect(CartService.subtotal, 10);
    expect(CartService.deliveryFee, 9);
    expect(CartService.total, 19);
    CartService.clear();
  });

  testWidgets('profile header fits a narrow screen without a photo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileHeader(
              name: 'Nombre de usuario considerablemente largo',
              secondaryText: 'usuario.con.correo.largo@example.com',
              photoUrl: null,
              memberSince: null,
              loading: false,
              onEdit: null,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile contact card handles missing and long data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: ProfileContactCard(
              phone: 'No registrado',
              email: 'correo.muy.extenso.para.validar@example-delipuno.com',
            ),
          ),
        ),
      ),
    );

    expect(find.text('No registrado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

double _contrastRatio(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first
      : second;
  final darker = identical(lighter, first) ? second : first;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
