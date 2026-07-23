import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});
  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  int _filter = 0;
  static const _filters = [
    'Todas',
    'Activas',
    'Programadas',
    'Vencidas',
    'Borrador'
  ];
  static const _promos = [
    ('NUEVOS50', 'Descuento bienvenida', '50% hasta S/ 15', 'Activa', 'green', 8420, 12000, '70.2%'),
    ('ENVIO0', 'Envío gratis fin de semana', '100% en envío', 'Activa', 'green', 4180, null, '—'),
    ('LUNES20', 'Lunes 20% en comida', '20%', 'Activa', 'green', 2910, 5000, '58.2%'),
    ('INKAPLATAFORMA', 'Inca Kola 2x1', '2x1', 'Programada', 'blue', 0, 3000, '0%'),
    ('MAMA2025', 'Día de la madre', '30% hasta S/ 30', 'Programada', 'blue', 0, 2000, '0%'),
    ('VERANO15', 'Verano helados', '15%', 'Vencida', 'gray', 5820, 6000, '97.0%'),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'config',
      title: 'Promociones y cupones',
      actions: const [
        AdminButton(
            label: 'Ver reglas',
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
        AdminButton(
            label: 'Crear promoción',
            icon: Icons.add,
            size: AdminBtnSize.sm),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Metrics(
            items: [
              ('Activas', '14', AdminColors.green),
              ('Programadas', '6', AdminColors.blue),
              ('Usos este mes', '21,330', AdminColors.text),
              ('Descuento entregado',
                  'S/ 84,210', AdminColors.primary),
            ],
          ),
          const SizedBox(height: 16),
          AdminCard.flush(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: AdminPillToggle(
                    options: _filters,
                    selectedIndex: _filter,
                    onSelected: (i) => setState(() => _filter = i),
                  ),
                ),
                _PromosTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Metric cards — content-sized Row/Expanded layout (never a fixed
/// aspect-ratio GridView, which caused bottom overflow on narrow widths).
class _Metrics extends StatelessWidget {
  final List<(String, String, Color)> items;
  const _Metrics({required this.items});
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
  final (String, String, Color) item;
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
                  color: item.$3)),
        ],
      ),
    );
  }
}

class _PromosTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AdminColors.bg,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: const [
              _Th('Código', flex: 3),
              _Th('Descripción', flex: 4),
              _Th('Beneficio', flex: 3),
              _Th('Estado', flex: 2),
              _Th('Usos', flex: 2, align: TextAlign.right),
              _Th('Cupo', flex: 2, align: TextAlign.right),
            ],
          ),
        ),
        for (int i = 0; i < _PromotionsScreenState._promos.length; i++)
          _PromoRow(
              row: _PromotionsScreenState._promos[i], index: i),
      ],
    );
  }
}

class _PromoRow extends StatelessWidget {
  final (String, String, String, String, String, int, int?, String) row;
  final int index;
  const _PromoRow({required this.row, required this.index});

  @override
  Widget build(BuildContext context) {
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
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AdminColors.bg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(row.$1,
                  style: GoogleFonts.robotoMono(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(row.$2,
                  style:
                      const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(row.$3,
                style: const TextStyle(
                    color: AdminColors.primary,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AdminBadge(row.$4, tone: row.$5),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${row.$6}',
                textAlign: TextAlign.right,
                style: GoogleFonts.robotoMono(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.$7 == null ? '∞' : '${row.$7}',
              textAlign: TextAlign.right,
              style: GoogleFonts.robotoMono(
                  fontSize: 13, color: AdminColors.textMuted),
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
