import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'models/order_model.dart';
import 'screens/chat_screen.dart';
import 'screens/completed_screen.dart';
import 'screens/deliver_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/new_order_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/pickup_screen.dart';
import 'screens/profile/bank_account_screen.dart';
import 'screens/profile/help_support_screen.dart';
import 'screens/profile/personal_data_screen.dart';
import 'screens/profile/security_screen.dart';
import 'screens/profile/vehicle_screen.dart';
import 'screens/register_screen.dart';
import 'screens/review_screen.dart';
import 'screens/route_to_customer_screen.dart';
import 'screens/route_to_store_screen.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: CourierColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const RepartidorApp());
}

class RepartidorApp extends StatelessWidget {
  const RepartidorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dely Repartidor',
      debugShowCheckedModeBanner: false,
      theme: buildCourierTheme(),
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      case '/login':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case '/register':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );
      case '/review':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ReviewScreen(),
        );
      case '/home':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainShell(),
        );
      case '/new-order':
        final order = settings.arguments as OrderModel;
        return PageRouteBuilder(
          settings: settings,
          opaque: false,
          barrierColor: Colors.transparent,
          pageBuilder: (_, _, _) => NewOrderScreen(order: order),
          transitionsBuilder: (_, anim, _, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      case '/order-detail':
        final order = settings.arguments as OrderModel;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => OrderDetailScreen(order: order),
        );
      case '/route-store':
        final order = settings.arguments as OrderModel;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RouteToStoreScreen(order: order),
        );
      case '/pickup':
        final order = settings.arguments as OrderModel;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PickupScreen(order: order),
        );
      case '/route-customer':
        final order = settings.arguments as OrderModel;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RouteToCustomerScreen(order: order),
        );
      case '/deliver':
        final order = settings.arguments as OrderModel;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DeliverScreen(order: order),
        );
      case '/completed':
        final order = settings.arguments as OrderModel;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CompletedScreen(order: order),
        );
      case '/chat':
        final order = settings.arguments as OrderModel;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChatScreen(order: order),
        );
      case '/personal-data':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PersonalDataScreen(),
        );
      case '/vehicle':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const VehicleScreen(),
        );
      case '/bank-account':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const BankAccountScreen(),
        );
      case '/help':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HelpSupportScreen(),
        );
      case '/security':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SecurityScreen(),
        );
    }
    return null;
  }
}
