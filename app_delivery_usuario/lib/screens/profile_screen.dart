import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/address_model.dart';
import '../models/favorite_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/db_service.dart';
import '../theme.dart';
import '../theme_controller.dart';
import '../widgets.dart';
import 'addresses_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _appVersion = 'v1.0.0';

  bool _navigating = false;
  bool _loggingOut = false;
  bool _sendingReset = false;

  Future<void> _openRoute(String route, {Object? arguments}) async {
    if (_navigating) return;
    setState(() => _navigating = true);
    await Navigator.pushNamed(context, route, arguments: arguments);
    if (mounted) setState(() => _navigating = false);
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUid;
    if (uid == null) {
      return Scaffold(
        body: AppStateView(
          icon: Icons.person_off_outlined,
          title: 'Inicia sesión para ver tu perfil',
          message: 'Tus datos y preferencias aparecerán aquí.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<UserModel?>(
        stream: DbService.streamUser(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const SafeArea(
              child: AppStateView(
                icon: Icons.cloud_off_rounded,
                title: 'No pudimos cargar tu perfil',
                message:
                    'Revisa tu conexión. Los datos se actualizarán automáticamente.',
              ),
            );
          }

          final loading =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;
          return _ProfileContent(
            uid: uid,
            user: snapshot.data,
            loading: loading,
            onEdit: snapshot.data == null
                ? null
                : () => _showEditDialog(snapshot.data!),
            onAddresses: () =>
                _openRoute('/addresses', arguments: AddressListMode.manage),
            onNotifications: () => _openRoute('/notifications'),
            onFavorites: () => _openRoute('/favorites'),
            onHelp: () => _openRoute('/help'),
            onPasswordReset:
                AuthService.currentUser?.providerData.any(
                      (provider) => provider.providerId == 'password',
                    ) ==
                    true
                ? (_sendingReset ? null : _confirmPasswordReset)
                : null,
            onLogout: _loggingOut ? null : _confirmLogout,
            loggingOut: _loggingOut,
            appVersion: _appVersion,
          );
        },
      ),
    );
  }

  Future<void> _confirmPasswordReset() async {
    final email = AuthService.currentUser?.email;
    if (email == null || email.trim().isEmpty) {
      _showMessage('Tu cuenta no tiene un correo registrado', error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cambiar contraseña'),
        content: Text(
          'Enviaremos un enlace seguro a $email para que establezcas una nueva contraseña.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Enviar enlace'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sendingReset = true);
    try {
      await AuthService.sendPasswordReset(email);
      _showMessage('Enlace enviado a $email');
    } on FirebaseAuthException catch (error) {
      final message = switch (error.code) {
        'network-request-failed' => 'Sin conexión a internet',
        'too-many-requests' => 'Demasiados intentos. Intenta más tarde',
        _ => 'No pudimos enviar el enlace de recuperación',
      };
      _showMessage(message, error: true);
    } catch (_) {
      _showMessage('No pudimos enviar el enlace de recuperación', error: true);
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cerrar sesión'),
        content: Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Cerrar sesión',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      await AuthService.signOut(preservePasswordBiometrics: true);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loggingOut = false);
        _showMessage('No pudimos cerrar la sesión', error: true);
      }
    }
  }

  Future<void> _showEditDialog(UserModel user) async {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final formKey = GlobalKey<FormState>();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Editar mis datos'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresa tu nombre'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: const InputDecoration(
                      labelText: 'Celular',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresa tu celular'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancelar'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => saving = true);
                      try {
                        await DbService.updateUser(user.uid, {
                          'name': nameController.text.trim(),
                          'phone': phoneController.text.trim(),
                        });
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _showMessage('Perfil actualizado');
                      } catch (_) {
                        if (dialogContext.mounted) {
                          setDialogState(() => saving = false);
                        }
                        _showMessage(
                          'No se pudo actualizar el perfil',
                          error: true,
                        );
                      }
                    },
              child: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    phoneController.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? context.colors.error
            : context.semantic.success,
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final String uid;
  final UserModel? user;
  final bool loading;
  final VoidCallback? onEdit;
  final VoidCallback onAddresses;
  final VoidCallback onNotifications;
  final VoidCallback onFavorites;
  final VoidCallback onHelp;
  final VoidCallback? onPasswordReset;
  final VoidCallback? onLogout;
  final bool loggingOut;
  final String appVersion;

  const _ProfileContent({
    required this.uid,
    required this.user,
    required this.loading,
    required this.onEdit,
    required this.onAddresses,
    required this.onNotifications,
    required this.onFavorites,
    required this.onHelp,
    required this.onPasswordReset,
    required this.onLogout,
    required this.loggingOut,
    required this.appVersion,
  });

  @override
  Widget build(BuildContext context) {
    final authUser = AuthService.currentUser;
    final email = _displayValue(user?.email, fallback: authUser?.email);
    final phone = _displayValue(user?.phone);
    final name = _displayValue(user?.name, emptyValue: 'Usuario DeliPuno');

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ProfileHeader(
            name: name,
            secondaryText: email == 'No registrado' ? phone : email,
            photoUrl: authUser?.photoURL,
            memberSince: user?.memberSince,
            loading: loading,
            onEdit: onEdit,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverList.list(
            children: [
              ProfileContactCard(phone: phone, email: email, loading: loading),
              const SizedBox(height: AppSpacing.lg),
              _ProfileStats(uid: uid, user: user, loading: loading),
              const SizedBox(height: AppSpacing.lg),
              SupportCard(onTap: onHelp),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('Mi cuenta'),
              const SizedBox(height: AppSpacing.sm),
              ProfileMenuSection(
                children: [
                  ProfileMenuItem(
                    icon: Icons.edit_outlined,
                    title: 'Editar mis datos',
                    subtitle: 'Nombre y celular',
                    onTap: onEdit,
                  ),
                  StreamBuilder<List<AddressModel>>(
                    stream: DbService.streamUserAddresses(uid),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length;
                      final subtitle = count == null
                          ? 'Cargando direcciones...'
                          : count == 0
                          ? 'Ninguna guardada'
                          : '$count guardada${count == 1 ? '' : 's'}';
                      return ProfileMenuItem(
                        icon: Icons.location_on_outlined,
                        title: 'Mis direcciones',
                        subtitle: subtitle,
                        onTap: onAddresses,
                      );
                    },
                  ),
                  StreamBuilder<int>(
                    stream: DbService.countUnreadNotifications(uid),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return ProfileMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notificaciones',
                        subtitle: count == 0
                            ? 'No tienes notificaciones nuevas'
                            : '$count sin leer',
                        onTap: onNotifications,
                      );
                    },
                  ),
                  StreamBuilder<List<FavoriteModel>>(
                    stream: DbService.streamUserFavorites(uid),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return ProfileMenuItem(
                        icon: Icons.favorite_border_rounded,
                        title: 'Favoritos',
                        subtitle: count == 0
                            ? 'Aún no tienes favoritos'
                            : '$count comercio${count == 1 ? '' : 's'}',
                        onTap: onFavorites,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('Seguridad'),
              const SizedBox(height: AppSpacing.sm),
              ProfileMenuSection(
                children: [
                  const BiometricAccessTile(),
                  const AppearanceTile(),
                  if (onPasswordReset != null)
                    ProfileMenuItem(
                      icon: Icons.lock_reset_rounded,
                      title: 'Cambiar contraseña',
                      subtitle: 'Recibe un enlace en tu correo',
                      onTap: onPasswordReset,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              ProfileMenuSection(
                children: [
                  ProfileMenuItem(
                    icon: Icons.logout_rounded,
                    title: loggingOut ? 'Cerrando sesión...' : 'Cerrar sesión',
                    subtitle: 'Salir de esta cuenta',
                    onTap: onLogout,
                    danger: true,
                    trailing: loggingOut
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'DeliPuno · $appVersion',
                  style: TextStyle(fontSize: 11, color: context.colors.outline),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }

  static String _displayValue(
    String? value, {
    String? fallback,
    String emptyValue = 'No registrado',
  }) {
    final normalized = value?.trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
    final normalizedFallback = fallback?.trim();
    if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
      return normalizedFallback;
    }
    return emptyValue;
  }
}

class ProfileHeader extends StatelessWidget {
  final String name;
  final String secondaryText;
  final String? photoUrl;
  final DateTime? memberSince;
  final bool loading;
  final VoidCallback? onEdit;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.secondaryText,
    required this.photoUrl,
    required this.memberSince,
    required this.loading,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mi perfil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Editar mis datos',
                onPressed: onEdit,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: 94,
            height: 94,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: AppShadows.raised,
            ),
            child: ClipOval(
              child: _ProfileAvatar(
                photoUrl: photoUrl,
                initials: initials.isEmpty ? '?' : initials,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loading ? 'Cargando perfil...' : name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loading ? 'Obteniendo tus datos' : secondaryText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          if (memberSince != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Miembro desde ${memberSince!.year}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;

  const _ProfileAvatar({required this.photoUrl, required this.initials});

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) return _fallback(context);
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Center(
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class ProfileContactCard extends StatelessWidget {
  final String phone;
  final String email;
  final bool loading;

  const ProfileContactCard({
    super.key,
    required this.phone,
    required this.email,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: context.isDark ? null : AppShadows.card,
      ),
      child: Column(
        children: [
          _ContactRow(
            icon: Icons.phone_outlined,
            iconColor: context.semantic.success,
            label: 'Celular',
            value: loading ? 'Cargando...' : phone,
          ),
          Divider(indent: 54),
          _ContactRow(
            icon: Icons.email_outlined,
            iconColor: AppColors.primary,
            label: 'Correo',
            value: loading ? 'Cargando...' : email,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _SoftIcon(icon: icon, color: iconColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  final String uid;
  final UserModel? user;
  final bool loading;

  const _ProfileStats({
    required this.uid,
    required this.user,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FavoriteModel>>(
      stream: DbService.streamUserFavorites(uid),
      builder: (context, snapshot) {
        return Row(
          children: [
            Expanded(
              child: _Statistic(
                value: loading ? '—' : '${user?.totalOrders ?? 0}',
                label: 'Pedidos',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Statistic(
                value: loading
                    ? '—'
                    : 'S/ ${(user?.totalSpent ?? 0).toStringAsFixed(0)}',
                label: 'Gastado',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Statistic(
                value: snapshot.hasData ? '${snapshot.data!.length}' : '—',
                label: 'Favoritos',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Statistic extends StatelessWidget {
  final String value;
  final String label;

  const _Statistic({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class SupportCard extends StatelessWidget {
  final VoidCallback onTap;

  const SupportCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.semantic.successContainer,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _SoftIcon(
                icon: Icons.support_agent_rounded,
                color: context.semantic.success,
                background: context.colors.surface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ayuda y soporte',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Resuelve tus dudas y revisa nuestros canales de atención.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: context.semantic.onSuccessContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: context.semantic.success,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: context.colors.onSurfaceVariant,
      ),
    );
  }
}

class ProfileMenuSection extends StatelessWidget {
  final List<Widget> children;

  const ProfileMenuSection({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(indent: 68, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? trailing;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.danger = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.colors.error : context.colors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _SoftIcon(
                  icon: icon,
                  color: color,
                  background: danger
                      ? context.colors.errorContainer
                      : context.colors.primaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: danger
                              ? context.colors.error
                              : context.colors.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: onTap == null
                          ? context.colors.outlineVariant
                          : context.colors.outline,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? background;

  const _SoftIcon({required this.icon, required this.color, this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 21, color: color),
    );
  }
}

class AppearanceTile extends StatelessWidget {
  const AppearanceTile({super.key});

  Future<void> _showPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                'Tema de la aplicación',
                style: AppTextStyles.sectionTitle,
              ),
            ),
            RadioGroup<ThemeMode>(
              groupValue: ThemeController.instance.mode,
              onChanged: (value) {
                if (value == null) return;
                ThemeController.instance.setMode(value);
                Navigator.pop(sheetContext);
              },
              child: Column(
                children: [
                  for (final mode in ThemeMode.values)
                    RadioListTile<ThemeMode>(
                      value: mode,
                      title: Text(mode.displayName),
                      secondary: Icon(switch (mode) {
                        ThemeMode.system => Icons.brightness_auto_rounded,
                        ThemeMode.light => Icons.light_mode_outlined,
                        ThemeMode.dark => Icons.dark_mode_outlined,
                      }),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) => ProfileMenuItem(
        icon: Icons.palette_outlined,
        title: 'Apariencia',
        subtitle: ThemeController.instance.mode.displayName,
        onTap: () => _showPicker(context),
      ),
    );
  }
}

class BiometricAccessTile extends StatefulWidget {
  const BiometricAccessTile({super.key});

  @override
  State<BiometricAccessTile> createState() => _BiometricAccessTileState();
}

class _BiometricAccessTileState extends State<BiometricAccessTile> {
  bool _available = false;
  bool _enabled = false;
  bool _busy = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await BiometricAuthService.isBiometricAvailable();
    final uid = AuthService.currentUid;
    final enabled =
        uid != null && await BiometricAuthService.hasAccessForUser(uid);
    if (!mounted) return;
    setState(() {
      _available = available;
      _enabled = enabled && available;
      _loaded = true;
    });
  }

  Future<void> _onToggle(bool value) async {
    if (_busy || !_available) return;
    if (value) {
      await _enable();
    } else {
      await _disable();
    }
  }

  Future<void> _enable() async {
    final authUser = AuthService.currentUser;
    if (authUser == null) {
      _showMessage('No hay una sesión activa', error: true);
      return;
    }
    final usesPassword = authUser.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    String? password;
    if (usesPassword) {
      password = await _askPassword();
      if (password == null || password.isEmpty || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final authenticated = await BiometricAuthService.authenticate(
        reason: 'Verifica tu huella para activar el acceso rápido',
      );
      if (!authenticated) return;
      if (usesPassword) {
        final email = authUser.email;
        if (email == null || email.isEmpty) {
          throw const BiometricUnavailableException(
            'Tu cuenta no tiene un correo registrado.',
          );
        }
        await BiometricAuthService.savePasswordCredentials(
          uid: authUser.uid,
          email: email,
          password: password!,
        );
      } else {
        await BiometricAuthService.enableForUser(authUser.uid);
      }
      if (!mounted) return;
      setState(() => _enabled = true);
      _showMessage('Acceso con huella activado');
    } on BiometricUnavailableException catch (error) {
      _showMessage(error.message, error: true);
    } on FirebaseAuthException catch (error) {
      final message = switch (error.code) {
        'wrong-password' ||
        'invalid-credential' => 'La contraseña es incorrecta',
        'too-many-requests' => 'Demasiados intentos. Espera unos minutos',
        _ => 'No se pudo activar el acceso con huella',
      };
      _showMessage(message, error: true);
    } catch (_) {
      _showMessage('No se pudo activar el acceso con huella', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      await BiometricAuthService.clearAccessForUser(uid);
      if (!mounted) return;
      setState(() => _enabled = false);
      _showMessage('Acceso con huella desactivado');
    } catch (_) {
      _showMessage('No se pudo desactivar el acceso con huella', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPassword() async {
    final controller = TextEditingController();
    var hidden = true;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Confirma tu contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Se guardará cifrada en el almacén seguro del dispositivo para habilitar la huella.',
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                obscureText: hidden,
                autofocus: true,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  suffixIcon: IconButton(
                    tooltip: hidden
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: () => setDialogState(() => hidden = !hidden),
                    icon: Icon(
                      hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? context.colors.error
            : context.semantic.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = !_loaded
        ? 'Comprobando disponibilidad...'
        : !_available
        ? 'No disponible en este dispositivo'
        : _enabled
        ? 'Protege la sesión de esta cuenta en el dispositivo'
        : 'Desbloquea tu sesión usando la biometría del dispositivo';

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 76),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _SoftIcon(
              icon: Icons.fingerprint_rounded,
              color: AppColors.primary,
              background: Theme.of(context).colorScheme.primaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Acceso con huella',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_busy || !_loaded)
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(value: _enabled, onChanged: _available ? _onToggle : null),
          ],
        ),
      ),
    );
  }
}
