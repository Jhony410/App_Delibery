import 'package:flutter/material.dart';
import '../models/courier_model.dart';
import '../services/auth_service.dart';
import '../services/courier_service.dart';
import '../theme.dart';
import '../widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUid;
    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CTopBar(title: 'Perfil', back: false),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: uid == null
                    ? const Text('No has iniciado sesión.')
                    : StreamBuilder<CourierModel?>(
                        stream: CourierService.streamCourier(uid),
                        builder: (_, snap) {
                          final c = snap.data;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _UserCard(courier: c),
                              const SizedBox(height: 14),
                              _ItemList(courier: c),
                              const SizedBox(height: 14),
                              const Center(
                                child: Text(
                                  'DELY REPARTIDOR · v1.0.0',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: CourierColors.textSubtle,
                                    fontFamily: 'monospace',
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final CourierModel? courier;
  const _UserCard({required this.courier});

  @override
  Widget build(BuildContext context) {
    final c = courier;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CourierColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CourierColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: CourierColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  c?.initials ?? 'R',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c?.name ?? 'Repartidor',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: CourierColors.text,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Repartidor desde ${_formatMonth(c?.memberSince)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CourierColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (c?.isVerified ?? false)
                            ? CourierColors.onlineTint
                            : CourierColors.surface2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (c?.isVerified ?? false)
                                ? Icons.check_rounded
                                : Icons.access_time_rounded,
                            size: 12,
                            color: (c?.isVerified ?? false)
                                ? CourierColors.online
                                : CourierColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (c?.isVerified ?? false)
                                ? 'CUENTA VERIFICADA'
                                : 'EN REVISIÓN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: (c?.isVerified ?? false)
                                  ? CourierColors.online
                                  : CourierColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: CourierColors.border, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: (c?.rating ?? 5.0).toStringAsFixed(1),
                  label: 'Calificación',
                  iconLeading: const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: CourierColors.warning,
                  ),
                ),
              ),
              const SizedBox(
                height: 36,
                child: VerticalDivider(
                  color: CourierColors.border,
                  thickness: 1,
                  width: 1,
                ),
              ),
              Expanded(
                child: _Stat(
                  value: (c?.totalDeliveries ?? 0).toString(),
                  label: 'Entregas',
                ),
              ),
              const SizedBox(
                height: 36,
                child: VerticalDivider(
                  color: CourierColors.border,
                  thickness: 1,
                  width: 1,
                ),
              ),
              Expanded(
                child: _Stat(
                  value:
                      '${((c?.acceptanceRate ?? 1.0) * 100).round()}%',
                  label: 'Aceptación',
                  valueColor: CourierColors.online,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMonth(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  final Widget? iconLeading;

  const _Stat({
    required this.value,
    required this.label,
    this.valueColor,
    this.iconLeading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconLeading != null) ...[iconLeading!, const SizedBox(width: 4)],
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: valueColor ?? CourierColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: CourierColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ItemList extends StatelessWidget {
  final CourierModel? courier;
  const _ItemList({required this.courier});

  @override
  Widget build(BuildContext context) {
    final items = <_ProfileItem>[
      _ProfileItem(
        icon: Icons.person_outline_rounded,
        label: 'Datos personales',
        desc: 'DNI, contacto, dirección',
        onTap: () {},
      ),
      _ProfileItem(
        icon: Icons.description_outlined,
        label: 'Documentos',
        desc: 'Licencia, SOAT · Vigentes',
        tag: 'OK',
        tagColor: CourierColors.online,
        onTap: () {},
      ),
      _ProfileItem(
        icon: Icons.two_wheeler_outlined,
        label: 'Mi vehículo',
        desc: courier?.vehicleModel.isNotEmpty ?? false
            ? '${courier!.vehicleModel} · ${courier!.vehiclePlate}'
            : 'Sin registrar',
        onTap: () {},
      ),
      _ProfileItem(
        icon: Icons.credit_card_outlined,
        label: 'Cuenta bancaria',
        desc: courier?.bankAccount.isNotEmpty ?? false
            ? courier!.bankAccount
            : 'Sin registrar',
        onTap: () {},
      ),
      _ProfileItem(
        icon: Icons.help_outline_rounded,
        label: 'Ayuda y soporte',
        onTap: () {},
      ),
      _ProfileItem(
        icon: Icons.shield_outlined,
        label: 'Seguridad y privacidad',
        onTap: () {},
      ),
      _ProfileItem(
        icon: Icons.logout_rounded,
        label: 'Cerrar sesión',
        danger: true,
        onTap: () async {
          await AuthService.signOut();
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (_) => false,
            );
          }
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: CourierColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CourierColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.asMap().entries.map((e) {
          final last = e.key == items.length - 1;
          final it = e.value;
          return InkWell(
            onTap: it.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: last
                        ? Colors.transparent
                        : CourierColors.borderSoft,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconBox(
                    icon: it.icon,
                    background: it.danger
                        ? CourierColors.dangerTint
                        : CourierColors.surface2,
                    color: it.danger
                        ? CourierColors.danger
                        : CourierColors.text,
                    size: 38,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: it.danger
                                ? CourierColors.danger
                                : CourierColors.text,
                          ),
                        ),
                        if (it.desc != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            it.desc!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: CourierColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (it.tag != null)
                    StatusPill(
                        text: it.tag!,
                        color: it.tagColor ?? CourierColors.online),
                  if (!it.danger)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: CourierColors.textSubtle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileItem {
  final IconData icon;
  final String label;
  final String? desc;
  final String? tag;
  final Color? tagColor;
  final bool danger;
  final VoidCallback onTap;

  _ProfileItem({
    required this.icon,
    required this.label,
    this.desc,
    this.tag,
    this.tagColor,
    this.danger = false,
    required this.onTap,
  });
}
