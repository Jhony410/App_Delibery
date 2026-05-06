import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  int _selected = 0;
  static const _zones = [
    (
      'Lima Centro',
      'Lince, Jesús María, Pueblo Libre',
      Color(0xFFFF6B35),
      false,
    ),
    (
      'Miraflores - Surco',
      'Miraflores, Surco, San Borja',
      Color(0xFF3B82F6),
      false,
    ),
    (
      'San Isidro',
      'San Isidro · Tarifa premium',
      Color(0xFF10B981),
      false,
    ),
    (
      'La Molina',
      'La Molina, Ate (parcial)',
      Color(0xFF8B5CF6),
      false,
    ),
    (
      'Lima Norte',
      'Comas, Independencia',
      Color(0xFFF59E0B),
      false,
    ),
    (
      'Callao Bellavista',
      'Callao centro',
      Color(0xFFEC4899),
      false,
    ),
    (
      'Lima Sur',
      'Chorrillos, Barranco',
      Color(0xFF06B6D4),
      false,
    ),
    (
      'Zonas piloto',
      'En prueba',
      Color(0xFF9CA3AF),
      true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'config',
      title: 'Zonas de cobertura',
      actions: const [
        AdminButton(
            label: 'Importar GeoJSON',
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
        AdminButton(
            label: 'Dibujar zona',
            icon: Icons.add,
            size: AdminBtnSize.sm),
      ],
      child: SizedBox(
        height: 760,
        child: LayoutBuilder(builder: (context, c) {
          final twoCol = c.maxWidth > 1100;
          final list = SizedBox(
            width: twoCol ? 320 : double.infinity,
            child: AdminCard.flush(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: AdminColors.border)),
                    ),
                    child: Row(
                      children: [
                        Text('Zonas configuradas',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Text('(${_zones.length})',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AdminColors.textMuted)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _zones.length,
                      itemBuilder: (context, i) {
                        final z = _zones[i];
                        final selected = i == _selected;
                        return InkWell(
                          onTap: () => setState(() => _selected = i),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AdminColors.bg
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                    color: AdminColors.border),
                                left: BorderSide(
                                  width: 3,
                                  color: selected
                                      ? AdminColors.primary
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  margin:
                                      const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: z.$3,
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(z.$1,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(z.$2,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color:
                                                  AdminColors.textMuted)),
                                      const SizedBox(height: 6),
                                      AdminBadge(
                                          z.$4 ? 'Borrador' : 'Operativa',
                                          tone:
                                              z.$4 ? 'amber' : 'green'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
          final map = AdminCard.flush(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _ZoneMapPainter()),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 14,
                              offset: Offset(0, 4)),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: const [
                          _MapTool(icon: Icons.pan_tool_outlined),
                          _MapTool(
                              icon: Icons.edit_outlined, active: true),
                          _MapTool(icon: Icons.crop_square),
                          _MapTool(icon: Icons.circle_outlined),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 8,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Text(
                        'Lima Centro · 12 vértices · 14.3 km²',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: AdminColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          if (!twoCol) {
            return Column(
                children: [list, const SizedBox(height: 16), Expanded(child: map)]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              list,
              const SizedBox(width: 20),
              Expanded(child: map),
            ],
          );
        }),
      ),
    );
  }
}

class _MapTool extends StatelessWidget {
  final IconData icon;
  final bool active;
  const _MapTool({required this.icon, this.active = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
          color: active ? AdminColors.text : Colors.transparent,
          borderRadius: BorderRadius.circular(6)),
      alignment: Alignment.center,
      child: Icon(icon,
          size: 16,
          color: active ? Colors.white : AdminColors.text),
    );
  }
}

class _ZoneMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFE5EDF2));
    final block = Paint()..color = const Color(0xFFEFF4F7);
    canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.22, h * 0.24), block);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.24, 0, w * 0.31, h * 0.24), block);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.58, 0, w * 0.42, h * 0.24), block);
    canvas.drawRect(
        Rect.fromLTWH(0, h * 0.27, w * 0.18, h * 0.27), block);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.20, h * 0.27, w * 0.36, h * 0.27), block);

    final road = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawLine(
        Offset(0, h * 0.25), Offset(w, h * 0.25), road);
    canvas.drawLine(
        Offset(0, h * 0.54), Offset(w, h * 0.54), road);
    canvas.drawLine(
        Offset(w * 0.23, 0), Offset(w * 0.23, h), road);
    canvas.drawLine(
        Offset(w * 0.57, 0), Offset(w * 0.57, h), road);

    // Polygons
    _polygon(canvas, w, h, [
      const Offset(0.07, 0.10),
      const Offset(0.31, 0.08),
      const Offset(0.36, 0.22),
      const Offset(0.27, 0.34),
      const Offset(0.09, 0.31),
    ], const Color(0xFFFF6B35), 'Lima Centro');
    _polygon(canvas, w, h, [
      const Offset(0.60, 0.12),
      const Offset(0.89, 0.10),
      const Offset(0.93, 0.26),
      const Offset(0.87, 0.38),
      const Offset(0.65, 0.41),
      const Offset(0.58, 0.26),
    ], const Color(0xFF3B82F6), 'Miraflores - Surco');
    _polygon(canvas, w, h, [
      const Offset(0.39, 0.43),
      const Offset(0.53, 0.42),
      const Offset(0.60, 0.55),
      const Offset(0.51, 0.64),
      const Offset(0.36, 0.62),
    ], const Color(0xFF10B981), 'San Isidro');
    _polygon(canvas, w, h, [
      const Offset(0.71, 0.58),
      const Offset(0.94, 0.57),
      const Offset(0.97, 0.74),
      const Offset(0.80, 0.76),
      const Offset(0.67, 0.71),
    ], const Color(0xFF8B5CF6), 'La Molina');
  }

  void _polygon(Canvas canvas, double w, double h, List<Offset> pts,
      Color color, String label) {
    final path = Path();
    final scaled =
        pts.map((p) => Offset(p.dx * w, p.dy * h)).toList();
    path.moveTo(scaled.first.dx, scaled.first.dy);
    for (final p in scaled.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
        path, Paint()..color = color.withValues(alpha: 0.22));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    final cx =
        scaled.fold<double>(0, (a, b) => a + b.dx) / scaled.length;
    final cy =
        scaled.fold<double>(0, (a, b) => a + b.dy) / scaled.length;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
