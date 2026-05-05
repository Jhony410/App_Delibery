import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../models/order_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';

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
    final uid = AuthService.currentUid;
    if (uid == null || CartService.items.isEmpty) return;
    setState(() => _loading = true);
    try {
      final order = OrderModel(
        id: '',
        userId: uid,
        storeId: CartService.storeId ?? '',
        storeName: CartService.storeName ?? '',
        storeTone: CartService.storeTone ?? 'warm',
        items: CartService.toOrderItems(),
        subtotal: CartService.subtotal,
        deliveryFee: CartService.deliveryFee,
        total: CartService.total,
        status: 'confirmed',
        address: CartService.selectedAddress,
        paymentMethod: _methods[_selected].id,
        observation: _noteCtrl.text.trim().isEmpty
            ? null
            : _noteCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      final orderId = await DbService.createOrder(order);
      CartService.clear();
      _runSimulation(orderId);
      if (mounted) {
        Navigator.pushNamed(context, '/confirmed', arguments: orderId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al confirmar el pedido'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _runSimulation(String orderId) {
    Future(() async {
      await Future.delayed(const Duration(seconds: 6));
      await DbService.updateOrderStatus(orderId, 'preparing');
      await Future.delayed(const Duration(seconds: 10));
      await DbService.updateOrderStatus(orderId, 'en_camino');
      await Future.delayed(const Duration(seconds: 14));
      await DbService.updateOrderStatus(orderId, 'entregado');
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = CartService.total;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 8),
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Método de pago ─────────────────────────────
                      const Text('Método de pago',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.04)),
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
                                  duration: const Duration(milliseconds: 160),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: sel
                                          ? m.selectedColor
                                          : AppColors.border,
                                      width: sel ? 2.5 : 1.5,
                                    ),
                                    boxShadow: sel
                                        ? [
                                            BoxShadow(
                                              color: m.selectedColor
                                                  .withValues(alpha: 0.18),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(14)),
                                        child: Image.asset(
                                          m.asset,
                                          height: 110,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                height: 110,
                                                color: AppColors.bg,
                                                child: Icon(Icons.image,
                                                    color: AppColors.textMuted,
                                                    size: 40),
                                              ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (sel)
                                              Container(
                                                width: 18,
                                                height: 18,
                                                margin: const EdgeInsets.only(
                                                    right: 6),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: m.selectedColor,
                                                ),
                                                child: const Icon(Icons.check,
                                                    size: 12,
                                                    color: Colors.white),
                                              ),
                                            Text(
                                              m.name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: sel
                                                    ? m.selectedColor
                                                    : AppColors.appText,
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
                      const Text('Observación',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.04)),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: TextField(
                          controller: _noteCtrl,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                          decoration: InputDecoration(
                            hintText:
                                'Ej: Sin cebolla, timbrar en el 3er piso, dejar en la puerta...',
                            hintStyle: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSubtle,
                                height: 1.5),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Resumen de precios ─────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _PriceRow('Subtotal',
                                'S/ ${CartService.subtotal.toStringAsFixed(2)}'),
                            const SizedBox(height: 8),
                            _PriceRow('Envío',
                                'S/ ${CartService.deliveryFee.toStringAsFixed(2)}'),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child:
                                  Divider(color: AppColors.border, height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total a pagar',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                Text(
                                  'S/ ${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary),
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
                  20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : AppButton(
                      label: 'Confirmar pedido',
                      onTap: _confirmOrder,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.chevron_left, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Confirmar pedido',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600)),
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
