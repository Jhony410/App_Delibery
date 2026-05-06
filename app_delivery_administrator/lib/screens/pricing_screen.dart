import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'config',
      title: 'Tarifas de delivery',
      actions: const [
        AdminButton(
            label: 'Descartar',
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
        AdminButton(label: 'Guardar cambios', size: AdminBtnSize.sm),
      ],
      child: LayoutBuilder(builder: (context, c) {
        final twoCol = c.maxWidth > 1100;
        final main = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _DistanceTable(),
            SizedBox(height: 16),
            _SurchargesGrid(),
            SizedBox(height: 16),
            _ZoneTariffs(),
          ],
        );
        final side = const _Simulator();
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
    );
  }
}

class _DistanceTable extends StatelessWidget {
  const _DistanceTable();
  @override
  Widget build(BuildContext context) {
    final rows = [
      ('0 - 2 km', 'S/ 4.90', 'S/ 3.50', 'S/ 1.40'),
      ('2 - 4 km', 'S/ 6.90', 'S/ 5.00', 'S/ 1.90'),
      ('4 - 6 km', 'S/ 8.90', 'S/ 6.50', 'S/ 2.40'),
      ('6 - 10 km', 'S/ 11.90', 'S/ 8.80', 'S/ 3.10'),
      ('+10 km', '+ S/ 1.20/km', '+ S/ 0.90/km', '—'),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tarifa base por distancia',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _tableHeader(),
          for (final r in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AdminColors.border))),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(r.$1,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(r.$2,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.robotoMono(fontSize: 13)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(r.$3,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.robotoMono(
                            fontSize: 13,
                            color: AdminColors.textMuted)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(r.$4,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.robotoMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.green)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Row(
      children: [
        Expanded(
            flex: 3,
            child: _Th('Rango')),
        Expanded(
            flex: 2,
            child: _Th('Costo cliente', align: TextAlign.right)),
        Expanded(
            flex: 2,
            child:
                _Th('Pago repartidor', align: TextAlign.right)),
        Expanded(
            flex: 2,
            child: _Th('Margen', align: TextAlign.right)),
      ],
    );
  }
}

class _SurchargesGrid extends StatelessWidget {
  const _SurchargesGrid();
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Hora pico almuerzo', '12:30 - 14:30', '+S/ 1.50'),
      ('Hora pico cena', '19:00 - 21:30', '+S/ 2.00'),
      ('Madrugada', '00:00 - 06:00', '+S/ 3.50'),
      ('Lluvia (auto)', 'Activa por sensor', '+25%'),
      ('Alta demanda', 'Surge dinámico', 'x1.2 - x1.8'),
      ('Día festivo', 'Calendario PE', '+S/ 2.00'),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Recargos por horario',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 700 ? 3 : 2;
            return GridView.count(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.4,
              children: items
                  .map((s) => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: AdminColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(s.$1,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(s.$2,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AdminColors.textMuted)),
                            const Spacer(),
                            Text(s.$3,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AdminColors.primary)),
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

class _ZoneTariffs extends StatelessWidget {
  const _ZoneTariffs();
  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Lima Centro', 'x1.0', 'S/ 4.90', 'green', 'Activa'),
      ('Miraflores - Surco', 'x1.0', 'S/ 5.50', 'green', 'Activa'),
      ('San Isidro', 'x1.3 (premium)', 'S/ 7.90', 'green', 'Activa'),
      ('La Molina', 'x1.1', 'S/ 6.90', 'green', 'Activa'),
      ('Lima Norte', 'x0.9', 'S/ 4.50', 'amber', 'Promo'),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tarifas por zona',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(flex: 4, child: _Th('Zona')),
              Expanded(
                  flex: 3,
                  child: _Th('Multiplicador', align: TextAlign.right)),
              Expanded(
                  flex: 2,
                  child: _Th('Mínimo', align: TextAlign.right)),
              SizedBox(width: 16),
              SizedBox(width: 80, child: _Th('Estado')),
            ],
          ),
          for (final r in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AdminColors.border))),
              child: Row(
                children: [
                  Expanded(
                      flex: 4,
                      child: Text(r.$1,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600))),
                  Expanded(
                      flex: 3,
                      child: Text(r.$2,
                          textAlign: TextAlign.right,
                          style:
                              GoogleFonts.robotoMono(fontSize: 13))),
                  Expanded(
                      flex: 2,
                      child: Text(r.$3,
                          textAlign: TextAlign.right,
                          style:
                              GoogleFonts.robotoMono(fontSize: 13))),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: AdminBadge(r.$5, tone: r.$4),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Simulator extends StatelessWidget {
  const _Simulator();
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Simulador',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _input('Distancia', '3.4 km'),
          const SizedBox(height: 10),
          _input('Zona', 'Miraflores - Surco'),
          const SizedBox(height: 10),
          _input('Hora', '20:15 (cena)'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AdminColors.border),
          ),
          for (final r in const [
            ('Tarifa base', 'S/ 6.90'),
            ('Recargo cena', '+S/ 2.00'),
            ('Surge demanda', 'x1.2'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.$1,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AdminColors.textMuted)),
                  Text(r.$2,
                      style: GoogleFonts.robotoMono(fontSize: 12)),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AdminColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total cliente',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              Text('S/ 10.68',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _input(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AdminColors.textMuted)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AdminColors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(value,
                    style: GoogleFonts.robotoMono(fontSize: 13)),
              ),
              const Icon(Icons.expand_more,
                  size: 14, color: AdminColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }
}

class _Th extends StatelessWidget {
  final String label;
  final TextAlign align;
  const _Th(this.label, {this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      textAlign: align,
      style: const TextStyle(
        fontSize: 11,
        color: AdminColors.textMuted,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }
}
