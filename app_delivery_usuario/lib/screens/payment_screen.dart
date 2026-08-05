import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../services/cart_service.dart';
import '../services/checkout_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selected = 0; // 0 = Yape, 1 = Efectivo
  bool _loading = false;
  final _noteCtrl = TextEditingController();

  static const _methods = [
    _PayMethod(
      id: 'yape',
      name: 'Yape',
      asset: 'images/yape.jpg',
      selectedColor: Color(0xFF6E2BB8),
    ),
    _PayMethod(
      id: 'cash',
      name: 'Efectivo',
      asset: 'images/efectivo.jpg',
      selectedColor: AppColors.secondary,
    ),
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmOrder() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final orderId = await CheckoutService.createOrder(
        paymentMethod: _methods[_selected].id,
        observation: _noteCtrl.text.trim().isEmpty
            ? null
            : _noteCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushNamed(context, '/confirmed', arguments: orderId);
      }
    } on CheckoutException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos confirmar el pedido. Tu carrito sigue guardado.',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = CartService.total;

    if (CartService.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Confirmar pedido')),
        body: AppStateView(
          icon: Icons.shopping_bag_outlined,
          title: 'No hay un pedido para confirmar',
          message: 'Agrega productos desde un comercio para continuar.',
          actionLabel: 'Volver al inicio',
          onAction: () =>
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 8),
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Método de pago ─────────────────────────────
                      Text(
                        'Método de pago',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.04,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: List.generate(_methods.length, (i) {
                          final m = _methods[i];
                          final sel = i == _selected;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: i < _methods.length - 1 ? 10 : 0,
                              ),
                              child: GestureDetector(
                                onTap: () => setState(() => _selected = i),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 160),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: sel
                                          ? m.selectedColor
                                          : Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
                                      width: sel ? 2.5 : 1.5,
                                    ),
                                    boxShadow: sel
                                        ? [
                                            BoxShadow(
                                              color: m.selectedColor.withValues(
                                                alpha: 0.18,
                                              ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(14),
                                        ),
                                        child: Image.asset(
                                          m.asset,
                                          height: 110,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            height: 110,
                                            color: Theme.of(
                                              context,
                                            ).scaffoldBackgroundColor,
                                            child: Icon(
                                              Icons.image,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (sel)
                                              Container(
                                                width: 18,
                                                height: 18,
                                                margin: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: m.selectedColor,
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            Text(
                                              m.name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: sel
                                                    ? m.selectedColor
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // ── Observación ────────────────────────────────
                      Text(
                        'Observación',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.04,
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _noteCtrl,
                          maxLines: 4,
                          style: TextStyle(fontSize: 14, height: 1.5),
                          decoration: InputDecoration(
                            hintText:
                                'Ej: Sin cebolla, timbrar en el 3er piso, dejar en la puerta...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.outline,
                              height: 1.5,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.fromLTRB(
                              16,
                              14,
                              16,
                              14,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),

                      SizedBox(height: 16),

                      // ── Resumen de precios ─────────────────────────
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            _PriceRow(
                              'Subtotal',
                              'S/ ${CartService.subtotal.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 8),
                            _PriceRow(
                              'Envío',
                              'S/ ${CartService.deliveryFee.toStringAsFixed(2)}',
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                                height: 1,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total a pagar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'S/ ${total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Botón confirmar ────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                14 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: AppButton(
                label: 'Confirmar pedido',
                onTap: _confirmOrder,
                isLoading: _loading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Icon(Icons.chevron_left, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Confirmar pedido',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _PayMethod {
  final String id;
  final String name;
  final String asset;
  final Color selectedColor;

  const _PayMethod({
    required this.id,
    required this.name,
    required this.asset,
    required this.selectedColor,
  });
}
