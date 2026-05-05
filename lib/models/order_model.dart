import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerToken;
  final String customerName;
  final String mobileNumber;
  final String makingType;
  final String stoneType;
  final String size;
  final String ringMakerId;
  final String ringMakerName;
  final double totalAmount;
  final double advancedAmount;
  final String modelImageUrl;
  final List<String> imageUrls;
  final String noteToMaker;
  final bool isUrgent;
  final DateTime orderDate;
  final DateTime expectedDelivery;
  final String status;
  final String makerRemark;
  final String createdBy;
  final String createdByRole;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerToken,
    required this.customerName,
    required this.mobileNumber,
    required this.makingType,
    required this.stoneType,
    required this.size,
    required this.ringMakerId,
    required this.ringMakerName,
    required this.totalAmount,
    required this.advancedAmount,
    required this.modelImageUrl,
    required this.imageUrls,
    required this.noteToMaker,
    required this.isUrgent,
    required this.orderDate,
    required this.expectedDelivery,
    required this.status,
    required this.makerRemark,
    required this.createdBy,
    required this.createdByRole,
  });

  double get balanceAmount => totalAmount - advancedAmount;

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return OrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? '',
      customerToken: data['customerToken'] ?? '',
      customerName: data['customerName'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      makingType: data['makingType'] ?? '',
      stoneType: data['stoneType'] ?? '',
      size: data['size'] ?? '',
      ringMakerId: data['ringMakerId'] ?? '',
      ringMakerName: data['ringMakerName'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      advancedAmount: (data['advancedAmount'] ?? 0).toDouble(),
      modelImageUrl: data['modelImageUrl'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      noteToMaker: data['noteToMaker'] ?? '',
      isUrgent: data['isUrgent'] ?? false,
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      expectedDelivery: (data['expectedDelivery'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      makerRemark: data['makerRemark'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdByRole: data['createdByRole'] ?? 'admin',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'customerToken': customerToken,
      'customerName': customerName,
      'mobileNumber': mobileNumber,
      'makingType': makingType,
      'stoneType': stoneType,
      'size': size,
      'ringMakerId': ringMakerId,
      'ringMakerName': ringMakerName,
      'totalAmount': totalAmount,
      'advancedAmount': advancedAmount,
      'modelImageUrl': modelImageUrl,
      'imageUrls': imageUrls,
      'noteToMaker': noteToMaker,
      'isUrgent': isUrgent,
      'orderDate': Timestamp.fromDate(orderDate),
      'expectedDelivery': Timestamp.fromDate(expectedDelivery),
      'status': status,
      'makerRemark': makerRemark,
      'createdBy': createdBy,
      'createdByRole': createdByRole,
    };
  }
}

