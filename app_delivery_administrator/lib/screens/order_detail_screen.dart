import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../models/store_model.dart';
import '../routes.dart';
import '../services/courier_service.dart';
import '../services/order_service.dart';
import '../services/store_service.dart';
import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/map_location_picker.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel? initial;
  final String? orderId;

  const OrderDetailScreen({super.key, this.initial, this.orderId});

  @override
  Widget build(BuildContext context) {
    final id = initial?.id ?? orderId;
    if (id == null) {
      return _missingArgs(context);
    }
    return StreamBuilder<OrderModel?>(
      stream: OrderService.streamOne(id),
      initialData: initial,
      builder: (context, snap) {
        final order = snap.data;
        if (order == null) {
          return AdminShell(
            activeId: 'pedidos',
            title: 'Pedido',
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('Pedido no encontrado.'),
              ),
            ),
          );
        }
        return _OrderDetailBody(order: order);
      },
    );
  }

  Widget _missingArgs(BuildContext context) => AdminShell(
        activeId: 'pedidos',
        title: 'Pedido',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('No se especificó un pedido.'),
          ),
        ),
      );
}

class _OrderDetailBody extends StatelessWidget {
  final OrderModel order;
  const _OrderDetailBody({required this.order});

  @override
  Widget build(BuildContext context) {
    // Single source of truth for locking the screen. A cancelled order is
    // read-only: no status-changing actions, only deletion.
    final bool isCancelled = order.status == 'cancelado';
    // Reassign only makes sense while the order is still looking for a courier:
    // during the offer rotation ('confirmed') or after it ran out of couriers
    // ('sin_repartidor'). Once a courier accepts ('accepted' and beyond) the
    // order is locked, so the button disappears permanently. Hidden for
    // cancelled orders too. ('searching' kept for any legacy in-flight docs.)
    final bool canReassign = !isCancelled &&
        (order.status == 'confirmed' ||
            order.status == 'sin_repartidor' ||
            order.status == 'searching');
    return AdminShell(
      activeId: 'pedidos',
      title: 'Pedido #${_short(order.id)}',
      actions: [
        if (canReassign)
          AdminButton(
            label: 'Reasignar repartidor',
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm,
            onPressed: () => _reassign(context),
          ),
        if (!isCancelled)
          AdminButton(
            label: 'Cancelar pedido',
            variant: AdminBtnVariant.danger,
            size: AdminBtnSize.sm,
            onPressed: () => OrderService.cancel(order.id),
          ),
        if (isCancelled)
          AdminButton(
            label: 'Eliminar pedido',
            variant: AdminBtnVariant.danger,
            size: AdminBtnSize.sm,
            icon: Icons.delete_outline,
            onPressed: () => _confirmDelete(context),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Breadcrumb(order: order),
          if (isCancelled) ...[
            const SizedBox(height: 12),
            const _CancelledBanner(),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final twoCol = c.maxWidth > 1100;
            final mainCol = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TimelineCard(order: order),
                const SizedBox(height: 16),
                _MapCard(order: order),
                const SizedBox(height: 16),
                _ProductsCard(order: order),
              ],
            );
            final sideCol = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PartyCard(
                  title: 'CLIENTE',
                  name: order.customerName ?? 'Cliente',
                  tone: 'purple',
                  subtitle: order.customerPhone ?? '—',
                  info: [order.address],
                ),
                const SizedBox(height: 16),
                _PartyCard(
                  title: 'COMERCIO',
                  name: order.storeName,
                  tone: 'coral',
                  subtitle: order.storeAddress ?? '—',
                  info: [order.storePhone ?? '—'],
                ),
                const SizedBox(height: 16),
                _CourierSection(order: order),
                const SizedBox(height: 16),
                AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminEyebrow('PAGO'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: const Color(0x336E2BB8),
                                borderRadius: BorderRadius.circular(8)),
                            alignment: Alignment.center,
                            child: Text(
                              _paymentInitial(order.paymentMethod),
                              style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF6E2BB8),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.paymentMethod,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const Text('Confirmado',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: AdminColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
            if (!twoCol) {
              return Column(
                children: [mainCol, const SizedBox(height: 16), sideCol],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: mainCol),
                const SizedBox(width: 16),
                SizedBox(width: 360, child: sideCol),
              ],
            );
          }),
        ],
      ),
    );
  }

  Future<void> _reassign(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await OrderService.reassign(order.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Reasignando… se ofreció al repartidor.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se pudo reasignar el pedido. Intenta de nuevo.'),
          backgroundColor: AdminColors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    // Capture context-bound objects before any async gap.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar pedido?'),
        content: const Text(
            'Esta acción no se puede deshacer. El pedido será eliminado permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(
                    color: AdminColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await OrderService.delete(order.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Pedido eliminado correctamente')),
      );
      navigator.pushReplacementNamed(AdminRoutes.orders);
    } catch (_) {
      // Stay on the detail screen so the admin can retry.
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar el pedido'),
          backgroundColor: AdminColors.red,
        ),
      );
    }
  }

  String _short(String id) =>
      id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  String _paymentInitial(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('yape')) return 'Y';
    if (lower.contains('plin')) return 'P';
    if (lower.contains('efect') || lower.contains('cash')) return 'E';
    if (lower.contains('tarjeta') || lower.contains('card')) return 'T';
    return method.substring(0, 1).toUpperCase();
  }
}

class _Breadcrumb extends StatelessWidget {
  final OrderModel order;
  const _Breadcrumb({required this.order});

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(order.createdAt);
    return Row(
      children: [
        InkWell(
          onTap: () =>
              Navigator.pushReplacementNamed(context, AdminRoutes.orders),
          child: const Text('Pedidos',
              style: TextStyle(
                  fontSize: 12.5, color: AdminColors.textMuted)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right,
              size: 12, color: AdminColors.textMuted),
        ),
        Text(
          '#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}'
              .toUpperCase(),
          style: GoogleFonts.robotoMono(
              fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 10),
        AdminBadge(order.statusLabel, tone: order.statusTone),
        const Spacer(),
        Text(
          'Iniciado a las ${DateFormat('h:mm a').format(order.createdAt)} · ${elapsed.inMinutes} min',
          style:
              const TextStyle(fontSize: 12.5, color: AdminColors.textMuted),
        ),
      ],
    );
  }
}

/// Read-only lock banner shown at the top of a cancelled order's detail.
class _CancelledBanner extends StatelessWidget {
  const _CancelledBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AdminColors.redTint,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AdminColors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16, color: AdminColors.red),
          const SizedBox(width: 10),
          Text('Pedido cancelado · Solo lectura',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.red)),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final OrderModel order;
  const _TimelineCard({required this.order});

  List<_TimelineStep> _build() {
    return [
      _TimelineStep(
        label: 'Pedido recibido',
        time: DateFormat('h:mm a').format(order.createdAt),
        done: true,
      ),
      _TimelineStep(
        label: 'Confirmado por el comercio',
        time: order.acceptedAt == null
            ? '—'
            : DateFormat('h:mm a').format(order.acceptedAt!),
        done: order.acceptedAt != null ||
            ['confirmed', 'preparing', 'accepted', 'picked_up', 'en_camino', 'entregado']
                .contains(order.status),
      ),
      _TimelineStep(
        label: 'Repartidor asignado · ${order.courierName ?? "—"}',
        time: order.acceptedAt == null
            ? '—'
            : DateFormat('h:mm a').format(order.acceptedAt!),
        done: order.courierId != null,
      ),
      _TimelineStep(
        label: 'Recogido del comercio',
        time: order.pickedUpAt == null
            ? '—'
            : DateFormat('h:mm a').format(order.pickedUpAt!),
        done: order.pickedUpAt != null ||
            order.status == 'en_camino' ||
            order.status == 'entregado',
      ),
      _TimelineStep(
        label: 'En camino al cliente',
        time: order.status == 'en_camino' ? 'Ahora' : '—',
        done: order.status == 'en_camino' || order.status == 'entregado',
        active: order.status == 'en_camino',
      ),
      _TimelineStep(
        label: 'Entregado',
        time: order.deliveredAt == null
            ? '—'
            : DateFormat('h:mm a').format(order.deliveredAt!),
        done: order.deliveredAt != null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final steps = _build();
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeline del pedido',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          for (int i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: steps[i].done
                              ? (steps[i].active
                                  ? AdminColors.primary
                                  : AdminColors.green)
                              : Colors.white,
                          border: steps[i].done
                              ? null
                              : Border.all(
                                  color: AdminColors.border, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: steps[i].active
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle))
                            : steps[i].done
                                ? const Icon(Icons.check,
                                    size: 12, color: Colors.white)
                                : null,
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: steps[i].done
                                ? AdminColors.green
                                : AdminColors.border,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: i < steps.length - 1 ? 16 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[i].label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: steps[i].active
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: steps[i].done
                                    ? AdminColors.text
                                    : AdminColors.textMuted,
                              )),
                          const SizedBox(height: 2),
                          Text(
                            steps[i].time,
                            style: GoogleFonts.robotoMono(
                                fontSize: 11.5,
                                color: AdminColors.textMuted),
                          ),
                        ],
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

class _TimelineStep {
  final String label;
  final String time;
  final bool done;
  final bool active;
  _TimelineStep({
    required this.label,
    required this.time,
    required this.done,
    this.active = false,
  });
}

/// Order map. The order document carries NO delivery coordinates (the customer
/// app never writes them), and there is no live courier position, so a route
/// map isn't possible. Instead we show the store's real location when it has
/// coordinates, and always note that delivery coordinates are missing.
class _MapCard extends StatelessWidget {
  final OrderModel order;
  const _MapCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StoreModel?>(
      future: StoreService.get(order.storeId),
      builder: (context, snap) {
        final store = snap.data;
        final hasStoreCoords =
            store?.latitude != null && store?.longitude != null;
        return AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('Ubicación del comercio',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              if (snap.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 170,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (hasStoreCoords)
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: LockedMiniMap(
                    position: LatLng(store!.latitude!, store.longitude!),
                    height: 220,
                  ),
                )
              else
                _NoMapNote(
                  text: 'El comercio "${order.storeName}" no tiene ubicación '
                      'definida en el mapa.',
                ),
              const SizedBox(height: 10),
              const _NoMapNote(
                icon: Icons.info_outline,
                text: 'Este pedido no tiene coordenadas de entrega: la app de '
                    'cliente no las registra, por lo que no se puede trazar la '
                    'ruta hasta el cliente.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NoMapNote extends StatelessWidget {
  final String text;
  final IconData icon;
  const _NoMapNote({required this.text, this.icon = Icons.location_off_outlined});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.grayTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AdminColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AdminColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _ProductsCard extends StatelessWidget {
  final OrderModel order;
  const _ProductsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return AdminCard.flush(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AdminColors.border)),
            ),
            child: Text('Productos (${order.items.length})',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5, fontWeight: FontWeight.w700)),
          ),
          for (int i = 0; i < order.items.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: i < order.items.length - 1
                    ? const Border(
                        bottom: BorderSide(color: AdminColors.border))
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text('${order.items[i].qty}×',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AdminColors.textMuted)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.items[i].name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        if (order.items[i].note != null &&
                            order.items[i].note!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(order.items[i].note!,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AdminColors.textMuted)),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    'S/ ${(order.items[i].price * order.items[i].qty).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AdminColors.bg,
            child: Column(
              children: [
                _summaryRow('Subtotal', 'S/ ${order.subtotal.toStringAsFixed(2)}'),
                _summaryRow('Envío', 'S/ ${order.deliveryFee.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _summaryRow('Total', 'S/ ${order.total.toStringAsFixed(2)}',
                    bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 14 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                  color: bold ? AdminColors.text : AdminColors.textMuted)),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 14 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                  color: bold ? AdminColors.text : AdminColors.textMuted)),
        ],
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  final String title;
  final String name;
  final String tone;
  final String subtitle;
  final List<String> info;

  const _PartyCard({
    required this.title,
    required this.name,
    required this.tone,
    required this.subtitle,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminEyebrow(title),
          const SizedBox(height: 10),
          Row(
            children: [
              AdminAvatar(name: name, size: 36, tone: tone),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11.5,
                            color: AdminColors.textMuted),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in info)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line,
                  style: const TextStyle(
                      fontSize: 12, color: AdminColors.textMuted)),
            ),
        ],
      ),
    );
  }
}

/// Resolves a courier's display name from the live `couriers` collection,
/// falling back to any name already stored on the order. Orders rarely carry a
/// `courierName` (the courier app only writes `courierId`), so the id lookup is
/// the usual path.
Future<String> _resolveCourierName(String? id, String? fallback) async {
  if (fallback != null && fallback.isNotEmpty) return fallback;
  if (id == null) return 'Repartidor';
  final courier = await CourierService.get(id);
  return courier?.name ?? 'Repartidor';
}

/// Real-time REPARTIDOR card driven by the live order document. Mirrors the
/// round-robin dispatch state:
///  • accepted (or beyond) → courier locked in, green check, no reassign
///  • confirmed + assignedCourierId → an offer is outstanding, 15s countdown
///  • confirmed + no assignment → still searching for the first courier
///  • sin_repartidor → no couriers available (admin can retry via Reasignar)
class _CourierSection extends StatelessWidget {
  final OrderModel order;
  const _CourierSection({required this.order});

  bool get _accepted =>
      order.courierId != null ||
      const ['accepted', 'picked_up', 'en_camino', 'entregado']
          .contains(order.status);

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminEyebrow('REPARTIDOR'),
          const SizedBox(height: 12),
          _body(),
        ],
      ),
    );
  }

  Widget _body() {
    if (_accepted) {
      return _AssignedRow(
        name: order.courierName,
        courierId: order.courierId ?? order.assignedCourierId,
      );
    }
    if (order.status == 'sin_repartidor') {
      return const _NoCourierRow();
    }
    if (order.status == 'confirmed' &&
        order.assignedCourierId != null &&
        order.assignmentExpiresAt != null) {
      return _OfferCountdown(
        // Reset the countdown widget whenever the offer rotates to a new
        // courier or a fresh window opens.
        key: ValueKey(
            '${order.assignedCourierId}_${order.assignmentExpiresAt!.millisecondsSinceEpoch}'),
        courierId: order.assignedCourierId!,
        expiresAt: order.assignmentExpiresAt!,
      );
    }
    return const _SearchingRow();
  }
}

class _AssignedRow extends StatelessWidget {
  final String? name;
  final String? courierId;
  const _AssignedRow({required this.name, required this.courierId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _resolveCourierName(courierId, name),
      builder: (context, snap) {
        final resolved = snap.data ?? name ?? 'Repartidor';
        return Row(
          children: [
            AdminAvatar(name: resolved, size: 36, tone: 'green'),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resolved,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  Row(
                    children: const [
                      Icon(Icons.check_circle,
                          size: 13, color: AdminColors.green),
                      SizedBox(width: 4),
                      Text('Asignado',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: AdminColors.green,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchingRow extends StatelessWidget {
  const _SearchingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AdminColors.primary),
        ),
        SizedBox(width: 10),
        Text('Buscando repartidor…',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AdminColors.textMuted)),
      ],
    );
  }
}

class _NoCourierRow extends StatelessWidget {
  const _NoCourierRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.redTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_off_outlined,
              size: 16, color: AdminColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Sin repartidores disponibles',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.red)),
          ),
        ],
      ),
    );
  }
}

/// The 30s offer countdown shown while a single courier is being offered the
/// order. Counts down from `assignmentExpiresAt` (server-driven, so it stays in
/// sync) and depletes a progress bar; at zero it flips to a "buscando
/// siguiente…" state while the Cloud Function rotates to the next courier
/// (continuous round-robin — it never gives up while couriers are online).
class _OfferCountdown extends StatefulWidget {
  final String courierId;
  final DateTime expiresAt;
  const _OfferCountdown({
    super.key,
    required this.courierId,
    required this.expiresAt,
  });

  @override
  State<_OfferCountdown> createState() => _OfferCountdownState();
}

class _OfferCountdownState extends State<_OfferCountdown> {
  static const _window = 30;
  Timer? _timer;
  late int _secondsLeft;
  String? _name;

  int _remaining() {
    final diff = widget.expiresAt.difference(DateTime.now()).inMilliseconds;
    return (diff / 1000).ceil().clamp(0, _window);
  }

  @override
  void initState() {
    super.initState();
    _secondsLeft = _remaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft = _remaining());
      if (_secondsLeft <= 0) t.cancel();
    });
    _loadName();
  }

  Future<void> _loadName() async {
    final courier = await CourierService.get(widget.courierId);
    if (mounted) setState(() => _name = courier?.name);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _secondsLeft <= 0;
    final progress = (_secondsLeft / _window).clamp(0.0, 1.0);
    final name = _name ?? 'Repartidor';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AdminAvatar(name: name, size: 36, tone: 'amber'),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  Text(
                    expired
                        ? 'No respondió · buscando siguiente…'
                        : 'Oferta enviada',
                    style: TextStyle(
                        fontSize: 11.5,
                        color:
                            expired ? AdminColors.textMuted : AdminColors.primary,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!expired)
              Text('Expira en ${_secondsLeft}s',
                  style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.primary)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            // Indeterminate (animated) once expired, signalling the rotation.
            value: expired ? null : progress,
            minHeight: 6,
            backgroundColor: AdminColors.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AdminColors.primary),
          ),
        ),
      ],
    );
  }
}
