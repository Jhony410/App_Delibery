import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/courier_model.dart';
import '../routes.dart';
import '../services/courier_service.dart';
import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class CouriersScreen extends StatelessWidget {
  const CouriersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'repartidores',
      title: 'Repartidores',
      actions: const [
        AdminButton(
            label: 'Exportar',
            icon: Icons.file_download_outlined,
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
        AdminButton(
            label: 'Invitar repartidor',
            icon: Icons.add,
            size: AdminBtnSize.sm),
      ],
      child: StreamBuilder<List<CourierModel>>(
        stream: CourierService.streamAll(),
        builder: (context, snap) {
          final couriers = snap.data ?? const <CourierModel>[];
          final total = couriers.length;
          final inDelivery =
              couriers.where((c) => c.online && c.status == 'active').length;
          final available = couriers.where((c) => c.online).length;
          final offline = couriers.where((c) => !c.online).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Metrics(
                items: [
                  ('Total', '$total', null),
                  ('En entrega', '$inDelivery', AdminColors.primary),
                  ('Disponibles', '$available', AdminColors.green),
                  ('Desconectados', '$offline', AdminColors.textMuted),
                ],
              ),
              const SizedBox(height: 16),
              _Filters(),
              _Table(couriers: couriers),
            ],
          );
        },
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  final List<(String, String, Color?)> items;
  const _Metrics({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 1100 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 4.0,
        children: items
            .map((m) => AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.$1,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AdminColors.textMuted,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(m.$2,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: m.$3 ?? AdminColors.text)),
                    ],
                  ),
                ))
            .toList(),
      );
    });
  }
}

class _Filters extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminCard.flush(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: const [
            Expanded(
              child: AdminFakeField(
                  icon: Icons.search,
                  text: 'Buscar por nombre, placa o teléfono…',
                  width: double.infinity),
            ),
            SizedBox(width: 10),
            AdminFakeField(
                text: 'Estado',
                trailing: Icons.expand_more,
                width: 110),
            SizedBox(width: 10),
            AdminFakeField(
                text: 'Zona',
                trailing: Icons.expand_more,
                width: 110),
          ],
        ),
      ),
    );
  }
}

class _Table extends StatelessWidget {
  final List<CourierModel> couriers;
  const _Table({required this.couriers});
  @override
  Widget build(BuildContext context) {
    return AdminCard.flush(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AdminColors.bg,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            child: Row(
              children: const [
                _Th('Repartidor', flex: 4),
                _Th('Placa', flex: 2),
                _Th('Estado', flex: 2),
                _Th('Pedidos', flex: 2, align: TextAlign.right),
                _Th('Rating', flex: 2, align: TextAlign.right),
                _Th('Documentos', flex: 2),
              ],
            ),
          ),
          if (couriers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Aún no hay repartidores registrados.',
                  style:
                      TextStyle(fontSize: 13, color: AdminColors.textMuted),
                ),
              ),
            )
          else
            for (int i = 0; i < couriers.length; i++)
              _Row(courier: couriers[i], index: i),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final CourierModel courier;
  final int index;
  const _Row({required this.courier, required this.index});

  @override
  Widget build(BuildContext context) {
    const tones = ['coral', 'blue', 'green', 'purple', 'amber'];
    return InkWell(
      onTap: () => Navigator.pushNamed(
          context, AdminRoutes.courierDetail,
          arguments: courier),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: index == 0
              ? null
              : const Border(
                  top: BorderSide(color: AdminColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  AdminAvatar(
                      name: courier.name,
                      size: 32,
                      tone: tones[index % tones.length]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(courier.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        Text(courier.phone,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AdminColors.textMuted),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                courier.vehiclePlate,
                style: GoogleFonts.robotoMono(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AdminBadge(courier.statusLabel,
                    tone: courier.statusTone),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${courier.totalDeliveries}',
                textAlign: TextAlign.right,
                style: GoogleFonts.robotoMono(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.star,
                      size: 13, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(courier.rating.toStringAsFixed(1)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AdminBadge(
                  courier.status == 'pending_review'
                      ? 'Por revisar'
                      : 'Al día',
                  tone: courier.status == 'pending_review'
                      ? 'amber'
                      : 'green',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;
  const _Th(this.label,
      {required this.flex, this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        textAlign: align,
        style: const TextStyle(
            fontSize: 11,
            color: AdminColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6),
      ),
    );
  }
}
