import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../models/address_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _streetCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  List<AddressModel> _saved = [];
  String? _selectedSavedId;
  bool _showForm = false;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _streetCtrl.text = CartService.selectedAddress;
    _refCtrl.text = CartService.selectedAddressRef ?? '';
    _loadSaved();
  }

  @override
  void dispose() {
    _streetCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;
    setState(() => _loading = true);
    final list = await DbService.getUserAddresses(uid);
    if (mounted) setState(() { _saved = list; _loading = false; });
  }

  Future<void> _confirm() async {
    if (_showForm) {
      final street = _streetCtrl.text.trim();
      if (street.isEmpty) return;
      final uid = AuthService.currentUid;
      if (uid != null) {
        setState(() => _saving = true);
        final addr = AddressModel(
          id: '',
          label: 'Casa',
          street: street,
          reference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
          isDefault: _saved.isEmpty,
        );
        await DbService.addAddress(uid, addr);
        if (mounted) setState(() => _saving = false);
      }
      CartService.selectedAddress = street;
      CartService.selectedAddressRef =
          _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim();
    } else if (_selectedSavedId != null) {
      final addr = _saved.firstWhere((a) => a.id == _selectedSavedId);
      CartService.selectedAddress = addr.street;
      CartService.selectedAddressRef = addr.reference;
    } else {
      CartService.selectedAddress = _streetCtrl.text.trim().isEmpty
          ? 'Av. Arequipa 2450, Lince'
          : _streetCtrl.text.trim();
      CartService.selectedAddressRef = null;
    }
    if (mounted) Navigator.pushNamed(context, '/summary');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 8),
              _buildAppBar(context),
              SizedBox(
                height: 280,
                child: CustomPaint(
                  size: const Size(double.infinity, 280),
                  painter: _MapPainter(),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.appText,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Arrastra para ajustar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.location_on,
                              size: 22, color: Colors.white),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -2),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_loading)
                        const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary))
                      else if (_saved.isNotEmpty && !_showForm) ...[
                        const Text(
                          'Mis direcciones guardadas',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.28),
                        ),
                        const SizedBox(height: 10),
                        ..._saved.map((addr) {
                          final sel = _selectedSavedId == addr.id;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedSavedId = addr.id),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppColors.primaryTint
                                          : AppColors.bg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.home_outlined,
                                        size: 18,
                                        color: sel
                                            ? AppColors.primary
                                            : AppColors.textMuted),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(addr.label,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700)),
                                        Text(addr.street,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted)),
                                        if (addr.reference != null)
                                          Text(addr.reference!,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textSubtle)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: sel
                                          ? AppColors.primary
                                          : Colors.white,
                                      border: Border.all(
                                        color: sel
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: 2,
                                      ),
                                    ),
                                    child: sel
                                        ? const Icon(Icons.check,
                                            size: 11, color: Colors.white)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () =>
                              setState(() { _showForm = true; _selectedSavedId = null; }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.primary,
                                  width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add,
                                    size: 18, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text('Agregar nueva dirección',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Detalles de la entrega',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Calle / Avenida',
                          icon: Icons.location_on_outlined,
                          placeholder: 'Ej: Av. Arequipa 2450',
                          controller: _streetCtrl,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Depto / Piso / Referencias',
                          placeholder: 'Ej: Depto 502, Edificio azul',
                          controller: _refCtrl,
                        ),
                        if (_saved.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _showForm = false),
                            child: const Text(
                              'Ver direcciones guardadas',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: _saving
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : AppButton(
                      label: 'Confirmar dirección',
                      onTap: _confirm,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_left, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Dirección de entrega',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 375;
    final sy = size.height / 280;
    canvas.drawRect(Offset.zero & size,
        Paint()..color = const Color(0xFFDDE7EC));
    final block = Paint()..color = const Color(0xFFE8EEF2);
    void rect(double x, double y, double w, double h) => canvas.drawRect(
        Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy), block);
    rect(0, 0, 130, 90);
    rect(160, 0, 120, 90);
    rect(310, 0, 65, 90);
    rect(0, 110, 80, 80);
    rect(110, 110, 170, 80);
    rect(0, 210, 130, 70);
    rect(160, 210, 120, 70);
    final road = Paint()..color = Colors.white;
    void rroad(double x, double y, double w, double h) => canvas.drawRect(
        Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy), road);
    rroad(0, 93, 375, 14);
    rroad(0, 195, 375, 14);
    rroad(135, 0, 22, 280);
    rroad(285, 0, 20, 280);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
