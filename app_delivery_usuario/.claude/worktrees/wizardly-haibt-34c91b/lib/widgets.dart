import 'package:flutter/material.dart';
import 'theme.dart';

// ── Diagonal-stripe image placeholder ───────────────────────────────────────

class ImgPlaceholder extends StatelessWidget {
  final String label;
  final double height;
  final double? width;
  final double radius;
  final String tone;
  final String? assetPath;

  static const _tones = {
    'warm': [Color(0xFFFFE2D1), Color(0xFFFFD0B0)],
    'cool': [Color(0xFFE3ECF5), Color(0xFFC9D8E8)],
    'green': [Color(0xFFDFF0E7), Color(0xFFC3E4D1)],
    'purple': [Color(0xFFEADDF4), Color(0xFFD7C1EA)],
    'neutral': [Color(0xFFECECEF), Color(0xFFDADADF)],
  };

  const ImgPlaceholder({
    super.key,
    this.label = '',
    required this.height,
    this.width,
    this.radius = 14,
    this.tone = 'warm',
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: width,
          height: height,
          child: Image.asset(
            assetPath!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => _buildStripe(),
          ),
        ),
      );
    }
    return _buildStripe();
  }

  Widget _buildStripe() {
    final colors = _tones[tone] ?? _tones['warm']!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _StripePainter(colors[0], colors[1]),
          child: label.isEmpty
              ? null
              : Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0x73000000),
                        letterSpacing: 0.04,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  final Color a;
  final Color b;
  const _StripePainter(this.a, this.b);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = a);
    final paint = Paint()..color = b;
    const sw = 8.0;
    final total = size.width + size.height;
    for (double i = -total; i < total; i += sw * 2) {
      final path = Path()
        ..moveTo(i, 0)
        ..lineTo(i + sw, 0)
        ..lineTo(i + sw + size.height, size.height)
        ..lineTo(i + size.height, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter o) => o.a != a || o.b != b;
}

// ── Primary / variant button ─────────────────────────────────────────────────

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String variant;
  final Widget? leading;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = 'primary',
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BoxBorder? border;
    List<BoxShadow>? shadows;

    switch (variant) {
      case 'secondary':
        bg = AppColors.secondary;
        fg = Colors.white;
      case 'ghost':
        bg = Colors.white;
        fg = AppColors.appText;
        border = Border.all(color: AppColors.border, width: 1.5);
      case 'dark':
        bg = AppColors.appText;
        fg = Colors.white;
      case 'soft':
        bg = AppColors.primaryTint;
        fg = AppColors.primary;
      default:
        bg = AppColors.primary;
        fg = Colors.white;
        shadows = [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ];
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: border,
          boxShadow: shadows,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Input field ──────────────────────────────────────────────────────────────

class AppInputField extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final String? value;
  final String placeholder;
  final bool obscure;
  final Widget? trailing;

  const AppInputField({
    super.key,
    this.label,
    this.icon,
    this.value,
    this.placeholder = '',
    this.obscure = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.textMuted),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  obscure && hasValue ? '••••••••' : (value ?? placeholder),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    color: hasValue ? AppColors.appText : AppColors.textSubtle,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ],
    );
  }
}

// ── Real text input field ────────────────────────────────────────────────────

class AppTextField extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final String placeholder;
  final bool obscure;
  final Widget? trailing;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const AppTextField({
    super.key,
    this.label,
    this.icon,
    this.placeholder = '',
    this.obscure = false,
    this.trailing,
    this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.textMuted),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSubtle,
                        fontWeight: FontWeight.w400),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ],
    );
  }
}

// ── DeliPuno logo / wordmark ─────────────────────────────────────────────────

class DeliPunoLogo extends StatelessWidget {
  final double size;
  final Color color;
  const DeliPunoLogo({super.key, this.size = 64, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
      ),
      child: Center(
        child: Text(
          'D',
          style: TextStyle(
            color: color,
            fontSize: size * 0.52,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class DeliPunoWordmark extends StatelessWidget {
  final Color color;
  final double size;
  const DeliPunoWordmark({
    super.key,
    this.color = AppColors.appText,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Deli',
            style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.9,
              fontFamily: 'PlusJakartaSans',
              package: null,
            ),
          ),
          TextSpan(
            text: 'Puno',
            style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.9,
            ),
          ),
          TextSpan(
            text: '.',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: size * 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Star rating row ──────────────────────────────────────────────────────────

class StarRow extends StatelessWidget {
  final int active;
  final int total;
  final double size;

  const StarRow({
    super.key,
    required this.active,
    this.total = 5,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            i < active ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: i < active ? AppColors.star : AppColors.border,
          ),
        );
      }),
    );
  }
}

// ── Section title ────────────────────────────────────────────────────────────

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.36,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}
