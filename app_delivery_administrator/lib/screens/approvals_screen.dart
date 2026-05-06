import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/courier_model.dart';
import '../services/courier_service.dart';
import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  CourierModel? _selected;

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'aprobaciones',
      title: 'Aprobaciones de repartidores',
      actions: const [
        AdminBadge('8 pendientes', tone: 'amber'),
        SizedBox(width: 8),
        AdminButton(
            label: 'Política de aprobación',
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
      ],
      child: StreamBuilder<List<CourierModel>>(
        stream: CourierService.streamPendingApproval(),
        builder: (context, snap) {
          final pending = snap.data ?? const <CourierModel>[];
          final selected = _selected ?? (pending.isNotEmpty ? pending.first : null);
          return SizedBox(
            height: 760,
            child: LayoutBuilder(builder: (context, c) {
              final twoCol = c.maxWidth > 1100;
              final list = SizedBox(
                width: twoCol ? 380 : double.infinity,
                child: _PendingList(
                  pending: pending,
                  selectedUid: selected?.uid,
                  onSelect: (c) => setState(() => _selected = c),
                ),
              );
              if (selected == null) {
                return Center(
                  child: Text(
                      'No hay solicitudes pendientes en este momento.',
                      style: GoogleFonts.plusJakartaSans(
                          color: AdminColors.textMuted)),
                );
              }
              if (!twoCol) return list;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  list,
                  const SizedBox(width: 20),
                  Expanded(child: _DetailPane(courier: selected)),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  final List<CourierModel> pending;
  final String? selectedUid;
  final ValueChanged<CourierModel> onSelect;
  const _PendingList(
      {required this.pending,
      required this.selectedUid,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return AdminCard.flush(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AdminColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cola de aprobación',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text('${pending.length}',
                    style: const TextStyle(
                        color: AdminColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: pending.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No hay postulaciones pendientes.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.textMuted, fontSize: 12.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: pending.length,
                    itemBuilder: (context, i) {
                      final p = pending[i];
                      final isSelected = p.uid == selectedUid;
                      return InkWell(
                        onTap: () => onSelect(p),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AdminColors.bg
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: i < pending.length - 1
                                    ? AdminColors.border
                                    : Colors.transparent,
                              ),
                              left: BorderSide(
                                width: 3,
                                color: isSelected
                                    ? AdminColors.primary
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AdminAvatar(name: p.name, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${p.vehicleModel.isEmpty ? "Vehículo" : p.vehicleModel} · ${p.district ?? "—"}',
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AdminColors.textMuted),
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    const AdminBadge(
                                        'Listo para revisar',
                                        tone: 'blue'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailPane extends StatelessWidget {
  final CourierModel courier;
  const _DetailPane({required this.courier});

  @override
  Widget build(BuildContext context) {
    return AdminCard.flush(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                children: [
                  AdminAvatar(name: courier.name, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(courier.name,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4)),
                        const SizedBox(height: 2),
                        Text('DNI ${courier.dni} · Postuló hace 12 min',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AdminColors.textMuted)),
                      ],
                    ),
                  ),
                  AdminButton(
                    label: 'Rechazar',
                    icon: Icons.close,
                    variant: AdminBtnVariant.danger,
                    onPressed: () =>
                        CourierService.reject(courier.uid),
                  ),
                  const SizedBox(width: 8),
                  AdminButton(
                    label: 'Aprobar',
                    icon: Icons.check,
                    variant: AdminBtnVariant.success,
                    onPressed: () =>
                        CourierService.approve(courier.uid),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos personales',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _DataGrid(courier: courier),
                  const SizedBox(height: 24),
                  Text('Documentos cargados (6)',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const _DocumentsGrid(),
                  const SizedBox(height: 24),
                  Text('Verificaciones automáticas',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const _VerificationsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataGrid extends StatelessWidget {
  final CourierModel courier;
  const _DataGrid({required this.courier});

  @override
  Widget build(BuildContext context) {
    final fields = [
      ('NOMBRE', courier.name),
      ('DNI', courier.dni),
      ('TELÉFONO', courier.phone),
      ('EMAIL', courier.email),
      ('DISTRITO', courier.district ?? '—'),
      ('VEHÍCULO',
          '${courier.vehicleModel} · ${courier.vehiclePlate}'.trim()),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 700 ? 3 : 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: fields.map((f) {
          return SizedBox(
            width: (c.maxWidth - 12 * (cols - 1)) / cols,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.$1,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: AdminColors.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4)),
                const SizedBox(height: 4),
                Text(f.$2.isEmpty ? '—' : f.$2,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}

class _DocumentsGrid extends StatelessWidget {
  const _DocumentsGrid();
  static const _docs = [
    ('DNI anverso', 'IMAGE'),
    ('DNI reverso', 'IMAGE'),
    ('Brevete A-IIa', 'IMAGE'),
    ('SOAT vigente', 'PDF'),
    ('Tarjeta propiedad', 'PDF'),
    ('Antecedentes', 'PDF'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 700 ? 3 : 2;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.0,
        children: _docs
            .map((d) => Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: AdminColors.border),
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: d.$2 == 'IMAGE'
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFE0E7FA),
                                      Color(0xFFDBEAFE)
                                    ],
                                  )
                                : null,
                            color: d.$2 == 'PDF'
                                ? AdminColors.bg
                                : null,
                          ),
                          child: Stack(
                            children: [
                              const Center(
                                child: Icon(
                                    Icons.description_outlined,
                                    size: 36,
                                    color: AdminColors.textSubtle),
                              ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(3)),
                                  child: Text(d.$2,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(d.$1,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const Icon(Icons.visibility_outlined,
                                size: 14,
                                color: AdminColors.textMuted),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );
    });
  }
}

class _VerificationsList extends StatelessWidget {
  const _VerificationsList();
  static const _items = [
    ('DNI verificado en RENIEC', 'green', 'Coincide con la foto'),
    ('Brevete vigente en MTC', 'green',
        'Categoría A-IIa · Vence 2027'),
    ('Antecedentes penales', 'green', 'Sin registro'),
    ('Detección de duplicados', 'green',
        'No se encuentra otro perfil con este DNI'),
    ('Validación de SOAT', 'amber',
        'Por vencer en 7 meses · Recordatorio activado'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final v in _items)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: AdminColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: v.$2 == 'green'
                        ? AdminColors.greenTint
                        : AdminColors.amberTint,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    v.$2 == 'green'
                        ? Icons.check_rounded
                        : Icons.help_outline,
                    size: 14,
                    color: v.$2 == 'green'
                        ? AdminColors.green
                        : AdminColors.amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.$1,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 1),
                      Text(v.$3,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AdminColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
