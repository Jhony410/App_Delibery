import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  static const _users = [
    ('Andrea Solís', 'andrea@runa.pe', 'Super Admin', 'purple', 'Hace 2 min'),
    ('Rafael Chávez', 'rafael@runa.pe', 'Operaciones', 'blue', 'Hace 14 min'),
    ('Lucía Ferrer', 'lucia@runa.pe', 'Finanzas', 'green', 'Hace 1h'),
    ('Manuel Aguirre', 'manuel@runa.pe', 'Soporte', 'amber', 'Hace 3h'),
    ('Verónica Ríos', 'veronica@runa.pe', 'Comercios', 'coral', 'Ayer'),
    ('Tomás Loayza', 'tomas@runa.pe', 'Repartidores', 'blue', 'Ayer'),
    ('Inés Bardales', 'ines@runa.pe', 'Solo lectura', 'gray', 'Hace 3 días'),
  ];

  static const _roles = [
    ('Super Admin', 'Acceso total al sistema', 2, [
      'Pedidos', 'Comercios', 'Repartidores', 'Clientes',
      'Finanzas', 'Configuración', 'Soporte', 'Usuarios admin'
    ]),
    ('Operaciones', 'Gestión diaria de pedidos y repartidores', 4, [
      'Pedidos', 'Repartidores', 'Soporte'
    ]),
    ('Finanzas', 'Reportes y pagos', 1,
        ['Finanzas', 'Pedidos (lectura)']),
    ('Soporte', 'Atención al cliente', 8,
        ['Soporte', 'Pedidos (lectura)', 'Clientes (lectura)']),
    ('Comercios', 'Gestión de partners', 3,
        ['Comercios', 'Pedidos (lectura)']),
    ('Solo lectura', 'Auditoría', 2, ['Todo (lectura)']),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'config',
      title: 'Usuarios y permisos',
      actions: const [
        AdminButton(
            label: 'Auditoría',
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
        AdminButton(
            label: 'Invitar usuario',
            icon: Icons.add,
            size: AdminBtnSize.sm),
      ],
      child: LayoutBuilder(builder: (context, c) {
        final twoCol = c.maxWidth > 1200;
        final left = AdminCard.flush(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: AdminColors.border)),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Equipo administrador',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    Text('${_users.length} personas',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AdminColors.textMuted)),
                  ],
                ),
              ),
              Container(
                color: AdminColors.bg,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: const [
                    _Th('Usuario', flex: 4),
                    _Th('Rol', flex: 3),
                    _Th('Última actividad', flex: 3),
                  ],
                ),
              ),
              for (int i = 0; i < _users.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(
                            top: BorderSide(
                                color: AdminColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            AdminAvatar(
                              name: _users[i].$1,
                              size: 32,
                              tone: const [
                                'coral',
                                'blue',
                                'green',
                                'purple',
                                'amber'
                              ][i % 5],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(_users[i].$1,
                                      style: const TextStyle(
                                          fontWeight:
                                              FontWeight.w600),
                                      overflow:
                                          TextOverflow.ellipsis),
                                  Text(_users[i].$2,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AdminColors
                                              .textMuted),
                                      overflow:
                                          TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AdminBadge(_users[i].$3,
                              tone: _users[i].$4),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(_users[i].$5,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AdminColors.textMuted)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
        final right = AdminCard.flush(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: AdminColors.border)),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Roles configurados',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const AdminButton(
                        label: 'Crear rol',
                        icon: Icons.add,
                        variant: AdminBtnVariant.ghost,
                        size: AdminBtnSize.sm),
                  ],
                ),
              ),
              for (int i = 0; i < _roles.length; i++)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(
                            top: BorderSide(
                                color: AdminColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(_roles[i].$1,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight:
                                            FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(
                                  '${_roles[i].$2} · ${_roles[i].$3} usuario${_roles[i].$3 != 1 ? "s" : ""}',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AdminColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_outlined,
                              size: 14,
                              color: AdminColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: _roles[i].$4
                            .map((p) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AdminColors.bg,
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text(p,
                                      style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AdminColors
                                              .textMuted,
                                          fontWeight:
                                              FontWeight.w600)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
        if (!twoCol) {
          return Column(
              children: [left, const SizedBox(height: 20), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 20),
            Expanded(child: right),
          ],
        );
      }),
    );
  }
}

class _Th extends StatelessWidget {
  final String label;
  final int flex;
  const _Th(this.label, {required this.flex});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              color: AdminColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6)),
    );
  }
}
