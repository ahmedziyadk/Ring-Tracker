import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'orders';

  String _generateOrderNumber() {
    final random = Random();
    final number = random.nextInt(9000) + 1000;
    return 'ORD-$number';
  }

  String _formatOfficeCustomerName(int number) {
    return 'AZ${number.toString().padLeft(2, '0')}';
  }

  Future<String> generateNextOfficeCustomerName() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('customerName', isGreaterThanOrEqualTo: 'AZ')
        .where('customerName', isLessThan: 'AZ\uf8ff')
        .get();

    var highest = 0;
    final pattern = RegExp(r'^AZ(\d+)$');
    for (final doc in snapshot.docs) {
      final name = (doc.data()['customerName'] ?? '').toString();
      final match = pattern.firstMatch(name);
      if (match == null) continue;
      final number = int.tryParse(match.group(1)!);
      if (number != null && number > highest) {
        highest = number;
      }
    }

    return _formatOfficeCustomerName(highest + 1);
  }

  Future<String> reserveNextOfficeCustomerName() async {
    final counterRef = _firestore.collection('counters').doc('officeCustomerName');
    final suggestedName = await generateNextOfficeCustomerName();
    final suggestedNumber = int.tryParse(suggestedName.substring(2)) ?? 1;

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      final storedNext = (snapshot.data()?['next'] ?? suggestedNumber) as int;
      final next = max(storedNext, suggestedNumber);
      transaction.set(counterRef, {'next': next + 1}, SetOptions(merge: true));
      return _formatOfficeCustomerName(next);
    });
  }

  String _generateCustomerToken() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    return List.generate(
      32,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection(_collection)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<OrderModel>> getOrdersCreatedBy(String userId) {
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<OrderModel>> getOrdersByMaker(String makerId) {
    return _firestore.collection(_collection).snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .where((order) => order.ringMakerId == makerId)
            .toList());
  }

  Stream<List<OrderModel>> searchOrders(String customerName) {
    return _firestore
        .collection(_collection)
        .where('customerName', isGreaterThanOrEqualTo: customerName)
        .where('customerName', isLessThanOrEqualTo: '$customerName\uf8ff')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  Future<DocumentReference> addOrder(OrderModel order) async {
    final orderWithNumber = order.toMap();

    orderWithNumber['orderNumber'] = _generateOrderNumber();
    orderWithNumber['customerToken'] = _generateCustomerToken();

    return await _firestore.collection(_collection).add(orderWithNumber);
  }

  Future<void> updateOrder(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  Future<void> deleteOrder(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<void> updateMakerRemark(String orderId, String remark) async {
    await _firestore
        .collection(_collection)
        .doc(orderId)
        .update({'makerRemark': remark});

    await _addNotification(
      orderId: orderId,
      message: 'Ring maker added a remark on order',
      type: 'remark',
    );
  }

  Future<void> updateStatus(String orderId, String status) async {
    await _firestore
        .collection(_collection)
        .doc(orderId)
        .update({'status': status});
  }

  Future<void> _addNotification({
    required String orderId,
    required String message,
    required String type,
  }) async {
    final orderDoc = await _firestore.collection(_collection).doc(orderId).get();

    final customerName = orderDoc.data()?['customerName'] ?? '';
    final makerName = orderDoc.data()?['ringMakerName'] ?? '';

    await _firestore.collection('notifications').add({
      'orderId': orderId,
      'customerName': customerName,
      'makerName': makerName,
      'message': message,
      'type': type,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<List<Map<String, dynamic>>> getNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  Future<void> markNotificationRead(String id) async {
    await _firestore.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> markAllNotificationsRead() async {
    final batch = _firestore.batch();

    final unread = await _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getAllMakers() {
    return _firestore.collection('users').snapshots().map((snapshot) =>
        snapshot.docs
            .where((doc) => doc.data()['role'] == 'maker')
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }
}


