import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../models/address_model.dart';
import '../models/favorite_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import 'addresses_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Versión de la app. package_info_plus no está en las dependencias del
  // proyecto, así que se mantiene fija (debe coincidir con pubspec.yaml).
  static const _appVersion = 'v1.0.0';

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUid;
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: uid == null
          ? const Center(
              child: Text('Inicia sesión para ver tu perfil',
                  style: TextStyle(color: AppColors.textMuted)))
          : StreamBuilder<UserModel?>(
              stream: DbService.streamUser(uid),
              builder: (context, snap) {
                final user = snap.data;
                final initials = user != null
                    ? user.name
                        .split(' ')
                        .take(2)
                        .map((w) => w.isNotEmpty ? w[0] : '')
                        .join()
                        .toUpperCase()
                    : '?';

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: top + 8),
                      _buildHeaderBar(context, user),
                      _buildProfileCard(user, initials,
                          snap.connectionState == ConnectionState.waiting),
                      _buildStats(uid, user),
                      _buildMenu(context, uid),
                      const SizedBox(height: 14),
                      Text('DeliPuno · $_appVersion',
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: AppColors.textSubtle,
                              letterSpacing: 0.06)),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHeaderBar(BuildContext context, UserModel? user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text('Mi perfil',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.34)),
          ),
          GestureDetector(
            onTap: user == null
                ? null
                : () => _showEditDialog(context, user),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.edit_outlined, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserModel? user, String initials, bool loading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFFFF8F5B)],
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loading ? 'Cargando...' : (user?.name ?? 'Usuario'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.36),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user != null ? '${user.email} · ${user.phone}' : '',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user != null
                              ? '★ MIEMBRO DESDE ${user.memberSince.year}'
                              : '★ MIEMBRO',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.04),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(String uid, UserModel? user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          _StatCard('${user?.totalOrders ?? 0}', 'Pedidos'),
          const SizedBox(width: 10),
          _StatCard(
              user != null
                  ? 'S/ ${user.totalSpent.toStringAsFixed(0)}'
                  : 'S/ 0',
              'Gastado'),
          const SizedBox(width: 10),
          // Tercera tarjeta: "Favoritos" con conteo real. Reemplaza el rating
          // fijo de 5.0 que nadie escribe en users/{uid}.
          StreamBuilder<List<FavoriteModel>>(
            stream: DbService.streamUserFavorites(uid),
            builder: (context, snap) =>
                _StatCard('${snap.data?.length ?? 0}', 'Favoritos'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context, String uid) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            _MenuRow(
              icon: Icons.location_on_outlined,
              label: 'Mis direcciones',
              onTap: () => Navigator.pushNamed(context, '/addresses',
                  arguments: AddressListMode.manage),
              subtitle: FutureBuilder<List<AddressModel>>(
                future: DbService.getUserAddresses(uid),
                builder: (context, snap) {
                  final n = snap.data?.length;
                  if (n == null || n == 0) return const SizedBox.shrink();
                  return _sub('$n guardada${n == 1 ? '' : 's'}');
                },
              ),
            ),
            _MenuRow(
              icon: Icons.credit_card,
              label: 'Métodos de pago',
              onTap: () => Navigator.pushNamed(context, '/payment'),
            ),
            _MenuRow(
              icon: Icons.notifications_none,
              label: 'Notificaciones',
              onTap: () => Navigator.pushNamed(context, '/notifications'),
              subtitle: StreamBuilder<int>(
                stream: DbService.countUnreadNotifications(uid),
                builder: (context, snap) {
                  final n = snap.data ?? 0;
                  if (n == 0) return const SizedBox.shrink();
                  return _sub('$n sin leer');
                },
              ),
            ),
            _MenuRow(
              icon: Icons.favorite_border,
              label: 'Favoritos',
              onTap: () => Navigator.pushNamed(context, '/favorites'),
              subtitle: StreamBuilder<List<FavoriteModel>>(
                stream: DbService.streamUserFavorites(uid),
                builder: (context, snap) {
                  final n = snap.data?.length;
                  if (n == null || n == 0) return const SizedBox.shrink();
                  return _sub('$n comercio${n == 1 ? '' : 's'}');
                },
              ),
            ),
            _MenuRow(
              icon: Icons.help_outline,
              label: 'Ayuda y soporte',
              onTap: () => Navigator.pushNamed(context, '/help'),
            ),
            _MenuRow(
              icon: Icons.logout,
              label: 'Cerrar sesión',
              isDanger: true,
              isLast: true,
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sub(String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11.5, color: AppColors.textMuted)),
      );

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _showEditDialog(BuildContext context, UserModel user) async {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar perfil'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa tu nombre'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa tu teléfono'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                try {
                  await DbService.updateUser(user.uid, {
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Perfil actualizado'),
                      backgroundColor: AppColors.secondary,
                    ));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('No se pudo actualizar el perfil'),
                      backgroundColor: AppColors.danger,
                    ));
                  }
                }
              },
              child: const Text('Guardar',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? subtitle;
  final bool isDanger;
  final bool isLast;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.isDanger = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : AppColors.border,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDanger ? const Color(0xFFFDECEC) : AppColors.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18,
                  color: isDanger ? AppColors.danger : AppColors.appText),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isDanger ? AppColors.danger : AppColors.appText)),
                  ?subtitle,
                ],
              ),
            ),
            if (!isDanger)
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }
}
