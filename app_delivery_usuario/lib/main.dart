import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'theme_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_shell.dart';
import 'screens/store_screen.dart';
import 'screens/product_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/addresses_screen.dart';
import 'screens/address_form_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/confirmed_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/rating_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/help_screen.dart';
import 'screens/order_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemeController.instance.initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DeliPunoApp());
}

class DeliPunoApp extends StatelessWidget {
  const DeliPunoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) => MaterialApp(
        title: 'DeliPuno',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeController.instance.mode,
        builder: (context, child) {
          final theme = Theme.of(context);
          final dark = theme.brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: dark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: dark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: theme.colorScheme.surface,
              systemNavigationBarIconBrightness: dark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarDividerColor: theme.colorScheme.outlineVariant,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        initialRoute: '/',
        routes: {
          '/': (ctx) => const SplashScreen(),
          '/login': (ctx) => const LoginScreen(),
          '/register': (ctx) => const RegisterScreen(),
          '/home': (ctx) => const MainShell(),
          '/store': (ctx) => const StoreScreen(),
          '/product': (ctx) => const ProductScreen(),
          '/cart': (ctx) => const CartScreen(),
          '/addresses': (ctx) => const AddressesScreen(),
          '/address-form': (ctx) => const AddressFormScreen(),
          '/summary': (ctx) => const SummaryScreen(),
          '/payment': (ctx) => const PaymentScreen(),
          '/confirmed': (ctx) => const ConfirmedScreen(),
          '/tracking': (ctx) => const TrackingScreen(),
          '/rating': (ctx) => const RatingScreen(),
          '/chat': (ctx) => const ChatScreen(),
          '/notifications': (ctx) => const NotificationsScreen(),
          '/favorites': (ctx) => const FavoritesScreen(),
          '/help': (ctx) => const HelpScreen(),
          '/order-detail': (ctx) => const OrderDetailScreen(),
        },
      ),
    );
  }
}
