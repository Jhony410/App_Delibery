import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../routes.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _search = TextEditingController();
  int _filter = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchFilter(OrderModel o) => switch (_filter) {
        1 => o.isActive,
        2 => o.status == 'searching' || o.courierId == null && o.isActive,
        3 => o.status == 'entregado',
        4 => o.status == 'cancelado',
        _ => true,
      };

  bool _matchSearch(OrderModel o) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return o.id.toLowerCase().contains(q) ||
        (o.customerName?.toLowerCase().contains(q) ?? false) ||
        o.storeName.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'pedidos',
      title: 'Pedidos',
      actions: const [
        AdminButton(
            label: 'Filtros',
            icon: Icons.filter_alt_outlined,
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
        AdminButton(
            label: 'Exportar',
            icon: Icons.file_download_outlined,
            size: AdminBtnSize.sm),
      ],
      child: StreamBuilder<List<OrderModel>>(
        stream: OrderService.streamAll(limit: 200),
        builder: (context, snap) {
          final all = snap.data ?? const <OrderModel>[];
          final visible = all
              .where(_matchFilter)
              .where(_matchSearch)
              .toList();
          final counts = {
            'Todos · ${all.length}': 0,
            'Activos · ${all.where((o) => o.isActive).length}': 1,
            'Buscando rep. · ${all.where((o) => o.status == 'searching' || (o.courierId == null && o.isActive)).length}':
                2,
            'Entregados · ${all.where((o) => o.status == 'entregado').length}':
                3,
            'Cancelados · ${all.where((o) => o.status == 'cancelado').length}':
                4,
          };
          return Column(
            children: [
              _SearchBar(controller: _search, onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AdminPillToggle(
                  options: counts.keys.toList(),
                  selectedIndex: _filter,
                  onSelected: (i) => setState(() => _filter = i),
                ),
              ),
              _OrdersTable(orders: visible, total: all.length),
            ],
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar(
      {required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AdminCard.flush(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar por ID, cliente o comercio…',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search,
                        size: 16, color: AdminColors.textMuted),
                    prefixIconConstraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AdminColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AdminColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AdminColors.text, width: 1.4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const AdminFakeField(
                icon: Icons.calendar_today_outlined,
                text: 'Hoy',
                trailing: Icons.expand_more,
                width: 140),
            const SizedBox(width: 10),
            const AdminFakeField(
                text: 'Todas las zonas',
                trailing: Icons.expand_more,
                width: 160),
          ],
        ),
      ),
    );
  }
}

class _OrdersTable extends StatelessWidget {
  final List<OrderModel> orders;
  final int total;
  const _OrdersTable({required this.orders, required this.total});

  @override
  Widget build(BuildContext context) {
    return AdminCard.flush(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AdminColors.bg,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: const [
                _Th('ID', flex: 2),
                _Th('Cliente', flex: 3),
                _Th('Comercio', flex: 3),
                _Th('Repartidor', flex: 3),
                _Th('Estado', flex: 2),
                _Th('Monto', flex: 2, align: TextAlign.right),
                _Th('Hora', flex: 2, align: TextAlign.right),
              ],
            ),
          ),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Sin pedidos que coincidan con el filtro.',
                  style: TextStyle(
                      fontSize: 13, color: AdminColors.textMuted),
                ),
              ),
            )
          else
            for (int i = 0; i < orders.length; i++)
              _OrderRow(order: orders[i], index: i),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AdminColors.border)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Mostrando ${orders.length} de $total pedidos',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AdminColors.textMuted)),
                Row(
                  children: [
                    _PageBtn(child: const Icon(Icons.chevron_left, size: 14)),
                    for (final p in const ['1', '2', '3', '…', '125'])
                      _PageBtn(
                        active: p == '1',
                        child: Text(p,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    _PageBtn(child: const Icon(Icons.chevron_right, size: 14)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;
  final int index;
  const _OrderRow({required this.order, required this.index});

  @override
  Widget build(BuildContext context) {
    const tones = ['coral', 'blue', 'green', 'purple', 'amber'];
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AdminRoutes.orderDetail,
          arguments: order),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: index == 0
              ? null
              : const Border(top: BorderSide(color: AdminColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                order.id.length > 9
                    ? '#${order.id.substring(0, 9)}'
                    : '#${order.id}',
                style: GoogleFonts.robotoMono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
                flex: 3,
                child: Text(order.customerName ?? '—',
                    style: const TextStyle(fontSize: 13))),
            Expanded(
                flex: 3,
                child: Text(order.storeName,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AdminColors.textMuted))),
            Expanded(
              flex: 3,
              child: order.courierId == null
                  ? const Text('Sin asignar',
                      style: TextStyle(
                          color: AdminColors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600))
                  : Row(
                      children: [
                        AdminAvatar(
                          name: order.courierName ?? 'Repartidor',
                          size: 22,
                          tone: tones[index % tones.length],
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            order.courierName ?? 'Repartidor',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AdminBadge(order.statusLabel, tone: order.statusTone),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'S/ ${order.total.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('h:mm a').format(order.createdAt),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12, color: AdminColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final Widget child;
  final bool active;
  const _PageBtn({required this.child, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AdminColors.text : null,
          borderRadius: BorderRadius.circular(6),
          border: active
              ? null
              : Border.all(color: AdminColors.border),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
              color: active ? Colors.white : AdminColors.text),
          child: IconTheme(
              data: IconThemeData(
                  color: active ? Colors.white : AdminColors.text),
              child: child),
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
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
