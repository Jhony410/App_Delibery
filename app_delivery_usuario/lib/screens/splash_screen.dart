import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/biometric_auth_service.dart';
import '../theme.dart';
import '../widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    _sessionTimer = Timer(const Duration(milliseconds: 700), _resolveSession);
  }

  Future<void> _resolveSession() async {
    final user = AuthService.currentUser;
    if (!mounted) return;
    if (user == null) {
      _go('/login');
      return;
    }
    final protected = await BiometricAuthService.hasAccessForUser(user.uid);
    if (!mounted) return;
    _go(protected ? '/login' : '/home');
  }

  void _go(String route) {
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DeliPunoLogo(size: 132),
              const SizedBox(height: 18),
              const DeliPunoWordmark(size: 44),
              const SizedBox(height: 12),
              Text(
                'Delivery local, simple y rápido',
                style: TextStyle(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 28,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
