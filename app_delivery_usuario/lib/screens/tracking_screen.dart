import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/order_model.dart';
import '../services/db_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  static const _steps = ['Recibido', 'Preparando', 'En camino', 'Entregado'];

  String? _orderId;
  Stream<OrderModel?>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id != null && id != _orderId) {
      _orderId = id;
      _stream = DbService.streamOrder(id);
    }
  }

  // Maps the shared order status (which the courier app also writes) onto the
  // 4 visual steps: Recibido · Preparando · En camino · Entregado.
  int _activeStep(String status) => switch (status) {
        'confirmed' => 0,
        'preparing' => 1,
        'accepted' => 1, // courier assigned, food still being prepared
        'picked_up' => 2, // courier has the order, heading out
        'en_camino' => 2,
        'entregado' => 3,
        _ => 0,
      };

  String _etaLabel(String status) => switch (status) {
        'confirmed' => 'Pedido recibido',
        'preparing' => 'Preparando tu pedido',
        'accepted' => 'Repartidor asignado',
        'picked_up' => 'Pedido recogido',
        'en_camino' => 'En camino · aprox. 12 min',
        'entregado' => '¡Entregado!',
        _ => 'Procesando...',
      };

  @override
  Widget build(BuildContext context) {
    if (_stream == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton()),
        body: const Center(child: Text('Pedido no encontrado')),
      );
    }

    return StreamBuilder<OrderModel?>(
      stream: _stream,
      builder: (context, snap) {
        final order = snap.data;
        final status = order?.status ?? 'confirmed';
        final active = _activeStep(status);
        final isDelivered = status == 'entregado';
        final shortId = (_orderId ?? '').length > 6
            ? _orderId!.substring(_orderId!.length - 6).toUpperCase()
            : (_orderId ?? '------').toUpperCase();

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // ── Mapa ───────────────────────────────────────────
              SizedBox(
                height: 340,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 340),
                      painter: _TrackingMapPainter(active: active),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 20,
                      child: _CircleBtn(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.chevron_left, size: 22),
                      ),
                    ),
                    // Pin tienda
                    const Positioned(
                      left: 48,
                      top: 60,
                      child: _MapPin(isStore: true,
                          child: Icon(Icons.restaurant, size: 17, color: AppColors.primary)),
                    ),
                    // Pin casa
                    const Positioned(
                      left: 248,
                      top: 268,
                      child: _MapPin(isStore: false,
                          child: Icon(Icons.home, size: 17, color: Colors.white)),
                    ),
                    // Repartidor
                    Positioned(
                      left: _driverLeft(active),
                      top: _driverTop(active),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.18),
                            ),
                          ),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDelivered
                                  ? AppColors.secondary
                                  : AppColors.primary,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDelivered
                                          ? AppColors.secondary
                                          : AppColors.primary)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              isDelivered ? Icons.check : Icons.motorcycle,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Panel inferior ─────────────────────────────────
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        20, 10, 20, 20 + MediaQuery.of(context).padding.bottom),
                    child: Column(
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),

                        // ETA + #pedido
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            snap.connectionState == ConnectionState.waiting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary))
                                : Text(
                                    _etaLabel(status),
                                    style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4),
                                  ),
                            Text('#RN-$shortId',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (order != null) ...[
                          const SizedBox(height: 2),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(order.storeName,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted)),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Barra de progreso
                        Row(
                          children: List.generate(_steps.length, (i) => Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: i < _steps.length - 1 ? 6 : 0),
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: i <= active
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                          )),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: _steps.asMap().entries.map((e) {
                            final isActive = e.key == active;
                            final isLast = e.key == _steps.length - 1;
                            return Expanded(
                              child: Text(e.value,
                                  textAlign: e.key == 0
                                      ? TextAlign.left
                                      : isLast
                                          ? TextAlign.right
                                          : TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: isActive
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: e.key <= active
                                          ? AppColors.appText
                                          : AppColors.textSubtle)),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Banner de estado activo / entregado
                        if (isDelivered)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryTint,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle,
                                    size: 18, color: AppColors.secondary),
                                SizedBox(width: 8),
                                Text('¡Tu pedido fue entregado!',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary)),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary),
                                ),
                                SizedBox(width: 10),
                                Text('Simulando entrega en tiempo real...',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary)),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Repartidor card — bound to couriers/{courierId} in
                        // real time; placeholder until a courier is locked in.
                        // Mirrors the admin panel: a courier is considered
                        // assigned once they accept (courierId set) OR the order
                        // has progressed past acceptance. We resolve the id from
                        // courierId, falling back to the round-robin
                        // assignedCourierId so legacy/edge orders still show the
                        // driver instead of "Buscando repartidor".
                        Builder(builder: (context) {
                          final hasCourier = order != null &&
                              (order.courierId != null ||
                                  const [
                                    'accepted',
                                    'picked_up',
                                    'en_camino',
                                    'entregado',
                                  ].contains(order.status));
                          final courierId =
                              order?.courierId ?? order?.assignedCourierId;
                          if (!hasCourier || courierId == null) {
                            return const _CourierCard(
                                courier: null, assigned: false);
                          }
                          return StreamBuilder<CourierInfo?>(
                            stream: DbService.streamCourier(courierId),
                            builder: (context, cs) => _CourierCard(
                              courier: cs.data,
                              assigned: true,
                              orderId: order.id,
                            ),
                          );
                        }),

                        // Resumen del pedido
                        if (order != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Resumen del pedido',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(order.statusLabel,
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: _statusColor(status))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ...order.items.map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: AppColors.bg,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Center(
                                              child: Text('${item.qty}',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: AppColors.textMuted)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                              child: Text(item.name,
                                                  style: const TextStyle(
                                                      fontSize: 13))),
                                          Text(
                                              'S/ ${item.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    )),
                                const Divider(color: AppColors.border, height: 18),
                                _SummaryRow('Subtotal',
                                    'S/ ${order.subtotal.toStringAsFixed(2)}'),
                                const SizedBox(height: 4),
                                _SummaryRow('Envío',
                                    'S/ ${order.deliveryFee.toStringAsFixed(2)}'),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800)),
                                    Text('S/ ${order.total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary)),
                                  ],
                                ),
                                if (order.observation != null) ...[
                                  const Divider(
                                      color: AppColors.border, height: 18),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.comment_outlined,
                                          size: 14,
                                          color: AppColors.textMuted),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(order.observation!,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted,
                                                height: 1.45)),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String status) => switch (status) {
        'entregado' => AppColors.secondary,
        'cancelado' => AppColors.danger,
        _ => AppColors.primary,
      };

  // Posición animada del repartidor según el paso
  double _driverLeft(int step) => switch (step) {
        0 => 62.0,
        1 => 100.0,
        2 => 150.0,
        3 => 245.0,
        _ => 62.0,
      };

  double _driverTop(int step) => switch (step) {
        0 => 74.0,
        1 => 120.0,
        2 => 168.0,
        3 => 270.0,
        _ => 74.0,
      };
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

class _CircleBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _CircleBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: child,
        ),
      );
}

class _MapPin extends StatelessWidget {
  final bool isStore;
  final Widget child;
  const _MapPin({required this.isStore, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isStore ? Colors.white : AppColors.appText,
          border: isStore
              ? Border.all(color: AppColors.primary, width: 2.5)
              : null,
        ),
        child: child,
      );
}

class _CourierCard extends StatelessWidget {
  final CourierInfo? courier;
  final bool assigned; // the order already has a courierId
  final String? orderId;
  const _CourierCard({
    required this.courier,
    required this.assigned,
    this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final c = courier;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD0B0),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: !assigned
                  ? const Icon(Icons.person_search,
                      size: 22, color: AppColors.primary)
                  : c == null
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        )
                      : Text(c.initials,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !assigned
                      ? 'Buscando repartidor...'
                      : (c?.name.isNotEmpty == true ? c!.name : 'Repartidor'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                if (assigned && c != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.motorcycle, size: 13),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          c.vehicleModel.isEmpty
                              ? 'Vehículo'
                              : c.vehicleModel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                      if (c.vehiclePlate.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(c.vehiclePlate,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '★ ${c.rating.toStringAsFixed(1)} · ${c.totalDeliveries} entregas',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary),
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  const Text('Te asignaremos uno en breve',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          if (assigned && c != null)
            Row(
              children: [
                GestureDetector(
                  onTap: orderId == null
                      ? null
                      : () => Navigator.pushNamed(context, '/chat',
                          arguments: orderId),
                  child: _ActionBtn(
                    color: Colors.white,
                    borderColor: AppColors.border,
                    child: const Icon(Icons.chat_bubble_outline, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  color: AppColors.secondary,
                  child:
                      const Icon(Icons.phone, size: 20, color: Colors.white),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final Color color;
  final Color? borderColor;
  final Widget child;
  const _ActionBtn({required this.color, this.borderColor, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
        ),
        child: child,
      );
}

class _TrackingMapPainter extends CustomPainter {
  final int active;
  const _TrackingMapPainter({required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 375;
    final sy = size.height / 340;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFDDE7EC));
    final block = Paint()..color = const Color(0xFFE8EEF2);
    void rect(double x, double y, double w, double h) => canvas.drawRect(
        Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy), block);
    rect(0, 0, 160, 100);
    rect(180, 0, 195, 100);
    rect(0, 125, 90, 110);
    rect(110, 125, 180, 110);
    rect(310, 125, 65, 110);
    rect(0, 260, 160, 80);
    rect(180, 260, 195, 80);
    final road = Paint()..color = Colors.white;
    void rroad(double x, double y, double w, double h) => canvas.drawRect(
        Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy), road);
    rroad(0, 105, 375, 14);
    rroad(0, 242, 375, 14);
    rroad(160, 0, 18, 340);
    rroad(90, 125, 16, 110);

    final routePath = Path()
      ..moveTo(65 * sx, 77 * sy)
      ..quadraticBezierTo(110 * sx, 95 * sy, 168 * sx, 158 * sy)
      ..quadraticBezierTo(226 * sx, 228 * sy, 260 * sx, 285 * sy);

    canvas.drawPath(
        routePath,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.35)
          ..strokeWidth = 5 * sx
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // Parte recorrida
    if (active > 0) {
      final metrics = routePath.computeMetrics().first;
      final progress = (active / 3).clamp(0.0, 1.0);
      final partial = metrics.extractPath(0, metrics.length * progress);
      canvas.drawPath(
          partial,
          Paint()
            ..color = AppColors.primary
            ..strokeWidth = 5 * sx
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_TrackingMapPainter old) => old.active != active;
}
