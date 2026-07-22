import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../services/db_service.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _storeRating = 5;
  int _driverRating = 4;

  Future<void> _submit() async {
    // The order id is passed as the route argument (from order_detail_screen).
    // When present we flag the order as rated so it won't be offered again.
    final orderId = ModalRoute.of(context)?.settings.arguments as String?;
    if (orderId != null && orderId.isNotEmpty) {
      try {
        await DbService.markOrderRated(orderId);
      } catch (_) {
        // Non-blocking: still let the user finish even if the write fails.
      }
    }
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¿Cómo estuvo\ntu pedido?',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.78,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tu opinión nos ayuda a mejorar.',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 28),
                      // Store card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            ImgPlaceholder(
                              height: 56,
                              width: 56,
                              tone: 'warm',
                              radius: 14,
                            ),
                            const SizedBox(height: 10),
                            const Text('El Norky\'s',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            const Text('Comida y presentación',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted)),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: List.generate(5, (i) {
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _storeRating = i + 1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Icon(
                                      i < _storeRating
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      size: 38,
                                      color: i < _storeRating
                                          ? AppColors.star
                                          : AppColors.border,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Driver card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: const Color(0xFFFFD0B0),
                              ),
                              child: const Center(
                                child: Text(
                                  'JR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text('Julio Ramírez',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            const Text('Tu repartidor',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted)),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: List.generate(5, (i) {
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _driverRating = i + 1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Icon(
                                      i < _driverRating
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      size: 38,
                                      color: i < _driverRating
                                          ? AppColors.star
                                          : AppColors.border,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Comment
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        constraints: const BoxConstraints(minHeight: 80),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Cuéntanos más (opcional)…',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSubtle),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
              color: Colors.white,
              child: AppButton(
                label: 'Enviar calificación',
                onTap: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
