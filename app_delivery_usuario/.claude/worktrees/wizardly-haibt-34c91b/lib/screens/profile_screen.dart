import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<UserModel?> _future;

  static const _menuItems = [
    _MenuItem(Icons.location_on_outlined, 'Mis direcciones', '3 guardadas', false),
    _MenuItem(Icons.credit_card, 'Métodos de pago', 'Yape, Visa •4821', false),
    _MenuItem(Icons.notifications_none, 'Notificaciones', 'Activadas', false),
    _MenuItem(Icons.favorite_border, 'Favoritos', '12 comercios', false),
    _MenuItem(Icons.help_outline, 'Ayuda y soporte', null, false),
    _MenuItem(Icons.logout, 'Cerrar sesión', null, true),
  ];

  @override
  void initState() {
    super.initState();
    final uid = AuthService.currentUid;
    _future = uid != null ? DbService.getUser(uid) : Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FutureBuilder<UserModel?>(
        future: _future,
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
                Padding(
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.edit_outlined, size: 18),
                      ),
                    ],
                  ),
                ),
                Padding(
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
                                    snap.connectionState ==
                                            ConnectionState.waiting
                                        ? 'Cargando...'
                                        : (user?.name ?? 'Usuario'),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.36),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    user != null
                                        ? '${user.email} · ${user.phone}'
                                        : '',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.22),
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
                ),
                Padding(
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
                      _StatCard(
                          user != null
                              ? user.rating.toStringAsFixed(1)
                              : '5.0',
                          'Rating'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          children: _menuItems.asMap().entries.map((e) {
                            final it = e.value;
                            final isLast = e.key == _menuItems.length - 1;
                            return GestureDetector(
                              onTap: it.isDanger
                                  ? () async {
                                      await AuthService.signOut();
                                      if (context.mounted) {
                                        Navigator.pushReplacementNamed(
                                            context, '/login');
                                      }
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isLast
                                          ? Colors.transparent
                                          : AppColors.border,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: it.isDanger
                                            ? const Color(0xFFFDECEC)
                                            : AppColors.bg,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(it.icon,
                                          size: 18,
                                          color: it.isDanger
                                              ? AppColors.danger
                                              : AppColors.appText),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(it.label,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: it.isDanger
                                                      ? AppColors.danger
                                                      : AppColors.appText)),
                                          if (it.desc != null) ...[
                                            const SizedBox(height: 2),
                                            Text(it.desc!,
                                                style: const TextStyle(
                                                    fontSize: 11.5,
                                                    color: AppColors.textMuted)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (!it.isDanger)
                                      const Icon(Icons.chevron_right,
                                          size: 18,
                                          color: AppColors.textSubtle),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('DeliPuno · v1.0.0',
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: AppColors.textSubtle,
                              letterSpacing: 0.06)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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

class _MenuItem {
  final IconData icon;
  final String label;
  final String? desc;
  final bool isDanger;
  const _MenuItem(this.icon, this.label, this.desc, this.isDanger);
}
