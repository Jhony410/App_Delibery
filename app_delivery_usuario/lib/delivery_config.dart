class DeliveryConfig {
  static const double fixedFee = 9.0;

  static String get formattedFee => 'S/ ${fixedFee.toStringAsFixed(2)}';
}
