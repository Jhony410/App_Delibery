import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/store_model.dart';
import '../routes.dart';
import '../services/store_service.dart';
import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'comercios',
      title: 'Comercios',
      actions: const [
        AdminButton(
            label: 'Exportar',
            icon: Icons.file_download_outlined,
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
        AdminButton(
            label: 'Agregar comercio',
            icon: Icons.add,
            size: AdminBtnSize.sm),
      ],
      child: StreamBuilder<List<StoreModel>>(
        stream: StoreService.streamAll(),
        builder: (context, snap) {
          final stores = snap.data ?? const <StoreModel>[];
          final active = stores.where((s) => s.isOpen).length;
          final paused = stores.length - active;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MetricsRow(metrics: [
                ('Total comercios', '${stores.length}', '+3 hoy'),
                ('Activos', '$active', stores.isEmpty ? '—' : '${(active / stores.length * 100).toStringAsFixed(1)}%'),
                ('Pausados', '$paused', stores.isEmpty ? '—' : '${(paused / stores.length * 100).toStringAsFixed(1)}%'),
                ('Pendientes alta', '0', 'Revisar'),
              ]),
              const SizedBox(height: 16),
              _StoresFilters(),
              const SizedBox(height: 0),
              _StoresTable(stores: stores),
            ],
          );
        },
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final List<(String, String, String)> metrics;
  const _MetricsRow({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 1100 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 3.6,
        children: metrics
            .map((m) => AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.$1,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AdminColors.textMuted,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(m.$2,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4)),
                      const SizedBox(height: 2),
                      Text(m.$3,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AdminColors.textMuted,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ))
            .toList(),
      );
    });
  }
}

class _StoresFilters extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminCard.flush(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: const [
            Expanded(
              child: AdminFakeField(
                  icon: Icons.search,
                  text: 'Buscar comercio…',
                  width: double.infinity),
            ),
            SizedBox(width: 10),
            AdminFakeField(
                text: 'Categoría',
                trailing: Icons.expand_more,
                width: 130),
            SizedBox(width: 10),
            AdminFakeField(
                text: 'Estado',
                trailing: Icons.expand_more,
                width: 110),
            SizedBox(width: 10),
            AdminFakeField(
                text: 'Distrito',
                trailing: Icons.expand_more,
                width: 110),
          ],
        ),
      ),
    );
  }
}

class _StoresTable extends StatelessWidget {
  final List<StoreModel> stores;
  const _StoresTable({required this.stores});

  @override
  Widget build(BuildContext context) {
    return AdminCard.flush(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AdminColors.bg,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: const [
                _Th('Comercio', flex: 4),
                _Th('Categoría', flex: 3),
                _Th('Estado', flex: 2),
                _Th('Ventas mes (S/)',
                    flex: 2, align: TextAlign.right),
                _Th('Comisión', flex: 2, align: TextAlign.right),
                _Th('Rating', flex: 2, align: TextAlign.right),
              ],
            ),
          ),
          if (stores.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Aún no hay comercios.',
                  style:
                      TextStyle(fontSize: 13, color: AdminColors.textMuted),
                ),
              ),
            )
          else
            for (int i = 0; i < stores.length; i++)
              _StoreRow(store: stores[i], index: i),
        ],
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  final StoreModel store;
  final int index;
  const _StoreRow({required this.store, required this.index});

  @override
  Widget build(BuildContext context) {
    const tints = [
      Color(0xFFFFE8DB),
      Color(0xFFDFF0E7),
      Color(0xFFE0E7FA),
      Color(0xFFEFDEF5),
      Color(0xFFFEF3C7),
    ];
    final tint = tints[index % tints.length];
    final isActive = store.isOpen;
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AdminRoutes.storeDetail,
          arguments: store),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: index == 0
              ? null
              : const Border(
                  top: BorderSide(color: AdminColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      store.name.isEmpty ? '?' : store.name[0],
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AdminColors.text),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        Text(store.district ?? store.address,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AdminColors.textMuted),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                store.category,
                style: const TextStyle(
                    fontSize: 13, color: AdminColors.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AdminBadge(
                  isActive ? 'Activo' : 'Pausado',
                  tone: isActive ? 'green' : 'amber',
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                store.monthSales == null
                    ? '—'
                    : store.monthSales!.toStringAsFixed(0),
                textAlign: TextAlign.right,
                style: GoogleFonts.robotoMono(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${(store.commissionPct ?? 18).toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.star,
                      size: 13, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(store.rating.toStringAsFixed(1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;
  const _Th(this.label,
      {required this.flex, this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        textAlign: align,
        style: const TextStyle(
            fontSize: 11,
            color: AdminColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6),
      ),
    );
  }
}
