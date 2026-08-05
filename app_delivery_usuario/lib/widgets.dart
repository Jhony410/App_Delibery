import 'package:flutter/material.dart';
import 'theme.dart';

String formatDeliveryTime(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Por confirmar';
  final normalized = trimmed.toLowerCase();
  if (normalized.contains('min') ||
      normalized.contains('hora') ||
      RegExp(r'\d\s*h($|\s)').hasMatch(normalized)) {
    return trimmed;
  }
  return '$trimmed min';
}

// ── Diagonal-stripe image placeholder ───────────────────────────────────────

class ImgPlaceholder extends StatelessWidget {
  final String label;
  final double height;
  final double? width;
  final double radius;
  final String tone;
  final String? assetPath;

  /// URL de imagen real (Firebase Storage o externa). Cuando viene no vacía se
  /// renderiza con [Image.network]; si es null/vacía o la carga falla, se cae
  /// al comportamiento actual ([assetPath] o el placeholder rayado).
  final String? imageUrl;

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
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: width,
          height: height,
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: (_tones[tone] ?? _tones['warm']!)[0],
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stack) => _buildFallback(),
          ),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label.toUpperCase(),
                      style: TextStyle(
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
  final bool isLoading;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = 'primary',
    this.leading,
    this.isLoading = false,
    this.expand = true,
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
        bg = context.colors.surface;
        fg = context.colors.onSurface;
        border = Border.all(color: context.colors.outlineVariant, width: 1.5);
      case 'dark':
        bg = context.colors.inverseSurface;
        fg = context.colors.onInverseSurface;
      case 'soft':
        bg = context.colors.primaryContainer;
        fg = context.colors.onPrimaryContainer;
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

    final enabled = onTap != null && !isLoading;
    final button = Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.55,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: border,
                boxShadow: shadows,
              ),
              alignment: Alignment.center,
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: fg,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fg,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border.all(
              color: context.colors.outlineVariant,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  obscure && hasValue ? '••••••••' : (value ?? placeholder),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    color: hasValue
                        ? context.colors.onSurface
                        : context.colors.outline,
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
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;

  const AppTextField({
    super.key,
    this.label,
    this.icon,
    this.placeholder = '',
    this.obscure = false,
    this.trailing,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: icon == null
                ? null
                : Icon(
                    icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            suffixIcon: trailing == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: trailing,
                  ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        child: Image.asset(
          'assets/icon/icon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Text(
              'D',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: size * 0.52,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DeliPunoWordmark extends StatelessWidget {
  final Color? color;
  final double size;
  const DeliPunoWordmark({super.key, this.color, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Deli',
            style: TextStyle(
              color: color ?? AppColors.primary,
              fontSize: size,
              fontWeight: FontWeight.w800,
              fontFamily: 'PlusJakartaSans',
              package: null,
            ),
          ),
          TextSpan(
            text: 'Puno',
            style: TextStyle(
              color: color ?? AppColors.secondary,
              fontSize: size,
              fontWeight: FontWeight.w800,
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
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            i < active ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: i < active
                ? AppColors.star
                : Theme.of(context).colorScheme.outlineVariant,
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
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.36,
            ),
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: TextStyle(
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

class AppStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(label: actionLabel!, onTap: onAction, expand: false),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const AppSkeleton({
    super.key,
    required this.height,
    this.width,
    this.radius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation shown when the user tries to add a product from a different
/// store than the one already in the cart (the cart is single-store).
/// Returns true if the user chose to empty the cart and add the new product.
Future<bool> showReplaceCartDialog(
  BuildContext context, {
  required String currentStoreName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Solo puedes pedir de una tienda',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      content: Text(
        'Tu carrito tiene productos de "$currentStoreName". Solo puedes pedir '
        'de una tienda a la vez. ¿Quieres vaciar el carrito y agregar este '
        'producto?',
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: ctx.colors.onSurfaceVariant,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: ctx.colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            'Vaciar carrito y agregar',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
