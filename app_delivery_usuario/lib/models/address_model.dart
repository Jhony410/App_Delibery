class AddressModel {
  final String id;
  final String label;
  final String street;
  final String? reference;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.street,
    this.reference,
    this.isDefault = false,
  });

  factory AddressModel.fromMap(String id, Map<String, dynamic> m) => AddressModel(
        id: id,
        label: m['label'] ?? '',
        street: m['street'] ?? '',
        reference: m['reference'],
        isDefault: m['isDefault'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'label': label,
        'street': street,
        'reference': reference,
        'isDefault': isDefault,
      };
}
