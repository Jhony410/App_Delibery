import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});

  static const _digits = ['9', '8', '7', '6', '', ''];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chevron_left, size: 22),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verifica tu\nnúmero',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.84,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: 'Enviamos un código de 6 dígitos a\n'),
                    TextSpan(
                      text: '+51 987 654 321',
                      style: TextStyle(
                        color: AppColors.appText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_digits.length, (i) {
                  final d = _digits[i];
                  final filled = d.isNotEmpty;
                  final isCursor = i == 4;
                  return Container(
                    width: 48,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: filled ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                      color: filled ? AppColors.primaryTint : Colors.white,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (filled)
                          Text(
                            d,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.appText,
                            ),
                          ),
                        if (isCursor)
                          Positioned(
                            bottom: 10,
                            child: Container(
                              width: 2,
                              height: 24,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              Center(
                child: RichText(
                  text: const TextSpan(
                    style:
                        TextStyle(fontSize: 14, color: AppColors.textMuted),
                    children: [
                      TextSpan(text: '¿No recibiste el código? '),
                      TextSpan(
                        text: 'Reenviar (0:32)',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              AppButton(
                label: 'Verificar',
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
