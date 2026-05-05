import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../theme.dart';
import '../widgets.dart';

class RouteToCustomerScreen extends StatelessWidget {
  final OrderModel order;
  const RouteToCustomerScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: DarkMapBackground(withRoute: true)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: CourierColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CourierColors.border),
                      ),
                      child: const Icon(Icons.chevron_left,
                          size: 24, color: CourierColors.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: CourierColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CourierColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: CourierColors.online,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.navigation_rounded,
                              size: 24,
                              color: CourierColors.onOnline,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EN 800 m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: CourierColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Continúa por Av. Arequipa',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: CourierColors.text,
                                  ),
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
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: CourierColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: CourierColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: CourierColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: CourierColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(order.customerName ?? 'Cliente'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: CourierColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName ?? 'Cliente',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: CourierColors.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CourierColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const IconBox(
                          icon: Icons.chat_bubble_outline,
                          background: CourierColors.surface2,
                          color: CourierColors.text,
                        ),
                        const SizedBox(width: 8),
                        const IconBox(
                          icon: Icons.phone_rounded,
                          background: CourierColors.online,
                          color: CourierColors.onOnline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: CourierColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            '3 min · 0.6 km',
                            style: TextStyle(
                              fontSize: 13,
                              color: CourierColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '● A tiempo',
                            style: TextStyle(
                              fontSize: 13,
                              color: CourierColors.online,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    CButton(
                      label: 'Llegué al cliente',
                      icon: Icons.check_circle_outline,
                      size: CButtonSize.xl,
                      variant: CButtonVariant.online,
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed(
                        '/deliver',
                        arguments: order,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
