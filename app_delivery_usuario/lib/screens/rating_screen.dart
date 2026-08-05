import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../services/db_service.dart';
import '../models/order_model.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _storeRating = 5;
  int _driverRating = 4;
  final _commentCtrl = TextEditingController();
  String? _orderId;
  OrderModel? _order;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id != null && id != _orderId) {
      _orderId = id;
      _loadOrder(id);
    }
  }

  Future<void> _loadOrder(String id) async {
    try {
      final order = await DbService.getOrder(id);
      if (mounted) setState(() => _order = order);
    } catch (_) {
      // The rating remains usable with generic labels if this read fails.
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final orderId = _orderId;
    if (orderId != null && orderId.isNotEmpty) {
      setState(() => _submitting = true);
      try {
        await DbService.markOrderRated(
          orderId,
          storeRating: _storeRating,
          courierRating: _driverRating,
          comment: _commentCtrl.text.trim(),
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos guardar tu calificación'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 8),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.close, size: 20),
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
                      Text(
                        '¿Cómo estuvo\ntu pedido?',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.78,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu opinión nos ayuda a mejorar.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 28),
                      // Store card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
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
                            Text(
                              _order?.storeName ?? 'Comercio',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Comida y presentación',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (i) {
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _storeRating = i + 1),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Icon(
                                      i < _storeRating
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      size: 38,
                                      color: i < _storeRating
                                          ? AppColors.star
                                          : Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14),
                      // Driver card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                              ),
                              child: Center(
                                child: Text(
                                  _courierInitials,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _order?.courierName ?? 'Tu repartidor',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tu repartidor',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (i) {
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _driverRating = i + 1),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Icon(
                                      i < _driverRating
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      size: 38,
                                      color: i < _driverRating
                                          ? AppColors.star
                                          : Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
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
                      TextField(
                        controller: _commentCtrl,
                        maxLines: 3,
                        maxLength: 300,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Cuéntanos más (opcional)',
                          alignLabelWithHint: true,
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
                20,
                16,
                20,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              color: Theme.of(context).colorScheme.surface,
              child: AppButton(
                label: 'Enviar calificación',
                onTap: _submit,
                isLoading: _submitting,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _courierInitials {
    final name = _order?.courierName?.trim();
    if (name == null || name.isEmpty) return 'R';
    final words = name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}
