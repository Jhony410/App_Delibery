import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../theme.dart';
import '../widgets.dart';

class RouteToStoreScreen extends StatelessWidget {
  final OrderModel order;
  const RouteToStoreScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dist = order.distanceKm ?? 1.2;
    final eta = (dist * 3.5).round();
    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: DarkMapBackground(withRoute: true)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: _InstructionCard(
                icon: Icons.navigation_rounded,
                iconColor: Colors.white,
                iconBg: CourierColors.primary,
                hint: 'EN 250 m',
                instruction: 'Gira a la derecha en Av. Petit Thouars',
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomSheet(
              title: 'RECOGER EN',
              storeName: order.storeName,
              address: order.storeAddress ?? 'Av. Petit Thouars 2150',
              distance: '${dist.toStringAsFixed(1)} km',
              eta: '$eta min',
              cta: 'Llegué al comercio',
              onPressed: () => Navigator.of(context).pushReplacementNamed(
                '/pickup',
                arguments: order,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String hint;
  final String instruction;
  final VoidCallback onBack;

  const _InstructionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.hint,
    required this.instruction,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 24, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hint,
                        style: const TextStyle(
                          fontSize: 11,
                          color: CourierColors.textMuted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        instruction,
                        style: const TextStyle(
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
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final String title;
  final String storeName;
  final String address;
  final String distance;
  final String eta;
  final String cta;
  final VoidCallback onPressed;

  const _BottomSheet({
    required this.title,
    required this.storeName,
    required this.address,
    required this.distance,
    required this.eta,
    required this.cta,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CourierColors.textMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: CourierColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CourierColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      eta,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: CourierColors.primary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      distance,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CourierColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            CButton(
              label: cta,
              icon: Icons.check_circle_outline,
              size: CButtonSize.xl,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}
