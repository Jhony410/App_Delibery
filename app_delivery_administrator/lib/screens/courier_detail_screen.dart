import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/courier_model.dart';
import '../routes.dart';
import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class CourierDetailScreen extends StatelessWidget {
  final CourierModel? courier;
  const CourierDetailScreen({super.key, this.courier});

  @override
  Widget build(BuildContext context) {
    if (courier == null) {
      return AdminShell(
        activeId: 'repartidores',
        title: 'Repartidor',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('Repartidor no encontrado.'),
          ),
        ),
      );
    }
    final c = courier!;
    return AdminShell(
      activeId: 'repartidores',
      title: c.name,
      actions: const [
        AdminButton(
            label: 'Mensaje',
            icon: Icons.message_outlined,
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
        AdminButton(
            label: 'Suspender',
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
        AdminButton(label: 'Liberar pago', size: AdminBtnSize.sm),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Breadcrumb(courier: c),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, sz) {
            final twoCol = sz.maxWidth > 1100;
            final left = Column(
              children: [
                _ProfileCard(courier: c),
                const SizedBox(height: 16),
                _PersonalDataCard(courier: c),
              ],
            );
            final right = Column(
              children: [
                _DocumentsCard(),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, sz2) {
                  final twoCols = sz2.maxWidth > 700;
                  if (!twoCols) {
                    return Column(
                      children: const [
                        _PendingPaymentsCard(),
                        SizedBox(height: 16),
                        _LastDeliveriesCard(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(child: _PendingPaymentsCard()),
                      SizedBox(width: 16),
                      Expanded(child: _LastDeliveriesCard()),
                    ],
                  );
                }),
              ],
            );
            if (!twoCol) {
              return Column(
                  children: [left, const SizedBox(height: 16), right]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 320, child: left),
                const SizedBox(width: 20),
                Expanded(child: right),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final CourierModel courier;
  const _Breadcrumb({required this.courier});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pushReplacementNamed(
              context, AdminRoutes.couriers),
          child: const Text('Repartidores',
              style: TextStyle(
                  fontSize: 12.5, color: AdminColors.textMuted)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right,
              size: 12, color: AdminColors.textMuted),
        ),
        Text(courier.name,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        AdminBadge(courier.statusLabel, tone: courier.statusTone),
        const Spacer(),
        const Text('En línea hace 3h 15m',
            style: TextStyle(
                fontSize: 12.5, color: AdminColors.textMuted)),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final CourierModel courier;
  const _ProfileCard({required this.courier});
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        children: [
          AdminAvatar(name: courier.name, size: 80, tone: 'amber'),
          const SizedBox(height: 12),
          Text(courier.name,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            'ID #${courier.uid.length > 6 ? courier.uid.substring(0, 6) : courier.uid} · Desde ${courier.memberSince.year}',
            style: const TextStyle(
                fontSize: 12, color: AdminColors.textMuted),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border:
                  Border(top: BorderSide(color: AdminColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(courier.rating.toStringAsFixed(1), 'RATING'),
                _stat('${courier.totalDeliveries}', 'ENTREGAS'),
                _stat(
                    '${(courier.acceptanceRate * 100).toStringAsFixed(0)}%',
                    'ACEPTACIÓN'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AdminColors.textMuted,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

class _PersonalDataCard extends StatelessWidget {
  final CourierModel courier;
  const _PersonalDataCard({required this.courier});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('DNI', courier.dni.isEmpty ? '—' : courier.dni),
      ('Teléfono', courier.phone),
      ('Email', courier.email),
      ('Distrito',
          courier.district == null || courier.district!.isEmpty ? '—' : courier.district!),
      ('Vehículo', courier.vehicleModel.isEmpty ? '—' : courier.vehicleModel),
      ('Placa',
          courier.vehiclePlate.isEmpty ? '—' : courier.vehiclePlate),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminEyebrow('DATOS PERSONALES'),
          const SizedBox(height: 6),
          for (final r in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
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
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  static const _docs = [
    ('DNI (anverso)', 'OK', 'Vence 2029'),
    ('DNI (reverso)', 'OK', 'Vence 2029'),
    ('Brevete A-IIa', 'OK', 'Vence ago 2027'),
    ('SOAT', 'OK', 'Vence dic 2025'),
    ('Tarjeta de propiedad', 'OK', '—'),
    ('Antecedentes penales', 'Por vencer', 'Vence 30 may'),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Documentos',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 700 ? 3 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: _docs
                  .map((d) => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: AdminColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: AdminColors.bg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                  Icons.description_outlined,
                                  color: AdminColors.textSubtle),
                            ),
                            const SizedBox(height: 8),
                            Text(d.$1,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(d.$3,
                                style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AdminColors.textMuted)),
                            const Spacer(),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: AdminBadge(
                                  d.$2 == 'OK' ? 'Vigente' : d.$2,
                                  tone:
                                      d.$2 == 'OK' ? 'green' : 'amber'),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _PendingPaymentsCard extends StatelessWidget {
  const _PendingPaymentsCard();
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pagos pendientes',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminColors.amberTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('POR LIBERAR',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AdminColors.amber,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text('S/ 487.30',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                const Text('14 entregas · 28 abr - 4 may',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: AdminColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final r in const [
            ('Sem. 21 abr', 'S/ 524.10'),
            ('Sem. 14 abr', 'S/ 612.40'),
            ('Sem. 7 abr', 'S/ 489.20'),
          ])
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(r.$1,
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: AdminColors.textMuted)),
                  ),
                  Text(r.$2,
                      style: GoogleFonts.robotoMono(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  const AdminBadge('Pagado', tone: 'gray'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LastDeliveriesCard extends StatelessWidget {
  const _LastDeliveriesCard();
  @override
  Widget build(BuildContext context) {
    final rows = const [
      ('#RN-24891', 'En curso', 'green', '7:32 PM'),
      ('#RN-24871', 'Entregado', 'gray', '6:45 PM'),
      ('#RN-24832', 'Entregado', 'gray', '5:58 PM'),
      ('#RN-24798', 'Entregado', 'gray', '5:12 PM'),
      ('#RN-24745', 'Entregado', 'gray', '4:20 PM'),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Últimas entregas',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (int i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(
                        bottom: BorderSide(color: AdminColors.border))
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(rows[i].$1,
                        style: GoogleFonts.robotoMono(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Center(
                      child: AdminBadge(rows[i].$2, tone: rows[i].$3),
                    ),
                  ),
                  Text(rows[i].$4,
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: AdminColors.textMuted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
