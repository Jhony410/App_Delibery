import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../theme.dart';
import '../widgets.dart';
import '../models/address_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import 'map_picker_screen.dart';

enum AddressFormMode { create, edit }

/// Argumentos de la ruta /address-form.
class AddressFormArgs {
  final AddressFormMode mode;
  final AddressModel? address; // requerido en modo edit
  const AddressFormArgs({required this.mode, this.address});
}

/// Pantalla B — Agregar / Editar dirección.
/// Contiene el formulario y una VISTA PREVIA pequeña del mapa (no interactiva).
/// Tocar la vista previa o el botón abre [MapPickerScreen] a pantalla completa.
/// Al guardar escribe en users/{uid}/addresses y hace pop devolviendo la
/// dirección. Nunca navega al checkout.
class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  static const LatLng _punoCenter = LatLng(-15.8402, -70.0219);
  static const _quickLabels = ['Casa', 'Trabajo', 'Otro'];

  final _labelCtrl = TextEditingController(text: 'Casa');
  final _streetCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  AddressFormMode _mode = AddressFormMode.create;
  AddressModel? _editing;
  bool _resolved = false;
  bool _saving = false;

  double? _lat;
  double? _lng;
  GoogleMapController? _previewController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved) return;
    _resolved = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is AddressFormArgs) {
      _mode = arg.mode;
      _editing = arg.address;
    }
    if (_mode == AddressFormMode.edit && _editing != null) {
      final a = _editing!;
      _labelCtrl.text = a.label.isEmpty ? 'Casa' : a.label;
      _streetCtrl.text = a.street;
      _refCtrl.text = a.reference ?? '';
      _lat = a.latitude;
      _lng = a.longitude;
    } else {
      // Modo crear: siembra coordenadas con la ubicación actual (solo GPS, sin
      // geocoding). El texto de calle se obtiene al abrir el mapa completo.
      WidgetsBinding.instance.addPostFrameCallback((_) => _seedCurrentLocation());
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _streetCtrl.dispose();
    _refCtrl.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _seedCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() { _lat = pos.latitude; _lng = pos.longitude; });
      _movePreview();
    } catch (_) {
      // Silencioso: el usuario puede abrir el mapa manualmente.
    }
  }

  LatLng get _previewTarget =>
      (_lat != null && _lng != null) ? LatLng(_lat!, _lng!) : _punoCenter;

  void _movePreview() {
    _previewController
        ?.animateCamera(CameraUpdate.newLatLngZoom(_previewTarget, 16));
  }

  Future<void> _openPicker() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(),
        settings: RouteSettings(
          arguments: (_lat != null && _lng != null)
              ? LatLng(_lat!, _lng!)
              : null,
        ),
      ),
    );
    if (result == null || !mounted) return; // cancelado: no cambia nada
    setState(() {
      _lat = result.latitude;
      _lng = result.longitude;
      // Sugerencia editable: reemplaza el texto de calle con el detectado.
      _streetCtrl.text = result.street;
    });
    _movePreview();
  }

  Future<void> _save() async {
    final street = _streetCtrl.text.trim();
    if (street.isEmpty) {
      _snack('Ingresa la calle o avenida', error: true);
      return;
    }
    final uid = AuthService.currentUid;
    if (uid == null) return;
    final label = _labelCtrl.text.trim().isEmpty ? 'Casa' : _labelCtrl.text.trim();
    final ref = _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim();

    final addr = AddressModel(
      id: _editing?.id ?? '',
      label: label,
      street: street,
      reference: ref,
      isDefault: _editing?.isDefault ?? false,
      latitude: _lat,
      longitude: _lng,
    );

    setState(() => _saving = true);
    try {
      if (_mode == AddressFormMode.edit && _editing != null) {
        await DbService.updateAddress(uid, _editing!.id, addr);
      } else {
        await DbService.addAddress(uid, addr);
      }
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Dirección guardada');
      Navigator.pop(context, addr);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('No se pudo guardar la dirección', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.secondary,
    ));
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
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMapPreview(),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _openPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary, width: 1.5),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined,
                                  size: 18, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Ajustar el punto en el mapa',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Etiqueta',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      _buildLabelChips(),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Nombre de la etiqueta',
                        icon: Icons.bookmark_outline,
                        placeholder: 'Ej: Casa, Trabajo, Intersección',
                        controller: _labelCtrl,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Calle / Avenida',
                        icon: Icons.location_on_outlined,
                        placeholder: 'Ej: Jr. Lima 123',
                        controller: _streetCtrl,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Depto / Piso / Referencias',
                        placeholder: 'Ej: Depto 502, portón azul',
                        controller: _refCtrl,
                      ),
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
                  : AppButton(label: 'Guardar dirección', onTap: _save),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // El mapa es solo vista previa: gestos deshabilitados + IgnorePointer.
            IgnorePointer(
              child: GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: _previewTarget, zoom: 16),
                onMapCreated: (c) => _previewController = c,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                liteModeEnabled: true,
              ),
            ),
            const IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(bottom: 22),
                child: Icon(Icons.location_on,
                    size: 36, color: AppColors.primary),
              ),
            ),
            Positioned(
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.appText.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Toca para ajustar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            // Capa transparente que captura el toque para abrir el mapa completo.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openPicker,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelChips() {
    return Row(
      children: _quickLabels.map((l) {
        final sel = _labelCtrl.text.trim().toLowerCase() == l.toLowerCase();
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _labelCtrl.text = l),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.appText : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: sel ? Colors.transparent : AppColors.border),
              ),
              child: Text(l,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.textMuted)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAppBar() {
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
          Expanded(
            child: Text(
              _mode == AddressFormMode.edit
                  ? 'Editar dirección'
                  : 'Agregar dirección',
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
