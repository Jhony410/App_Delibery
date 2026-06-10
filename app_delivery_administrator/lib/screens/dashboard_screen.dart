import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../routes.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'dashboard',
      title: 'Dashboard',
      actions: [
        AdminButton(
          label: 'Actualizar',
          icon: Icons.refresh,
          variant: AdminBtnVariant.secondary,
          size: AdminBtnSize.sm,
          onPressed: () {},
        ),
        const AdminButton(
          label: 'Exportar',
          icon: Icons.file_download_outlined,
          size: AdminBtnSize.sm,
        ),
      ],
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.streamAll(limit: 50),
      builder: (context, snap) {
        final orders = snap.data ?? const <OrderModel>[];
        final today = _ordersToday(orders);
        final salesToday = today.fold<double>(0, (a, b) => a + b.total);
        final activeCouriers =
            orders.where((o) => o.isActive && o.courierId != null).length;
        final activeStores =
            orders.map((o) => o.storeId).toSet().length;
        final metrics = [
          _Metric('Pedidos hoy', '${today.length}',
              today.isEmpty ? '+0%' : '+12.4%', 'green', Icons.inventory_2_outlined),
          _Metric('Ventas del día', _money(salesToday), '+8.2%',
              'green', Icons.account_balance_wallet_outlined),
          _Metric('Repartidores activos', '$activeCouriers', '/ 320',
              'gray', Icons.two_wheeler_outlined),
          _Metric('Comercios activos', '$activeStores', '+3 hoy',
              'blue', Icons.storefront_outlined),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricGrid(metrics: metrics),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final twoCol = c.maxWidth > 1100;
              if (twoCol) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: const _SalesChart()),
                    const SizedBox(width: 16),
                    const Expanded(flex: 1, child: _AlertsCard()),
                  ],
                );
              }
              return Column(
                children: const [
                  _SalesChart(),
                  SizedBox(height: 16),
                  _AlertsCard(),
                ],
              );
            }),
            const SizedBox(height: 16),
            _RecentOrdersTable(orders: orders.take(8).toList()),
          ],
        );
      },
    );
  }

  List<OrderModel> _ordersToday(List<OrderModel> all) {
    final now = DateTime.now();
    return all
        .where((o) =>
            o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day)
        .toList();
  }

  String _money(double v) =>
      'S/ ${NumberFormat('#,##0.00').format(v)}';
}

class _Metric {
  final String label;
  final String value;
  final String delta;
  final String tone;
  final IconData icon;
  const _Metric(this.label, this.value, this.delta, this.tone, this.icon);
}

class _MetricGrid extends StatelessWidget {
  final List<_Metric> metrics;
  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 1100
          ? 4
          : c.maxWidth > 800
              ? 2
              : 1;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.4,
        children: metrics
            .map((m) => AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AdminColors.bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(m.icon, size: 18),
                          ),
                          AdminBadge(m.delta, tone: m.tone),
                        ],
                      ),
                      const Spacer(),
                      Text(m.label,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AdminColors.textMuted,
                              fontWeight: FontWeight.w500)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(m.value,
                            maxLines: 1,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );
    });
  }
}

class _SalesChart extends StatelessWidget {
  const _SalesChart();

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ventas de la semana',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    const Text('Últimos 7 días · S/ 287,420 total',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: AdminColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const AdminPillToggle(
                  options: ['7d', '30d', '90d'], selectedIndex: 0),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _SalesChartPainter(),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb']
                  .map((d) => Text(d,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AdminColors.textMuted)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesChartPainter extends CustomPainter {
  static const _values = [130.0, 110, 90, 100, 70, 50, 65, 30];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gridlines
    final grid = Paint()
      ..color = AdminColors.border
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final y = i * (h / 4) + 10;
      _drawDashedLine(canvas, Offset(0, y), Offset(w, y), grid);
    }

    // Map values to points
    final points = <Offset>[];
    final n = _values.length;
    for (int i = 0; i < n; i++) {
      final x = (i / (n - 1)) * w;
      final y = (_values[i] / 180) * h;
      points.add(Offset(x, y));
    }

    // Filled area
    final areaPath = Path();
    areaPath.moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(w, h);
    areaPath.lineTo(0, h);
    areaPath.close();
    final gradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AdminColors.primary.withValues(alpha: 0.25),
          AdminColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(areaPath, gradient);

    // Line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AdminColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Points
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (i == points.length - 1) {
        canvas.drawCircle(p, 11,
            Paint()..color = AdminColors.primary.withValues(alpha: 0.2));
        canvas.drawCircle(p, 6, Paint()..color = AdminColors.primary);
      } else {
        canvas.drawCircle(p, 3.5, Paint()..color = Colors.white);
        canvas.drawCircle(
            p,
            3.5,
            Paint()
              ..color = AdminColors.primary
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }
  }

  void _drawDashedLine(
      Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 2.0;
    const gap = 4.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    double pos = 0;
    while (pos < total) {
      final start = a + dir * pos;
      final end = a + dir * (pos + dash).clamp(0, total);
      canvas.drawLine(start, end, paint);
      pos += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard();

  @override
  Widget build(BuildContext context) {
    final alerts = [
      ('red', Icons.inventory_2_outlined, '3 pedidos sin asignar',
          'Zona Surco · más de 5 min esperando'),
      ('amber', Icons.verified_outlined, '8 repartidores pendientes',
          'Documentación lista para revisar'),
      ('blue', Icons.storefront_outlined,
          'Nuevo comercio solicitando alta',
          'Anticuchería La Esquina · Barranco'),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alertas',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const AdminBadge('3 nuevas', tone: 'red'),
            ],
          ),
          const SizedBox(height: 14),
          for (final a in alerts) ...[
            _AlertTile(
                tone: a.$1, icon: a.$2, title: a.$3, desc: a.$4),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final String tone;
  final IconData icon;
  final String title;
  final String desc;
  const _AlertTile(
      {required this.tone,
      required this.icon,
      required this.title,
      required this.desc});

  Color get _tint => switch (tone) {
        'red' => AdminColors.redTint,
        'amber' => AdminColors.amberTint,
        'blue' => AdminColors.blueTint,
        _ => AdminColors.grayTint,
      };
  Color get _fg => switch (tone) {
        'red' => AdminColors.red,
        'amber' => AdminColors.amber,
        'blue' => AdminColors.blue,
        _ => AdminColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          border: Border.all(color: AdminColors.border),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: _tint, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: _fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 11, color: AdminColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersTable extends StatelessWidget {
  final List<OrderModel> orders;
  const _RecentOrdersTable({required this.orders});

  @override
  Widget build(BuildContext context) {
    return AdminCard.flush(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: AdminColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Últimos pedidos',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                InkWell(
                  onTap: () => Navigator.pushNamed(
                      context, AdminRoutes.orders),
                  child: const Text('Ver todos →',
                      style: TextStyle(
                          fontSize: 12,
                          color: AdminColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Aún no hay pedidos en el sistema.',
                  style:
                      TextStyle(fontSize: 13, color: AdminColors.textMuted),
                ),
              ),
            )
          else
            _OrderRowsTable(orders: orders),
        ],
      ),
    );
  }
}

class _OrderRowsTable extends StatelessWidget {
  final List<OrderModel> orders;
  const _OrderRowsTable({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AdminColors.bg,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const _Th('ID', flex: 2),
              const _Th('Cliente', flex: 3),
              const _Th('Comercio', flex: 3),
              const _Th('Estado', flex: 2),
              const _Th('Monto', flex: 2, align: TextAlign.right),
              const _Th('Hora', flex: 2, align: TextAlign.right),
            ],
          ),
        ),
        for (int i = 0; i < orders.length; i++)
          InkWell(
            onTap: () => Navigator.pushNamed(
                context, AdminRoutes.orderDetail,
                arguments: orders[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(
                        top: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                children: [
                  _Td(orders[i].id.length > 8
                      ? '#${orders[i].id.substring(0, 8)}'
                      : '#${orders[i].id}',
                      flex: 2, mono: true, bold: true),
                  _Td(orders[i].customerName ?? '—', flex: 3),
                  _Td(orders[i].storeName, flex: 3, muted: true),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AdminBadge(orders[i].statusLabel,
                          tone: orders[i].statusTone),
                    ),
                  ),
                  _Td(
                      'S/ ${orders[i].total.toStringAsFixed(2)}',
                      flex: 2,
                      bold: true,
                      align: TextAlign.right),
                  _Td(
                    DateFormat('h:mm a').format(orders[i].createdAt),
                    flex: 2,
                    muted: true,
                    align: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),
      ],
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

class _Td extends StatelessWidget {
  final String text;
  final int flex;
  final bool mono;
  final bool bold;
  final bool muted;
  final TextAlign align;
  const _Td(this.text,
      {required this.flex,
      this.mono = false,
      this.bold = false,
      this.muted = false,
      this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      fontFamily: mono ? 'RobotoMono' : null,
      color: muted ? AdminColors.textMuted : AdminColors.text,
    );
    return Expanded(
      flex: flex,
      child: Text(text,
          style: mono ? GoogleFonts.robotoMono(textStyle: style) : style,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }
}
