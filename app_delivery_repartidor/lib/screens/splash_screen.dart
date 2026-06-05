import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/courier_service.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideNext());
  }

  Future<void> _decideNext() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final uid = AuthService.currentUid;
    if (uid == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    final courier = await CourierService.getCourier(uid);
    if (!mounted) return;
    if (courier == null) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else if (courier.status == 'active') {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // pending_review / rejected / suspended → waiting room, which live-streams
      // the status and advances on its own once the admin approves.
      Navigator.of(context).pushReplacementNamed('/review');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: CourierColors.primary,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: CourierColors.primary.withValues(alpha: 0.4),
                        blurRadius: 60,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.two_wheeler_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: const [
                    Text(
                      'Dely',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        color: CourierColors.text,
                      ),
                    ),
                    Text(
                      '.',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w800,
                        color: CourierColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: CourierColors.primaryTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'REPARTIDOR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CourierColors.primary,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Center(
              child: Text(
                'v1.0  ·  APP DEL REPARTIDOR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CourierColors.textSubtle,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
