import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme.dart';
import 'admin_widgets.dart';

/// Default map center when a store has no coordinates yet: Puno, Perú.
const LatLng kPunoCenter = LatLng(-15.8402, -70.0219);
const double kPunoZoom = 15;

/// A locked, non-interactive mini-map showing a single pin at [position].
/// Gestures are disabled so it acts as a static preview. Used both in the store
/// detail location field and the order detail (store location) card.
///
/// Web note: [GoogleMap] requires a unique widget so multiple instances on one
/// page each get their own map container. Flutter handles that automatically.
class LockedMiniMap extends StatelessWidget {
  final LatLng position;
  final double height;
  final double zoom;
  const LockedMiniMap({
    super.key,
    required this.position,
    this.height = 160,
    this.zoom = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: IgnorePointer(
        // Fully static: swallow all gestures so the outer widget controls taps.
        child: GoogleMap(
          initialCameraPosition:
              CameraPosition(target: position, zoom: zoom),
          markers: {
            Marker(
              markerId: const MarkerId('store'),
              position: position,
            ),
          },
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          liteModeEnabled: false,
        ),
      ),
    );
  }
}

/// Store-location field for the General tab. Shows a small preview map with the
/// current pin (or an "undefined location" empty state) plus a button to open
/// the full-screen picker. Never surfaces raw coordinates as the primary datum;
/// they appear only as small secondary reference text.
class StoreLocationField extends StatelessWidget {
  final double? latitude;
  final double? longitude;

  /// Called with the picked coordinates when the admin confirms the picker.
  final void Function(double lat, double lng) onPicked;

  const StoreLocationField({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onPicked,
  });

  bool get _hasLocation => latitude != null && longitude != null;

  Future<void> _openPicker(BuildContext context) async {
    final initial =
        _hasLocation ? LatLng(latitude!, longitude!) : null;
    final result = await showMapLocationPicker(context, initial: initial);
    if (result != null) {
      onPicked(result.latitude, result.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminEyebrow('UBICACIÓN EN EL MAPA'),
        const SizedBox(height: 4),
        const Text(
          'Marca la ubicación exacta del local en el mapa. Otras apps usan estas '
          'coordenadas para mostrar el comercio y calcular distancias.',
          style: TextStyle(fontSize: 12, color: AdminColors.textMuted),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _hasLocation
              ? _PreviewWithPin(
                  position: LatLng(latitude!, longitude!),
                  onTap: () => _openPicker(context),
                )
              : _UndefinedState(onDefine: () => _openPicker(context)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            AdminButton(
              label: _hasLocation
                  ? 'Ajustar ubicación en el mapa'
                  : 'Definir ubicación en el mapa',
              icon: Icons.map_outlined,
              variant: AdminBtnVariant.secondary,
              size: AdminBtnSize.sm,
              onPressed: () => _openPicker(context),
            ),
            const Spacer(),
            if (_hasLocation)
              // Small secondary reference — never the primary datum.
              Text(
                '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                style: GoogleFonts.robotoMono(
                    fontSize: 10.5, color: AdminColors.textSubtle),
              ),
          ],
        ),
      ],
    );
  }
}

class _PreviewWithPin extends StatelessWidget {
  final LatLng position;
  final VoidCallback onTap;
  const _PreviewWithPin({required this.position, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LockedMiniMap(position: position, height: 170),
        // Transparent tap layer over the locked map to open the picker.
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(onTap: onTap),
          ),
        ),
      ],
    );
  }
}

class _UndefinedState extends StatelessWidget {
  final VoidCallback onDefine;
  const _UndefinedState({required this.onDefine});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDefine,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: AdminColors.grayTint,
          border: Border.all(color: AdminColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_outlined,
                size: 28, color: AdminColors.textMuted),
            const SizedBox(height: 8),
            Text('Ubicación no definida',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textMuted)),
            const SizedBox(height: 2),
            const Text('Toca para definirla en el mapa',
                style:
                    TextStyle(fontSize: 11.5, color: AdminColors.textSubtle)),
          ],
        ),
      ),
    );
  }
}

/// Opens the full-screen map picker in a large dialog (desktop-appropriate,
/// since the admin is web). Returns the picked [LatLng], or null if cancelled.
Future<LatLng?> showMapLocationPicker(
  BuildContext context, {
  LatLng? initial,
}) {
  return showDialog<LatLng>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _MapPickerDialog(initial: initial),
  );
}

/// Interactive pin-drop picker: the admin moves the map under a fixed center
/// pin, then confirms. The center of the camera is the chosen coordinate.
class _MapPickerDialog extends StatefulWidget {
  final LatLng? initial;
  const _MapPickerDialog({this.initial});

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  late LatLng _target;

  @override
  void initState() {
    super.initState();
    _target = widget.initial ?? kPunoCenter;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogW = size.width.clamp(0.0, 900.0) * 0.9;
    final dialogH = size.height * 0.85;
    return Dialog(
      backgroundColor: AdminColors.surface,
      insetPadding: const EdgeInsets.all(24),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: dialogW,
        height: dialogH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ubicación del local',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text(
                          'Mueve el mapa para que el pin quede justo sobre el local.',
                          style: TextStyle(
                              fontSize: 12, color: AdminColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    splashRadius: 18,
                    tooltip: 'Cancelar',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _target,
                      zoom: widget.initial == null ? kPunoZoom : 16,
                    ),
                    onCameraMove: (pos) => _target = pos.target,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    myLocationEnabled: false,
                  ),
                  // Fixed center pin (bottom vertex points at the exact center).
                  const IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 44),
                      child: Icon(Icons.location_on,
                          size: 48, color: AdminColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminButton(
                    label: 'Cancelar',
                    variant: AdminBtnVariant.secondary,
                    size: AdminBtnSize.md,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  AdminButton(
                    label: 'Confirmar ubicación',
                    icon: Icons.check,
                    size: AdminBtnSize.md,
                    onPressed: () => Navigator.pop(context, _target),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
