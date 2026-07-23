import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

/// ─── Card ──────────────────────────────────────────────────────
class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Color? background;

  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.background,
  });

  /// No-padding variant for tables/lists where the children handle their own.
  const AdminCard.flush({
    super.key,
    required this.child,
    this.margin,
    this.background,
  }) : padding = EdgeInsets.zero;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: background ?? AdminColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// ─── Badge ─────────────────────────────────────────────────────
class AdminBadge extends StatelessWidget {
  final String label;
  final String tone; // gray | green | amber | red | blue | purple | coral

  const AdminBadge(this.label, {super.key, this.tone = 'gray'});

  static const _palette = <String, List<Color>>{
    'gray': [AdminColors.grayTint, AdminColors.textMuted],
    'green': [AdminColors.greenTint, AdminColors.green],
    'amber': [AdminColors.amberTint, AdminColors.amber],
    'red': [AdminColors.redTint, AdminColors.red],
    'blue': [AdminColors.blueTint, AdminColors.blue],
    'purple': [AdminColors.purpleTint, AdminColors.purple],
    'coral': [AdminColors.primaryTint, AdminColors.primary],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _palette[tone] ?? _palette['gray']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors[0],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: colors[1], shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: colors[1],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Button ────────────────────────────────────────────────────
enum AdminBtnVariant { primary, secondary, ghost, coral, danger, success }

enum AdminBtnSize { sm, md, lg }

class AdminButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AdminBtnVariant variant;
  final AdminBtnSize size;
  final VoidCallback? onPressed;
  final bool loading;

  const AdminButton({
    super.key,
    required this.label,
    this.icon,
    this.variant = AdminBtnVariant.primary,
    this.size = AdminBtnSize.md,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final dims = switch (size) {
      AdminBtnSize.sm => const _BtnDims(30, 10, 12.5, 14),
      AdminBtnSize.md => const _BtnDims(36, 14, 13, 14),
      AdminBtnSize.lg => const _BtnDims(42, 18, 14, 16),
    };
    final palette = switch (variant) {
      AdminBtnVariant.primary =>
        const _BtnPalette(AdminColors.text, Colors.white, null),
      AdminBtnVariant.secondary =>
        const _BtnPalette(Colors.white, AdminColors.text, AdminColors.border),
      AdminBtnVariant.ghost =>
        const _BtnPalette(Colors.transparent, AdminColors.text, null),
      AdminBtnVariant.coral =>
        const _BtnPalette(AdminColors.primary, Colors.white, null),
      AdminBtnVariant.danger =>
        const _BtnPalette(Colors.white, AdminColors.red, AdminColors.border),
      AdminBtnVariant.success =>
        const _BtnPalette(AdminColors.green, Colors.white, null),
    };
    return Material(
      color: palette.bg,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onPressed,
        child: Container(
          height: dims.h,
          padding: EdgeInsets.symmetric(horizontal: dims.px),
          decoration: BoxDecoration(
            border: palette.border == null
                ? null
                : Border.all(color: palette.border!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: dims.iconSize,
                  height: dims.iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(palette.fg),
                  ),
                )
              else if (icon != null)
                Icon(icon, size: dims.iconSize, color: palette.fg),
              if ((icon != null || loading) && label.isNotEmpty)
                const SizedBox(width: 6),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: dims.fs,
                    fontWeight: FontWeight.w600,
                    color: palette.fg,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BtnDims {
  final double h;
  final double px;
  final double fs;
  final double iconSize;
  const _BtnDims(this.h, this.px, this.fs, this.iconSize);
}

class _BtnPalette {
  final Color bg;
  final Color fg;
  final Color? border;
  const _BtnPalette(this.bg, this.fg, this.border);
}

/// ─── Avatar with initials ──────────────────────────────────────
class AdminAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String tone;

  const AdminAvatar({
    super.key,
    required this.name,
    this.size = 28,
    this.tone = 'coral',
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AdminColors.avatarGradients[tone] ??
        AdminColors.avatarGradients['coral']!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// ─── Status dot with label ─────────────────────────────────────
class AdminStatusDot extends StatelessWidget {
  final Color color;
  final String label;

  const AdminStatusDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5)),
      ],
    );
  }
}

/// ─── Section eyebrow heading (UPPER, muted) ────────────────────
class AdminEyebrow extends StatelessWidget {
  final String label;
  const AdminEyebrow(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        color: AdminColors.textMuted,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

/// ─── Search-style fake input field (for the screens that show the
/// design without functional input). Used in mock filters. ───────
class AdminFakeField extends StatelessWidget {
  final IconData? icon;
  final String text;
  final IconData? trailing;
  final double width;

  const AdminFakeField({
    super.key,
    this.icon,
    required this.text,
    this.trailing,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AdminColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: width == double.infinity
            ? MainAxisSize.max
            : MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AdminColors.textMuted),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            Icon(trailing, size: 14, color: AdminColors.textMuted),
          ],
        ],
      ),
    );
  }
}

/// ─── Functional text input field with label ────────────────────
class AdminTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final bool obscure;
  final String? hint;
  final String? trailingLabel;
  final TextInputType? keyboardType;

  const AdminTextField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.obscure = false,
    this.hint,
    this.trailingLabel,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            if (trailingLabel != null)
              Text(
                trailingLabel!,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.primary),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, size: 16, color: AdminColors.textMuted),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AdminColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AdminColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AdminColors.text, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ─── Read-only display field (label + bordered value). ─────────
class AdminReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const AdminReadOnlyField({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AdminColors.textMuted)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border.all(color: AdminColors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

/// ─── Pill toggle row (e.g. "Todos · 1,247", "Activos · 89") ────
class AdminPillToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  const AdminPillToggle({
    super.key,
    required this.options,
    this.selectedIndex = 0,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(options.length, (i) {
        final selected = i == selectedIndex;
        return Material(
          color: selected ? AdminColors.text : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onSelected?.call(i),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: selected
                    ? null
                    : Border.all(color: AdminColors.border),
              ),
              child: Text(
                options[i],
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AdminColors.textMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// ─── Error state ───────────────────────────────────────────────
/// Visible error card shown when a StreamBuilder/FutureBuilder reports
/// `snapshot.hasError`. A Firestore failure (e.g. permission-denied) must
/// surface as this — never as an empty list, which hides the real cause.
class AdminErrorState extends StatelessWidget {
  final String message;
  final String? title;
  const AdminErrorState({super.key, required this.message, this.title});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      background: AdminColors.redTint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.error_outline,
                size: 20, color: AdminColors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? 'No se pudieron cargar los datos',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.red),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  message,
                  style: const TextStyle(
                      fontSize: 12.5, color: AdminColors.text),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Abre la consola del navegador (F12) para ver el detalle completo.',
                  style: TextStyle(
                      fontSize: 11, color: AdminColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
