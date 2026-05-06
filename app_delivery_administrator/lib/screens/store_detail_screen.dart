import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/store_model.dart';
import '../routes.dart';
import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class StoreDetailScreen extends StatelessWidget {
  final StoreModel? store;
  const StoreDetailScreen({super.key, this.store});

  @override
  Widget build(BuildContext context) {
    if (store == null) {
      return AdminShell(
        activeId: 'comercios',
        title: 'Comercio',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('Comercio no encontrado.'),
          ),
        ),
      );
    }
    final s = store!;
    return AdminShell(
      activeId: 'comercios',
      title: s.name,
      actions: [
        AdminButton(
            label: s.isOpen ? 'Pausar' : 'Reactivar',
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm,
            onPressed: () {}),
        const AdminButton(
            label: 'Guardar cambios', size: AdminBtnSize.sm),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Breadcrumb(name: s.name, isOpen: s.isOpen),
          const SizedBox(height: 20),
          _Tabs(),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, c) {
            final twoCol = c.maxWidth > 1100;
            final main = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GeneralInfoCard(store: s),
                const SizedBox(height: 16),
                _HoursCard(),
                const SizedBox(height: 16),
                _SalesBarCard(),
              ],
            );
            final side = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CommissionCard(pct: s.commissionPct ?? 18),
                const SizedBox(height: 16),
                _MonthSummaryCard(),
                const SizedBox(height: 16),
                _ActionsCard(),
              ],
            );
            if (!twoCol) {
              return Column(
                  children: [main, const SizedBox(height: 16), side]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: main),
                const SizedBox(width: 20),
                SizedBox(width: 320, child: side),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final String name;
  final bool isOpen;
  const _Breadcrumb({required this.name, required this.isOpen});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () =>
              Navigator.pushReplacementNamed(context, AdminRoutes.stores),
          child: const Text('Comercios',
              style: TextStyle(
                  fontSize: 12.5, color: AdminColors.textMuted)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right,
              size: 12, color: AdminColors.textMuted),
        ),
        Text(name,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        AdminBadge(isOpen ? 'Activo' : 'Pausado',
            tone: isOpen ? 'green' : 'amber'),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  static const _tabs = [
    'General',
    'Menú',
    'Horarios',
    'Comisión',
    'Ventas',
    'Documentos'
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < _tabs.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: i == 0
                        ? AdminColors.text
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _tabs[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      i == 0 ? AdminColors.text : AdminColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GeneralInfoCard extends StatelessWidget {
  final StoreModel store;
  const _GeneralInfoCard({required this.store});
  @override
  Widget build(BuildContext context) {
    final fields = [
      ('Razón social', store.name),
      ('RUC', '20512345678'),
      ('Categoría', store.category),
      ('Distrito', store.district ?? '—'),
      ('Dirección', store.address),
      ('Teléfono', store.phone ?? '—'),
      ('Email', 'contacto@${store.categorySlug}.pe'),
      ('Contacto', 'Roberto Morales (Gerente)'),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Información general',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: fields.map((f) {
                return SizedBox(
                  width: (c.maxWidth - 14) / 2,
                  child: AdminReadOnlyField(label: f.$1, value: f.$2),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _HoursCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hours = [
      ('Lunes a viernes', '11:00 AM - 11:00 PM'),
      ('Sábado', '11:00 AM - 12:00 AM'),
      ('Domingo', '11:00 AM - 11:00 PM'),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Horarios de atención',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5, fontWeight: FontWeight.w700)),
              const AdminButton(
                  label: 'Editar',
                  icon: Icons.edit,
                  variant: AdminBtnVariant.ghost,
                  size: AdminBtnSize.sm),
            ],
          ),
          const SizedBox(height: 6),
          for (final h in hours)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(h.$1,
                      style: const TextStyle(
                          fontSize: 13, color: AdminColors.textMuted)),
                  Text(h.$2,
                      style: GoogleFonts.robotoMono(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SalesBarCard extends StatelessWidget {
  static const _bars = [
    12, 18, 24, 14, 22, 30, 28, 34, 40, 32, 28, 36, 42, 38,
    30, 26, 32, 44, 50, 46, 38, 42, 48, 52, 60, 56, 44, 50,
    58, 64
  ];
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ventas últimos 30 días',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5, fontWeight: FontWeight.w700)),
              Text('S/ 12,480',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 100,
            child: LayoutBuilder(builder: (context, c) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_bars.length, (i) {
                  final maxBar = _bars.reduce((a, b) => a > b ? a : b);
                  final h = (_bars[i] / maxBar) * 90;
                  return Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(
                        height: h,
                        decoration: BoxDecoration(
                          color: i == _bars.length - 1
                              ? AdminColors.primary
                              : AdminColors.primary
                                  .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CommissionCard extends StatelessWidget {
  final double pct;
  const _CommissionCard({required this.pct});
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminEyebrow('COMISIÓN'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${pct.toStringAsFixed(0)}%',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 32, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              const Text('por pedido',
                  style: TextStyle(
                      fontSize: 12, color: AdminColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AdminColors.bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Acuerdo vigente desde 15 mar 2024',
              style: TextStyle(
                  fontSize: 11.5, color: AdminColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          const AdminButton(
            label: 'Modificar comisión',
            icon: Icons.edit,
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm,
          ),
        ],
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Pedidos', '892'),
      ('Ventas brutas', 'S/ 12,480'),
      ('Comisión Runa', 'S/ 2,246'),
      ('A pagar al comercio', 'S/ 10,234'),
      ('Cancelaciones', '14 (1.6%)'),
      ('Rating prom.', '4.8 ★'),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Resumen del mes',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final r in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.$1,
                      style: const TextStyle(
                          fontSize: 12.5, color: AdminColors.textMuted)),
                  Text(r.$2,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Acciones',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const AdminButton(
              label: 'Ver pedidos',
              icon: Icons.visibility_outlined,
              variant: AdminBtnVariant.secondary,
              size: AdminBtnSize.sm),
          const SizedBox(height: 8),
          const AdminButton(
              label: 'Contactar comercio',
              icon: Icons.message_outlined,
              variant: AdminBtnVariant.secondary,
              size: AdminBtnSize.sm),
          const SizedBox(height: 8),
          const AdminButton(
              label: 'Pausar operación',
              variant: AdminBtnVariant.danger,
              size: AdminBtnSize.sm),
        ],
      ),
    );
  }
}
