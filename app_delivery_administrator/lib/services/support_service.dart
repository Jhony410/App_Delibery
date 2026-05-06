import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ticket_model.dart';

class SupportService {
  static final _col = FirebaseFirestore.instance.collection('tickets');

  static Stream<List<TicketModel>> streamAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => TicketModel.fromMap(d.id, d.data()))
            .toList());
  }

  static Future<void> resolve(String id) =>
      _col.doc(id).update({'status': 'resolved'});
}
