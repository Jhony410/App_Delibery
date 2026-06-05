import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/seed_service.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/main_shell.dart';
import 'screens/store_screen.dart';
import 'screens/product_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/address_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/confirmed_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/rating_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SeedService.seedIfEmpty();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DeliPunoApp());
}

class DeliPunoApp extends StatelessWidget {
  const DeliPunoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeliPuno',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      initialRoute: '/',
      routes: {
        '/': (ctx) => const SplashScreen(),
        '/login': (ctx) => const LoginScreen(),
        '/register': (ctx) => const RegisterScreen(),
        '/verify': (ctx) => const VerifyScreen(),
        '/home': (ctx) => const MainShell(),
        '/store': (ctx) => const StoreScreen(),
        '/product': (ctx) => const ProductScreen(),
        '/cart': (ctx) => const CartScreen(),
        '/address': (ctx) => const AddressScreen(),
        '/summary': (ctx) => const SummaryScreen(),
        '/payment': (ctx) => const PaymentScreen(),
        '/confirmed': (ctx) => const ConfirmedScreen(),
        '/tracking': (ctx) => const TrackingScreen(),
        '/rating': (ctx) => const RatingScreen(),
        '/chat': (ctx) => const ChatScreen(),
      },
    );
  }
}
