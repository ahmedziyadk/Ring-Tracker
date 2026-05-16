import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/order_status.dart';

class CustomerOrderViewScreen extends StatelessWidget {
  final String orderId;
  final String token;
  final bool isMakerView;

  const CustomerOrderViewScreen({
    super.key,
    required this.orderId,
    required this.token,
    this.isMakerView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        title: Text(isMakerView ? 'Maker Order Details' : 'Click Gems Order'),
        backgroundColor: const Color(0xFFFAFAF8),
        foregroundColor: const Color(0xFF1A1814),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFB8960C)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          if (data['customerToken'] != token) {
            return const Center(child: Text('Invalid or expired order link'));
          }

          final orderDate = (data['orderDate'] as Timestamp?)?.toDate();
          final expectedDelivery =
              (data['expectedDelivery'] as Timestamp?)?.toDate();
          final imageUrls = List<String>.from(data['imageUrls'] ?? []);
          final makerRemark = (data['makerRemark'] ?? '').toString();
          final status = (data['status'] ?? '').toString();
          final statusLabel = status.isEmpty ? '' : OrderStatus.label(status);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1814),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMakerView ? 'Order Details' : 'Order Confirmed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['orderNumber'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFFE8D48B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _section('Customer Details', [
                _row('Name', data['customerName'] ?? ''),
                if (!isMakerView)
                  _row('Mobile Number', data['mobileNumber'] ?? ''),
              ]),
              _section('Order Details', [
                _row('Stone', data['stoneType'] ?? ''),
                _row('Making', data['makingType'] ?? ''),
                _row('Size', data['size'] ?? ''),
                _row('Status', statusLabel),
                _row(
                  'Order Date',
                  orderDate == null ? '' : DateFormat('dd/MM/yyyy').format(orderDate),
                ),
                _row(
                  isMakerView ? 'സമയ പരിധി' : 'Expected Delivery',
                  expectedDelivery == null
                      ? ''
                      : DateFormat('dd/MM/yyyy').format(expectedDelivery),
                ),
                if (makerRemark.isNotEmpty)
                  _row('Ring Maker Remark', makerRemark),
              ]),
              if (!isMakerView)
                _section('Payment Details', [
                  _row('Total Amount', 'Rs ${data['totalAmount'] ?? 0}'),
                  _row('Advance Paid', 'Rs ${data['advancedAmount'] ?? 0}'),
                ]),
              if (imageUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Model Images',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1814),
                  ),
                ),
                const SizedBox(height: 10),
                ...imageUrls.map(
                  (url) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8E4DC)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Image not available'),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Thank you for choosing Click Gems',
                  style: TextStyle(
                    color: Color(0xFFB8960C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E4DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B7109),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9C9685),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1A1814),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
