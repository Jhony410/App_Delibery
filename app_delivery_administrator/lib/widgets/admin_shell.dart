import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes.dart';
import '../theme.dart';

/// Sidebar items (id, label, icon, route, optional badge count provider).
class AdminNavItem {
  final String id;
  final String label;
  final IconData icon;
  final String route;
  final String? badge;

  const AdminNavItem(
      {required this.id,
      required this.label,
      required this.icon,
      required this.route,
      this.badge});
}

const _navItems = <AdminNavItem>[
  AdminNavItem(
      id: 'dashboard',
      label: 'Dashboard',
      icon: Icons.grid_view_rounded,
      route: AdminRoutes.dashboard),
  AdminNavItem(
      id: 'pedidos',
      label: 'Pedidos',
      icon: Icons.inventory_2_outlined,
      route: AdminRoutes.orders),
  AdminNavItem(
      id: 'mapa',
      label: 'Mapa en vivo',
      icon: Icons.map_outlined,
      route: AdminRoutes.liveMap),
  AdminNavItem(
      id: 'comercios',
      label: 'Comercios',
      icon: Icons.storefront_outlined,
      route: AdminRoutes.stores),
  AdminNavItem(
      id: 'repartidores',
      label: 'Repartidores',
      icon: Icons.two_wheeler_outlined,
      route: AdminRoutes.couriers),
  AdminNavItem(
      id: 'aprobaciones',
      label: 'Aprobaciones',
      icon: Icons.verified_outlined,
      route: AdminRoutes.approvals),
  AdminNavItem(
      id: 'clientes',
      label: 'Clientes',
      icon: Icons.people_outline,
      route: AdminRoutes.customers),
  AdminNavItem(
      id: 'finanzas',
      label: 'Finanzas',
      icon: Icons.bar_chart_rounded,
      route: AdminRoutes.finance),
  AdminNavItem(
      id: 'config',
      label: 'Configuración',
      icon: Icons.settings_outlined,
      route: AdminRoutes.zones),
  AdminNavItem(
      id: 'soporte',
      label: 'Soporte',
      icon: Icons.help_outline,
      route: AdminRoutes.support),
];

class AdminShell extends StatelessWidget {
  final String activeId;
  final String title;
  final String? eyebrow;
  final List<Widget>? actions;
  final Widget child;

  const AdminShell({
    super.key,
    required this.activeId,
    required this.title,
    required this.child,
    this.eyebrow = 'RUNA · LIMA · PERÚ',
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(activeId: activeId),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  eyebrow: eyebrow,
                  title: title,
                  actions: actions,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String activeId;
  const _Sidebar({required this.activeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AdminColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AdminColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'R',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.4,
                          ),
                          children: const [
                            TextSpan(text: 'runa'),
                            TextSpan(
                                text: '.',
                                style: TextStyle(
                                    color: AdminColors.primary)),
                          ],
                        ),
                      ),
                      Text(
                        'ADMIN PANEL',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.sidebarText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Search
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom:
                    BorderSide(color: Color(0xFF1C1D21), width: 1),
              ),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AdminColors.sidebarHover,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      size: 14, color: AdminColors.sidebarText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buscar…',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AdminColors.sidebarText,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AdminColors.sidebar,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '⌘K',
                      style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: AdminColors.sidebarText),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Nav
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _navItems.map((item) {
                final active = item.id == activeId;
                return _NavTile(item: item, active: active);
              }).toList(),
            ),
          ),
          // User chip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1C1D21), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AdminColors.primary, Color(0xFFFFAA80)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'JM',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Juan Mendoza',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Super Admin',
                        style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.sidebarText,
                            fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz,
                    size: 16, color: AdminColors.sidebarText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final AdminNavItem item;
  final bool active;
  const _NavTile({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? AdminColors.sidebarHover : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (ModalRoute.of(context)?.settings.name == item.route) return;
            Navigator.pushReplacementNamed(context, item.route);
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 18,
                    color: active
                        ? Colors.white
                        : AdminColors.sidebarText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w500,
                      color: active
                          ? Colors.white
                          : AdminColors.sidebarText,
                    ),
                  ),
                ),
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 20),
                    decoration: BoxDecoration(
                      color: active
                          ? AdminColors.primary
                          : AdminColors.sidebarHover,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.badge!,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
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

class _TopBar extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final List<Widget>? actions;

  const _TopBar({
    required this.title,
    this.eyebrow,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(
          bottom: BorderSide(color: AdminColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AdminColors.textSubtle,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          if (actions != null) ...[
            for (final w in actions!) ...[
              w,
              const SizedBox(width: 10),
            ],
          ],
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: AdminColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.notifications_outlined, size: 18),
                ),
                Positioned(
                  top: 6,
                  right: 7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AdminColors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
