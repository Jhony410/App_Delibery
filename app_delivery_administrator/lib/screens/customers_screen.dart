import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'clientes',
      title: 'Clientes',
      actions: const [
        AdminButton(
            label: 'Exportar CSV',
            icon: Icons.file_download_outlined,
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
      ],
      child: StreamBuilder<List<CustomerModel>>(
        stream: CustomerService.streamAll(limit: 200),
        builder: (context, snap) {
          if (snap.hasError) {
            debugPrint('CustomersScreen stream error: ${snap.error}');
            return AdminErrorState(message: '${snap.error}');
          }
          final customers = snap.data ?? const <CustomerModel>[];
          final activeCount =
              customers.where((c) => c.totalOrders > 0).length;
          final vipCount =
              customers.where((c) => c.segment == 'VIP').length;
          final avgTicket = customers.isEmpty
              ? 0.0
              : customers.fold<double>(0, (s, c) => s + c.totalSpent) /
                  customers
                      .map((c) => c.totalOrders)
                      .where((o) => o > 0)
                      .fold<int>(1, (s, o) => s + o);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MetricsRow(
                items: [
                  ('Total', '${customers.length}', null),
                  ('Activos', '$activeCount', AdminColors.green),
                  ('VIP', '$vipCount', AdminColors.purple),
                  ('Ticket prom.',
                      'S/ ${avgTicket.toStringAsFixed(2)}', null),
                ],
              ),
              const SizedBox(height: 16),
              _Filters(),
              _CustomersTable(customers: customers),
            ],
          );
        },
      ),
    );
  }
}

/// Metric cards — content-sized Row/Expanded layout (never a fixed
/// aspect-ratio GridView, which was the source of the bottom overflow).
class _MetricsRow extends StatelessWidget {
  final List<(String, String, Color?)> items;
  const _MetricsRow({required this.items});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 1100 ? 4 : 2;
      return Column(
        children: [
          for (var i = 0; i < items.length; i += cols) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = i; j < i + cols; j++) ...[
                  if (j > i) const SizedBox(width: 16),
                  Expanded(
                    child: j < items.length
                        ? _MetricCard(item: items[j])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    });
  }
}

class _MetricCard extends StatelessWidget {
  final (String, String, Color?) item;
  const _MetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.$1,
              style: const TextStyle(
                  fontSize: 12,
                  color: AdminColors.textMuted,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(item.$2,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: item.$3 ?? AdminColors.text)),
        ],
      ),
    );
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
                  text: 'Buscar por nombre o teléfono…',
                  width: double.infinity),
            ),
            SizedBox(width: 10),
            AdminFakeField(
                text: 'Segmento',
                trailing: Icons.expand_more,
                width: 130),
          ],
        ),
      ),
    );
  }
}

class _CustomersTable extends StatelessWidget {
  final List<CustomerModel> customers;
  const _CustomersTable({required this.customers});
  @override
  Widget build(BuildContext context) {
    return AdminCard.flush(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AdminColors.bg,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: const [
                _Th('Cliente', flex: 4),
                _Th('Distrito', flex: 3),
                _Th('Pedidos', flex: 2, align: TextAlign.right),
                _Th('Gasto total', flex: 2, align: TextAlign.right),
                _Th('Rating', flex: 2, align: TextAlign.right),
                _Th('Segmento', flex: 2),
              ],
            ),
          ),
          if (customers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text('Aún no hay clientes registrados.',
                    style: TextStyle(
                        fontSize: 13, color: AdminColors.textMuted)),
              ),
            )
          else
            for (int i = 0; i < customers.length; i++)
              _CustomerRow(customer: customers[i], index: i),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final CustomerModel customer;
  final int index;
  const _CustomerRow({required this.customer, required this.index});

  @override
  Widget build(BuildContext context) {
    const tones = ['coral', 'blue', 'green', 'purple', 'amber'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: index == 0
            ? null
            : const Border(top: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                AdminAvatar(
                    name: customer.name,
                    size: 32,
                    tone: tones[index % tones.length]),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(customer.phone,
                          style: GoogleFonts.robotoMono(
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
            flex: 3,
            child: Text(customer.district ?? '—',
                style: const TextStyle(
                    fontSize: 13, color: AdminColors.textMuted)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${customer.totalOrders}',
              textAlign: TextAlign.right,
              style: GoogleFonts.robotoMono(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'S/ ${customer.totalSpent.toStringAsFixed(2)}',
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
                Text(customer.rating.toStringAsFixed(1)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AdminBadge(customer.segment,
                  tone: customer.segmentTone),
            ),
          ),
        ],
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
      // Horizontal padding keeps adjacent uppercase labels from touching when a
      // right-aligned column is followed by a left-aligned one (e.g. RATING /
      // SEGMENTO).
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(label.toUpperCase(),
            textAlign: align,
            style: const TextStyle(
                fontSize: 11,
                color: AdminColors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6)),
      ),
    );
  }
}
