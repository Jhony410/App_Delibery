import 'package:flutter/material.dart';
import 'theme.dart';

enum CButtonVariant { primary, online, danger, surface, ghost }

enum CButtonSize { md, lg, xl }

class CButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final CButtonVariant variant;
  final CButtonSize size;
  final bool fullWidth;

  const CButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = CButtonVariant.primary,
    this.size = CButtonSize.lg,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final (height, fontSize, radius, hPad) = switch (size) {
      CButtonSize.xl => (64.0, 19.0, 16.0, 22.0),
      CButtonSize.lg => (56.0, 17.0, 14.0, 20.0),
      CButtonSize.md => (44.0, 14.0, 12.0, 16.0),
    };
    final (bg, fg, border) = switch (variant) {
      CButtonVariant.primary => (CourierColors.primary, Colors.white, null),
      CButtonVariant.online => (CourierColors.online, CourierColors.onOnline, null),
      CButtonVariant.danger => (CourierColors.danger, Colors.white, null),
      CButtonVariant.surface => (CourierColors.surface2, CourierColors.text, null),
      CButtonVariant.ghost => (Colors.transparent, CourierColors.text, CourierColors.border),
    };

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            decoration: border != null
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: border, width: 1.5),
                  )
                : null,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22, color: fg),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: fg,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CField extends StatelessWidget {
  final String? label;
  final String? value;
  final String? placeholder;
  final IconData? icon;
  final Widget? suffix;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;

  const CField({
    super.key,
    this.label,
    this.value,
    this.placeholder,
    this.icon,
    this.suffix,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEditable = controller != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CourierColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: CourierColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CourierColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22, color: CourierColors.textMuted),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: isEditable
                    ? TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        obscureText: obscureText,
                        readOnly: readOnly,
                        style: const TextStyle(
                          fontSize: 16,
                          color: CourierColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: placeholder,
                          hintStyle: const TextStyle(
                            color: CourierColors.textSubtle,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : Text(
                        (value?.isNotEmpty ?? false) ? value! : (placeholder ?? ''),
                        style: TextStyle(
                          fontSize: 16,
                          color: (value?.isNotEmpty ?? false)
                              ? CourierColors.text
                              : CourierColors.textSubtle,
                          fontWeight: (value?.isNotEmpty ?? false)
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
              ),
              ?suffix,
            ],
          ),
        ),
      ],
    );
  }
}

class CTopBar extends StatelessWidget {
  final String title;
  final bool back;
  final Widget? trailing;
  final VoidCallback? onBack;

  const CTopBar({
    super.key,
    required this.title,
    this.back = true,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Row(
        children: [
          if (back) ...[
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CourierColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CourierColors.border, width: 1),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.chevron_left, size: 24, color: CourierColors.text),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: CourierColors.text,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const StatusPill({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: CourierColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderSide? border;
  final double radius;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.border,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? CourierColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.fromBorderSide(
          border ?? const BorderSide(color: CourierColors.border, width: 1),
        ),
      ),
      child: child,
    );
  }
}

class DarkMapBackground extends StatelessWidget {
  final bool withRoute;
  final double height;

  const DarkMapBackground({
    super.key,
    this.withRoute = false,
    this.height = 460,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _DarkMapPainter(withRoute: withRoute),
    );
  }
}

class _DarkMapPainter extends CustomPainter {
  final bool withRoute;
  _DarkMapPainter({required this.withRoute});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF15171C);
    canvas.drawRect(Offset.zero & size, bg);

    final block = Paint()..color = const Color(0xFF1E2128);
    final w = size.width;
    final third = size.height / 3;

    canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.32, third * 0.85), block);
    canvas.drawRect(Rect.fromLTWH(w * 0.40, 0, w * 0.32, third * 0.85), block);
    canvas.drawRect(Rect.fromLTWH(w * 0.78, 0, w * 0.22, third * 0.85), block);
    canvas.drawRect(Rect.fromLTWH(0, third + 30, w * 0.27, third * 0.85), block);
    canvas.drawRect(Rect.fromLTWH(w * 0.35, third + 30, w * 0.42, third * 0.85), block);
    canvas.drawRect(Rect.fromLTWH(w * 0.84, third + 30, w * 0.16, third * 0.85), block);

    final road = Paint()..color = const Color(0xFF2A2D36);
    canvas.drawRect(Rect.fromLTWH(0, third * 0.93, w, 14), road);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.6, w, 14), road);
    canvas.drawRect(Rect.fromLTWH(w * 0.32, 0, 14, size.height), road);
    canvas.drawRect(Rect.fromLTWH(w * 0.74, 0, 14, size.height), road);

    if (withRoute) {
      final routePath = Path()
        ..moveTo(w * 0.10, size.height * 0.10)
        ..quadraticBezierTo(
          w * 0.35, size.height * 0.20,
          w * 0.55, size.height * 0.50,
        )
        ..quadraticBezierTo(
          w * 0.80, size.height * 0.78,
          w * 0.85, size.height * 0.92,
        );

      final routeStroke = Paint()
        ..color = CourierColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(routePath, routeStroke);

      final dashStroke = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(_dashed(routePath, 4, 6), dashStroke);
    }
  }

  Path _dashed(Path source, double dash, double gap) {
    final result = Path();
    for (final m in source.computeMetrics()) {
      double dist = 0;
      while (dist < m.length) {
        final next = (dist + dash).clamp(0, m.length).toDouble();
        result.addPath(m.extractPath(dist, next), Offset.zero);
        dist = next + gap;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(_DarkMapPainter old) => old.withRoute != withRoute;
}

class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulsingDot({super.key, this.color = CourierColors.online, this.size = 22});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = _ctrl.value;
        return SizedBox(
          width: widget.size + 32,
          height: widget.size + 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size + 32 * t,
                height: widget.size + 32 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.30 * (1 - t)),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color color;
  final double size;
  final double iconSize;

  const IconBox({
    super.key,
    required this.icon,
    required this.background,
    required this.color,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
