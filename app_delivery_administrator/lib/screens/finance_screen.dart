import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/finance_service.dart';
import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'finanzas',
      title: 'Reportes financieros',
      actions: const [
        AdminFakeField(
            icon: Icons.calendar_today_outlined,
            text: '1 abr - 30 abr 2026',
            trailing: Icons.expand_more,
            width: 220),
        SizedBox(width: 10),
        AdminButton(
            label: 'Exportar Excel',
            icon: Icons.file_download_outlined,
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
      ],
      child: FutureBuilder<FinanceSummary>(
        future: FinanceService.summary(),
        builder: (context, snap) {
          final s = snap.data;
          final gross = s?.gross ?? 0;
          final commission = s?.commission ?? 0;
          final payable = s?.payable ?? 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Metrics(items: [
                ('Ventas brutas', 'S/ ${gross.toStringAsFixed(0)}',
                    '+12.4%', AdminColors.green),
                ('Comisión Runa',
                    'S/ ${commission.toStringAsFixed(0)}',
                    '+10.8%', AdminColors.primary),
                ('A pagar a comercios',
                    'S/ ${payable.toStringAsFixed(0)}',
                    '—', AdminColors.text),
                ('Pagos pendientes', 'S/ 38,920',
                    '128 transac.', AdminColors.amber),
              ]),
              const SizedBox(height: 16),
              const _SalesBarChart(),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, c) {
                final twoCol = c.maxWidth > 1100;
                if (!twoCol) {
                  return Column(children: const [
                    _CommissionByCategory(),
                    SizedBox(height: 16),
                    _TopStores(),
                  ]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(child: _CommissionByCategory()),
                    SizedBox(width: 16),
                    Expanded(child: _TopStores()),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  final List<(String, String, String, Color)> items;
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
        childAspectRatio: 3.4,
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(m.$2,
                            maxLines: 1,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: m.$4)),
                      ),
                      const SizedBox(height: 2),
                      Text(m.$3,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AdminColors.textMuted,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ))
            .toList(),
      );
    });
  }
}

class _SalesBarChart extends StatelessWidget {
  const _SalesBarChart();
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('Ventas y comisión por día',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Row(
                children: const [
                  _LegendDot(
                      color: AdminColors.primary, label: 'Ventas'),
                  SizedBox(width: 14),
                  _LegendDot(
                      color: AdminColors.green, label: 'Comisión'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: CustomPaint(
                painter: _BarChartPainter(),
                child: const SizedBox.expand()),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final pad = 40.0;
    final usableW = w - pad - 10;
    final n = 30;
    final groupW = usableW / n;
    final maxVal = 200.0;

    final grid = Paint()..color = AdminColors.border;
    for (int i = 0; i < 4; i++) {
      final y = i * (h / 4) + 10;
      canvas.drawLine(Offset(pad, y), Offset(w, y), grid);
    }

    final salesPaint = Paint()..color = AdminColors.primary;
    final commPaint = Paint()..color = AdminColors.green;
    for (int i = 0; i < n; i++) {
      final v = 60 + math.sin(i * 0.5) * 30 + math.cos(i * 0.3) * 25 + i * 1.5;
      final c = v * 0.17;
      final x = pad + i * groupW;
      final salesH = (v / maxVal) * (h - 20);
      final commH = (c / maxVal) * (h - 20);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
                x, h - salesH - 10, groupW * 0.35, salesH),
            const Radius.circular(2),
          ),
          salesPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + groupW * 0.45, h - commH - 10,
                groupW * 0.35, commH),
            const Radius.circular(2),
          ),
          commPaint);
    }

    // Y labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < 5; i++) {
      final v = 200 - i * 50;
      tp.text = TextSpan(
        text: 'S/${v}k',
        style: const TextStyle(
            color: AdminColors.textMuted, fontSize: 10),
      );
      tp.layout();
      tp.paint(canvas, Offset(0, i * (h / 4) + 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CommissionByCategory extends StatelessWidget {
  const _CommissionByCategory();
  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Comida', 0.54, 'S/ 49,367', AdminColors.primary),
      ('Supermercado', 0.28, 'S/ 25,597', AdminColors.blue),
      ('Farmacia', 0.14, 'S/ 12,798', AdminColors.green),
      ('Otros', 0.04, 'S/ 3,658', AdminColors.purple),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Comisión por categoría',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.$1,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                      Flexible(
                        child: Text(
                            '${r.$3} · ${(r.$2 * 100).toStringAsFixed(0)}%',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AdminColors.textMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AdminColors.bg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: r.$2,
                      child: Container(
                        decoration: BoxDecoration(
                            color: r.$4,
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TopStores extends StatelessWidget {
  const _TopStores();
  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Plaza Vea Cerca', 'Supermercado', 'S/ 38,540'),
      ('Tanta Larcomar', 'Restaurante', 'S/ 22,180'),
      ('La Botica Express', 'Farmacia', 'S/ 14,210'),
      ('El Norky\'s', 'Pollería', 'S/ 12,480'),
      ('Inkafarma Pardo', 'Farmacia', 'S/ 11,360'),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Top comercios del mes',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (int i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(
                        top: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AdminColors.textMuted)),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(rows[i].$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(rows[i].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AdminColors.textMuted)),
                  ),
                  Text(rows[i].$3,
                      style: GoogleFonts.robotoMono(
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
