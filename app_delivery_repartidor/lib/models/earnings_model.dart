class DailyEarnings {
  final DateTime day;
  final int orders;
  final double total;
  final Duration online;

  const DailyEarnings({
    required this.day,
    required this.orders,
    required this.total,
    required this.online,
  });

  String get hoursLabel {
    final h = online.inHours;
    final m = online.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}
