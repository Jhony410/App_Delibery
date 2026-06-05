import 'package:flutter/material.dart';
import '../models/courier_model.dart';
import '../services/auth_service.dart';
import '../services/courier_service.dart';
import '../theme.dart';
import '../widgets.dart';

/// Waiting room shown while a courier's account is `pending_review`.
///
/// Instead of a fake countdown, this screen keeps a live snapshot listener on
/// the courier's own `couriers/{uid}` document. The moment the admin approves
/// (status → `active`) or rejects (status → `rejected`), this UI reacts in real
/// time — approval auto-advances to `/home`, rejection shows a clear message.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  String? _uid;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _uid = AuthService.currentUid;
  }

  void _goHome() {
    if (_navigated) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: CourierColors.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: CButton(
                label: 'Iniciar sesión',
                variant: CButtonVariant.primary,
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CourierColors.bg,
      body: SafeArea(
        child: StreamBuilder<CourierModel?>(
          stream: CourierService.streamCourier(uid),
          builder: (context, courierSnap) {
            final status = courierSnap.data?.status ?? 'pending_review';
            if (status == 'active') _goHome();

            return StreamBuilder<CourierNotice?>(
              stream: CourierService.streamLatestNotice(uid),
              builder: (context, noticeSnap) {
                return _buildContent(status, noticeSnap.data);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(String status, CourierNotice? notice) {
    switch (status) {
      case 'active':
        return _ApprovedView(
          message: notice?.type == 'approval' ? notice!.body : null,
          onEnter: () => Navigator.of(context).pushReplacementNamed('/home'),
        );
      case 'rejected':
      case 'suspended':
        return _RejectedView(
          suspended: status == 'suspended',
          message: notice?.type == 'rejection' ? notice!.body : null,
          onLogout: _logout,
        );
      default:
        return _PendingView(onLogout: _logout);
    }
  }
}

// ── Pending ──────────────────────────────────────────────────────────────
class _PendingView extends StatelessWidget {
  final Future<void> Function() onLogout;
  const _PendingView({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Datos personales', true),
      ('Documentos enviados', true),
      ('Verificación', false),
    ];
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const _ReviewBadge(
                    icon: Icons.hourglass_top_rounded,
                    color: CourierColors.warning,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Tu cuenta está\nen revisión',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: CourierColors.text,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Estamos validando tus documentos. Esta pantalla se '
                    'actualizará sola en cuanto un administrador apruebe '
                    'tu cuenta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: CourierColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: CourierColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: CourierColors.border),
                    ),
                    child: Column(
                      children:
                          steps.map((s) => _StatusRow(s.$1, s.$2)).toList(),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 36,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CButton(
                label: 'Contactar soporte',
                icon: Icons.help_outline,
                variant: CButtonVariant.ghost,
                onPressed: () {},
              ),
              const SizedBox(height: 10),
              CButton(
                label: 'Cerrar sesión',
                variant: CButtonVariant.surface,
                onPressed: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Approved ─────────────────────────────────────────────────────────────
class _ApprovedView extends StatelessWidget {
  final String? message;
  final VoidCallback onEnter;
  const _ApprovedView({required this.message, required this.onEnter});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const _ReviewBadge(
                    icon: Icons.check_rounded,
                    color: CourierColors.online,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '¡Cuenta aprobada!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: CourierColors.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message ??
                        'Tu cuenta fue verificada. Ya puedes conectarte y '
                            'empezar a recibir pedidos.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: CourierColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 36,
          child: CButton(
            label: 'Entrar ahora',
            icon: Icons.arrow_forward_rounded,
            variant: CButtonVariant.primary,
            onPressed: onEnter,
          ),
        ),
      ],
    );
  }
}

// ── Rejected / suspended ─────────────────────────────────────────────────
class _RejectedView extends StatelessWidget {
  final bool suspended;
  final String? message;
  final Future<void> Function() onLogout;
  const _RejectedView({
    required this.suspended,
    required this.message,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const _ReviewBadge(
                    icon: Icons.close_rounded,
                    color: CourierColors.danger,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    suspended
                        ? 'Cuenta\nsuspendida'
                        : 'Solicitud\nrechazada',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: CourierColors.text,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message ??
                        (suspended
                            ? 'Tu cuenta fue suspendida. Contacta a soporte '
                                'para más información.'
                            : 'Tu solicitud no fue aprobada. Escríbenos a '
                                'soporte para revisar tu caso.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: CourierColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 36,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CButton(
                label: 'Contactar soporte',
                icon: Icons.help_outline,
                variant: CButtonVariant.primary,
                onPressed: () {},
              ),
              const SizedBox(height: 10),
              CButton(
                label: 'Cerrar sesión',
                variant: CButtonVariant.surface,
                onPressed: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared bits ──────────────────────────────────────────────────────────
class _ReviewBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _ReviewBadge({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
          ),
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CourierColors.surface,
              border: Border.all(color: color, width: 3),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 60, color: color),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool done;
  const _StatusRow(this.label, this.done);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? CourierColors.online : CourierColors.surface2,
              border: done
                  ? null
                  : Border.all(
                      color: CourierColors.warning,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
            ),
            alignment: Alignment.center,
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: done ? CourierColors.text : CourierColors.textMuted,
              ),
            ),
          ),
          Text(
            done ? 'OK' : 'En proceso',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: done ? CourierColors.online : CourierColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
