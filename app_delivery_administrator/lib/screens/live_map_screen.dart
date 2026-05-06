import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class LiveMapScreen extends StatelessWidget {
  const LiveMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'mapa',
      title: 'Mapa en vivo',
      actions: const [
        AdminStatusDot(
            color: AdminColors.green, label: 'Actualizado hace 2s'),
        SizedBox(width: 8),
        AdminButton(
            label: 'Filtros',
            icon: Icons.filter_alt_outlined,
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
      ],
      child: LayoutBuilder(builder: (context, c) {
        final twoCol = c.maxWidth > 1100;
        final map = SizedBox(
          height: 760,
          child: AdminCard.flush(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _CityPainter()),
                  ),
                  // Couriers
                  for (final c in _couriers)
                    Positioned(
                      left: c.x,
                      top: c.y,
                      child: AdminAvatar(
                        name: c.label,
                        size: 26,
                        tone: c.tone,
                      ),
                    ),
                  // Legend
                  const Positioned(top: 16, left: 16, child: _Legend()),
                  Positioned(right: 16, bottom: 16, child: _ZoomCtrls()),
                ],
              ),
            ),
          ),
        );
        final right = SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _InProgressOrders(),
              SizedBox(height: 12),
              _ZoneHeat(),
            ],
          ),
        );
        if (!twoCol) {
          return Column(
              children: [map, const SizedBox(height: 16), right]);
        }
        return SizedBox(
          height: 760,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: map),
              const SizedBox(width: 16),
              right,
            ],
          ),
        );
      }),
    );
  }
}

class _CourierDot {
  final double x;
  final double y;
  final String tone;
  final String label;
  const _CourierDot(this.x, this.y, this.tone, this.label);
}

const _couriers = <_CourierDot>[
  _CourierDot(120, 220, 'coral', 'JR'),
  _CourierDot(280, 480, 'blue', 'AS'),
  _CourierDot(560, 280, 'green', 'PQ'),
  _CourierDot(720, 580, 'purple', 'MV'),
  _CourierDot(180, 620, 'amber', 'CM'),
  _CourierDot(430, 150, 'coral', 'JI'),
  _CourierDot(800, 380, 'blue', 'LP'),
  _CourierDot(340, 380, 'green', 'SH'),
  _CourierDot(620, 100, 'amber', 'DO'),
  _CourierDot(80, 420, 'purple', 'BG'),
  _CourierDot(500, 600, 'coral', 'EQ'),
];

class _CityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = const Color(0xFFDDE7EC));
    final block = Paint()..color = const Color(0xFFE8EEF2);
    final cols = 12;
    final rows = math.max(8, (size.height / 72).round());
    final cw = size.width / cols;
    final ch = size.height / rows;
    for (int r = 0; r < rows; r++) {
      for (int col = 0; col < cols; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(col * cw + 5, r * ch + 5, cw - 10, ch - 10),
            const Radius.circular(3),
          ),
          block,
        );
      }
    }
    final road = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.47, size.width, 14), road);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.41, 0, 14, size.height), road);
    // Curved avenue
    final p = Path()
      ..moveTo(0, size.height * 0.26)
      ..quadraticBezierTo(size.width * 0.33, size.height * 0.29,
          size.width * 0.55, size.height * 0.24)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.20,
          size.width, size.height * 0.29);
    canvas.drawPath(
        p,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10);
    // Park
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.66, size.height * 0.59,
            size.width * 0.18, size.height * 0.16),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFC8DCC4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('EN VIVO · LIMA CENTRO',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AdminColors.textMuted)),
          const SizedBox(height: 8),
          _legendRow(AdminColors.green, 'Disponibles', '72'),
          _legendRow(AdminColors.primary, 'En entrega', '112'),
          _legendRow(AdminColors.textMuted, 'En descanso', '23'),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: SizedBox(
        width: 200,
        child: Row(
          children: [
            AdminStatusDot(color: color, label: label),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

class _ZoomCtrls extends StatelessWidget {
  const _ZoomCtrls();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _zoomBtn(Icons.add),
          Container(width: 36, height: 1, color: AdminColors.border),
          _zoomBtn(Icons.remove),
        ],
      ),
    );
  }

  Widget _zoomBtn(IconData icon) => SizedBox(
      width: 36, height: 36, child: Center(child: Icon(icon, size: 18)));
}

class _InProgressOrders extends StatelessWidget {
  const _InProgressOrders();
  @override
  Widget build(BuildContext context) {
    final rows = const [
      ('#RN-24891', 'Julio R.', 'En camino', 'green'),
      ('#RN-24890', 'Ana S.', 'Recogiendo', 'amber'),
      ('#RN-24886', 'Carla M.', 'En camino', 'green'),
      ('#RN-24883', '—', 'Buscando', 'red'),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pedidos en curso',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(rows[i].$1,
                        style: GoogleFonts.robotoMono(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: Text(rows[i].$2,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AdminColors.textMuted)),
                  ),
                  AdminBadge(rows[i].$3, tone: rows[i].$4),
                ],
              ),
            ),
            if (i < rows.length - 1)
              const Divider(height: 1, color: AdminColors.border),
          ],
        ],
      ),
    );
  }
}

class _ZoneHeat extends StatelessWidget {
  const _ZoneHeat();
  @override
  Widget build(BuildContext context) {
    final zones = const [
      ('Miraflores', 89, AdminColors.red),
      ('Surco', 67, AdminColors.primary),
      ('San Isidro', 54, AdminColors.amber),
      ('Lince', 42, AdminColors.green),
      ('Barranco', 28, AdminColors.green),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calor por zonas',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final z in zones) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(z.$1,
                          style: const TextStyle(fontSize: 12)),
                      Text('${z.$2} ped.',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AdminColors.bg,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: z.$2 / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: z.$3,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
