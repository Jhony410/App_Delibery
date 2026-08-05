import 'package:flutter/material.dart';

import 'models/address_model.dart';
import 'screens/addresses_screen.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/checkout_service.dart';
import 'services/db_service.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> showCartCheckoutSheet(BuildContext context) async {
  final orderId = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => const CartCheckoutSheet(),
  );
  if (orderId != null && context.mounted) {
    Navigator.of(context).pushNamed('/confirmed', arguments: orderId);
  }
}

class CartCountBadge extends StatelessWidget {
  final int count;

  const CartCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: context.colors.surface, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class CartFloatingBar extends StatelessWidget {
  final VoidCallback onTap;

  const CartFloatingBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CartService.revision,
      builder: (context, _, _) {
        if (CartService.items.isEmpty) return const SizedBox.shrink();
        return Material(
          color: context.colors.surface,
          elevation: 12,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Semantics(
              button: true,
              label:
                  'Ver carrito, ${CartService.itemCount} productos, total S/ ${CartService.total.toStringAsFixed(2)}',
              child: Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(
                    height: 56,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${CartService.itemCount}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ver carrito',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            'S/ ${CartService.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CartCheckoutSheet extends StatefulWidget {
  const CartCheckoutSheet({super.key});

  @override
  State<CartCheckoutSheet> createState() => _CartCheckoutSheetState();
}

class _CartCheckoutSheetState extends State<CartCheckoutSheet> {
  final _noteController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _submitting = false;
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultAddress() async {
    if (CartService.selectedAddress.trim().isNotEmpty) return;
    final uid = AuthService.currentUid;
    if (uid == null) return;
    setState(() => _loadingAddress = true);
    try {
      final address = await DbService.getDefaultAddress(uid);
      if (address != null) _applyAddress(address);
    } catch (_) {
      // The selector remains available when the default-address read fails.
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  void _applyAddress(AddressModel address) {
    CartService.setDeliveryAddress(
      street: address.street,
      label: address.label,
      reference: address.reference,
      latitude: address.latitude,
      longitude: address.longitude,
    );
  }

  Future<void> _chooseAddress() async {
    final chosen = await Navigator.of(
      context,
    ).pushNamed('/addresses', arguments: AddressListMode.select);
    if (!mounted) return;
    if (chosen is AddressModel) _applyAddress(chosen);
  }

  Future<void> _confirm() async {
    if (_submitting || CheckoutService.isCreatingOrder) return;
    if (CartService.items.isEmpty) return;
    if (CartService.selectedAddress.trim().isEmpty) {
      _showMessage('Selecciona una dirección de entrega.', error: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final orderId = await CheckoutService.createOrder(
        paymentMethod: _paymentMethod,
        observation: _noteController.text,
      );
      if (mounted) Navigator.of(context).pop(orderId);
    } on CheckoutException catch (error) {
      if (mounted) setState(() => _submitting = false);
      if (error.code == 'missing-phone') {
        final saved = await _requestContactPhone();
        if (saved && mounted) await _confirm();
      } else {
        _showMessage(error.message, error: true);
      }
    } catch (_) {
      _showMessage(
        'No pudimos confirmar el pedido. Tu carrito sigue guardado.',
        error: true,
      );
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _requestContactPhone() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final phone = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Celular de contacto'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lo usaremos únicamente para coordinar esta y próximas entregas. No enviaremos un código SMS.',
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(
                  labelText: 'Celular',
                  prefixText: '+51 ',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  return digits.length == 9
                      ? null
                      : 'Ingresa un celular de 9 dígitos';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(
                dialogContext,
                controller.text.replaceAll(RegExp(r'\D'), ''),
              );
            },
            child: const Text('Guardar y continuar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (phone == null || !mounted) return false;

    final uid = AuthService.currentUid;
    if (uid == null) {
      _showMessage('Tu sesión expiró. Inicia sesión nuevamente.', error: true);
      return false;
    }
    try {
      await DbService.updateUser(uid, {'phone': phone});
      if (!mounted) return false;
      _showMessage('Celular guardado');
      return true;
    } catch (_) {
      _showMessage('No pudimos guardar tu celular.', error: true);
      return false;
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.30,
      maxChildSize: 0.94,
      snap: true,
      snapSizes: [0.30, 0.72, 0.94],
      builder: (context, scrollController) {
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _SheetHeader(onClose: () => Navigator.of(context).pop()),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: CartService.revision,
                    builder: (context, _, _) {
                      if (CartService.items.isEmpty) {
                        return ListView(
                          controller: scrollController,
                          children: [
                            SizedBox(height: 20),
                            AppStateView(
                              icon: Icons.shopping_bag_outlined,
                              title: 'Tu carrito está vacío',
                              message: 'Cierra el panel y agrega productos.',
                            ),
                          ],
                        );
                      }
                      return ListView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 20),
                        children: [
                          if (CartService.selectedAddressLabel?.isNotEmpty ??
                              false)
                            Text(
                              CartService.selectedAddressLabel!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          Text(
                            CartService.cartStoreName ?? 'Tu pedido',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...CartService.items.map(
                            (item) => _CartItemTile(item: item),
                          ),
                          const SizedBox(height: 8),
                          _sectionLabel('Dirección de entrega'),
                          _AddressCard(
                            loading: _loadingAddress,
                            onChange: _chooseAddress,
                            noteController: _noteController,
                          ),
                          const SizedBox(height: 20),
                          _sectionLabel('Método de pago'),
                          _PaymentSelector(
                            selected: _paymentMethod,
                            onSelected: (value) =>
                                setState(() => _paymentMethod = value),
                          ),
                          const SizedBox(height: 20),
                          _sectionLabel('Resumen'),
                          const _OrderSummary(),
                        ],
                      );
                    },
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: CartService.revision,
                  builder: (context, _, _) => _ConfirmFooter(
                    enabled: CartService.items.isNotEmpty,
                    loading: _submitting,
                    total: CartService.total,
                    onConfirm: _confirm,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: EdgeInsets.only(left: 2, bottom: 9),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _SheetHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _SheetHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surface,
      padding: EdgeInsets.fromLTRB(16, 8, 8, 12),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: CartService.revision,
                  builder: (context, _, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirmar pedido',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${CartService.itemCount} ${CartService.itemCount == 1 ? 'producto' : 'productos'} en tu pedido',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: onClose,
                icon: Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartEntry item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('${item.storeId}-${item.productId}-${item.note ?? ''}'),
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          ImgPlaceholder(
            height: 58,
            width: 58,
            radius: 10,
            tone: item.tone,
            imageUrl: item.imageUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Eliminar producto',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 38,
                        height: 38,
                      ),
                      onPressed: () => CartService.removeEntry(item),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                if (item.note?.isNotEmpty ?? false) ...[
                  SizedBox(height: 2),
                  Text(
                    item.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Row(
                  children: [
                    _quantityButton(
                      context,
                      icon: Icons.remove_rounded,
                      onTap: () => CartService.decrementEntry(item),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${item.qty}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    _quantityButton(
                      context,
                      icon: Icons.add_rounded,
                      primary: true,
                      onTap: () => CartService.incrementEntry(item),
                    ),
                    const Spacer(),
                    Text(
                      'S/ ${item.lineTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Material(
      color: primary
          ? AppColors.primary
          : Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: CircleBorder(),
      child: InkWell(
        customBorder: CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 17,
            color: primary
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final bool loading;
  final VoidCallback onChange;
  final TextEditingController noteController;

  const _AddressCard({
    required this.loading,
    required this.onChange,
    required this.noteController,
  });

  @override
  Widget build(BuildContext context) {
    final hasAddress = CartService.selectedAddress.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: loading
                    ? Text(
                        'Cargando dirección...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasAddress
                                ? CartService.selectedAddress
                                : 'Selecciona una dirección',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (CartService.selectedAddressRef?.isNotEmpty ??
                              false)
                            Text(
                              CartService.selectedAddressRef!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
              ),
              TextButton(
                onPressed: loading ? null : onChange,
                child: Text(hasAddress ? 'Cambiar' : 'Elegir'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteController,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Nota para el repartidor (opcional)',
              prefixIcon: Icon(Icons.notes_rounded, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _PaymentSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const methods = [
      ('cash', 'Efectivo', Icons.payments_outlined, AppColors.secondary),
      ('yape', 'Yape', Icons.phone_android_rounded, Color(0xFF742284)),
    ];
    return Row(
      children: methods.map((method) {
        final active = selected == method.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: method.$1 == 'cash' ? 10 : 0),
            child: Material(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                onTap: () => onSelected(method.$1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: active
                          ? method.$4
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(method.$3, color: method.$4, size: 22),
                      SizedBox(height: 4),
                      Text(
                        method.$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: active
                              ? method.$4
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _row(context, 'Subtotal', CartService.subtotal),
          const SizedBox(height: 7),
          _row(context, 'Envío', CartService.deliveryFee),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          _row(context, 'Total', CartService.total, total: true),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    double value, {
    bool total = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: total ? 15 : 13,
            fontWeight: total ? FontWeight.w800 : FontWeight.w500,
            color: total
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          'S/ ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: total ? 17 : 13,
            fontWeight: total ? FontWeight.w800 : FontWeight.w700,
            color: total
                ? AppColors.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ConfirmFooter extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final double total;
  final VoidCallback onConfirm;

  const _ConfirmFooter({
    required this.enabled,
    required this.loading,
    required this.total,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: AppButton(
        label: enabled
            ? 'Confirmar pedido · S/ ${total.toStringAsFixed(2)}'
            : 'Confirmar pedido',
        onTap: enabled ? onConfirm : null,
        isLoading: loading,
      ),
    );
  }
}
