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
                  ('Total', '${customers.length}', '+412 mes'),
                  ('Activos', '$activeCount',
                      customers.isEmpty
                          ? '—'
                          : '${(activeCount / customers.length * 100).toStringAsFixed(1)}%'),
                  ('VIP', '$vipCount', 'Top 5%'),
                  ('Ticket prom.',
                      'S/ ${avgTicket.toStringAsFixed(2)}', '+S/ 2.10'),
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

class _MetricsRow extends StatelessWidget {
  final List<(String, String, String)> items;
  const _MetricsRow({required this.items});
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
        childAspectRatio: 3.6,
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
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(m.$3,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AdminColors.green,
                              fontWeight: FontWeight.w600)),
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
      child: Text(label.toUpperCase(),
          textAlign: align,
          style: const TextStyle(
              fontSize: 11,
              color: AdminColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6)),
    );
  }
}
