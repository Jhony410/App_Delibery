import 'package:cloud_firestore/cloud_firestore.dart';

/// Aggregates derived financial figures from the orders collection.
/// In a production system these would be precomputed by a Cloud Function;
/// here we read recent orders and roll them up client-side.
class FinanceService {
  static final _orders = FirebaseFirestore.instance.collection('orders');

  static Future<FinanceSummary> summary({int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final snap = await _orders
        .where('createdAt',
            isGreaterThan: Timestamp.fromDate(since))
        .where('status', isEqualTo: 'entregado')
        .get();
    double gross = 0;
    double delivery = 0;
    int orders = 0;
    final perDay = <String, double>{};
    for (final d in snap.docs) {
      final m = d.data();
      final t = (m['total'] as num?)?.toDouble() ?? 0;
      final f = (m['deliveryFee'] as num?)?.toDouble() ?? 0;
      gross += t;
      delivery += f;
      orders++;
      final created =
          (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final key =
          '${created.year}-${created.month.toString().padLeft(2, '0')}-'
          '${created.day.toString().padLeft(2, '0')}';
      perDay[key] = (perDay[key] ?? 0) + t;
    }
    final commission = gross * 0.18;
    return FinanceSummary(
      gross: gross,
      commission: commission,
      payable: gross - commission,
      delivery: delivery,
      orders: orders,
      perDay: perDay,
    );
  }
}

class FinanceSummary {
  final double gross;
  final double commission;
  final double payable;
  final double delivery;
  final int orders;
  final Map<String, double> perDay;

  const FinanceSummary({
    required this.gross,
    required this.commission,
    required this.payable,
    required this.delivery,
    required this.orders,
    required this.perDay,
  });
}
