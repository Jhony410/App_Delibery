class AddressModel {
  final String id;
  final String label;
  final String street;
  final String? reference;
  final bool isDefault;

  /// Coordenadas seleccionadas en el mapa. Nullable: las direcciones antiguas
  /// guardadas antes de esta versión no las tienen y deben seguir funcionando.
  final double? latitude;
  final double? longitude;

  const AddressModel({
    required this.id,
    required this.label,
    required this.street,
    this.reference,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromMap(String id, Map<String, dynamic> m) => AddressModel(
        id: id,
        label: m['label'] ?? '',
        street: m['street'] ?? '',
        reference: m['reference'],
        isDefault: m['isDefault'] ?? false,
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'label': label,
        'street': street,
        'reference': reference,
        'isDefault': isDefault,
        'latitude': latitude,
        'longitude': longitude,
      };

  bool get hasCoords => latitude != null && longitude != null;
}
