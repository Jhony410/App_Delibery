import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/courier_model.dart';
import 'models/order_model.dart';
import 'models/store_model.dart';
import 'routes.dart';
import 'screens/admin_users_screen.dart';
import 'screens/approvals_screen.dart';
import 'screens/courier_detail_screen.dart';
import 'screens/couriers_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/live_map_screen.dart';
import 'screens/login_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/pricing_screen.dart';
import 'screens/promotions_screen.dart';
import 'screens/setup_admin_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/store_detail_screen.dart';
import 'screens/stores_screen.dart';
import 'screens/support_screen.dart';
import 'screens/zones_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RunaAdminApp());
}

class RunaAdminApp extends StatelessWidget {
  const RunaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runa Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: buildAdminTheme(),
      initialRoute: AdminRoutes.splash,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case AdminRoutes.splash:
        page = const SplashScreen();
        break;
      case AdminRoutes.login:
        page = const LoginScreen();
        break;
      case AdminRoutes.setup:
        page = const SetupAdminScreen();
        break;
      case AdminRoutes.dashboard:
        page = const DashboardScreen();
        break;
      case AdminRoutes.orders:
        page = const OrdersScreen();
        break;
      case AdminRoutes.orderDetail:
        final args = settings.arguments;
        if (args is OrderModel) {
          page = OrderDetailScreen(initial: args);
        } else if (args is String) {
          page = OrderDetailScreen(orderId: args);
        } else {
          page = const OrderDetailScreen();
        }
        break;
      case AdminRoutes.liveMap:
        page = const LiveMapScreen();
        break;
      case AdminRoutes.stores:
        page = const StoresScreen();
        break;
      case AdminRoutes.storeDetail:
        final args = settings.arguments;
        page = StoreDetailScreen(
            store: args is StoreModel ? args : null);
        break;
      case AdminRoutes.couriers:
        page = const CouriersScreen();
        break;
      case AdminRoutes.courierDetail:
        final args = settings.arguments;
        page = CourierDetailScreen(
            courier: args is CourierModel ? args : null);
        break;
      case AdminRoutes.approvals:
        page = const ApprovalsScreen();
        break;
      case AdminRoutes.customers:
        page = const CustomersScreen();
        break;
      case AdminRoutes.finance:
        page = const FinanceScreen();
        break;
      case AdminRoutes.zones:
        page = const ZonesScreen();
        break;
      case AdminRoutes.pricing:
        page = const PricingScreen();
        break;
      case AdminRoutes.promotions:
        page = const PromotionsScreen();
        break;
      case AdminRoutes.adminUsers:
        page = const AdminUsersScreen();
        break;
      case AdminRoutes.support:
        page = const SupportScreen();
        break;
      default:
        page = const SplashScreen();
    }
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, anim, secondary) => page,
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 150),
    );
  }
}
