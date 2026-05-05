import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import 'order_detail_screen.dart';

class MakerOrdersScreen extends StatelessWidget {
  final String makerId;
  final String makerName;
  const MakerOrdersScreen(
      {super.key, required this.makerId, required this.makerName});

  static const Color kGold = Color(0xFFB8960C);
  static const Color kGoldLight = Color(0xFFFBF6E6);
  static const Color kGoldBorder = Color(0xFFE8D48B);
  static const Color kBg = Color(0xFFFAFAF8);
  static const Color kCard = Colors.white;
  static const Color kText = Color(0xFF1A1814);
  static const Color kTextSub = Color(0xFF9C9685);
  static const Color kBorder = Color(0xFFE8E4DC);

  @override
  Widget build(BuildContext context) {
    final OrderService orderService = OrderService();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        foregroundColor: kText,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: kBorder.withOpacity(0.5)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(makerName,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: kText)),
            const Text('ASSIGNED ORDERS',
                style: TextStyle(
                    fontSize: 9,
                    color: kTextSub,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: orderService.getOrdersByMaker(makerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: kGold));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: kGoldLight,
                      borderRadius:
                      BorderRadius.circular(20),
                      border: Border.all(
                          color: kGoldBorder, width: 1),
                    ),
                    child: const Icon(
                        Icons.inbox_outlined,
                        size: 36,
                        color: kGold),
                  ),
                  const SizedBox(height: 16),
                  Text('No orders assigned to $makerName',
                      style: const TextStyle(
                          color: kTextSub,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          final pending = orders
              .where((o) => o.status != 'completed')
              .toList();
          final completed = orders
              .where((o) => o.status == 'completed')
              .toList();
          final rework = orders
              .where((o) => o.status == 'rework')
              .toList();

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: kBg,
                child: Row(
                  children: [
                    _statCard('Total', orders.length, kGold),
                    const SizedBox(width: 8),
                    _statCard('Pending', pending.length,
                        const Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    _statCard('Completed', completed.length,
                        const Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    _statCard('Rework', rework.length,
                        const Color(0xFFB45309)),
                  ],
                ),
              ),
              Divider(
                  height: 1,
                  color: kGold.withOpacity(0.1)),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) =>
                      _buildOrderTile(
                          context, orders[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(
      String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: kGold.withOpacity(0.12), width: 1),
        ),
        child: Column(
          children: [
            Text(count.toString(),
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 3),
            Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 9,
                    color: kTextSub,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTile(
      BuildContext context, OrderModel order) {
    final dueSoon =
        order.expectedDelivery.difference(DateTime.now()).inDays <=
            7 &&
            order.expectedDelivery
                .difference(DateTime.now())
                .inDays >=
                0 &&
            order.status != 'completed';

    Color statusColor;
    String statusLabel;
    switch (order.status) {
      case 'completed':
        statusColor = const Color(0xFF16A34A);
        statusLabel = 'Completed';
        break;
      case 'in_progress':
        statusColor = const Color(0xFF2563EB);
        statusLabel = 'In Progress';
        break;
      case 'rework':
        statusColor = const Color(0xFFB45309);
        statusLabel = 'Rework';
        break;
      default:
        statusColor = kGold;
        statusLabel = 'Pending';
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                OrderDetailScreen(order: order)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: order.isUrgent
                ? const Color(0xFFDC2626).withOpacity(0.2)
                : kGold.withOpacity(0.14),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: order.isUrgent
                      ? const Color(0xFFDC2626)
                      : order.status == 'completed'
                      ? const Color(0xFF16A34A)
                      : order.status == 'rework'
                      ? const Color(0xFFB45309)
                      : kGold,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: order.isUrgent
                          ? const Color(0xFFFEF2F2)
                          : kGoldLight,
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                        color: order.isUrgent
                            ? const Color(0xFFDC2626)
                            .withOpacity(0.2)
                            : kGoldBorder,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.diamond_outlined,
                      color: order.isUrgent
                          ? const Color(0xFFDC2626)
                          : kGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                  order.customerName,
                                  style: const TextStyle(
                                      fontWeight:
                                      FontWeight.w600,
                                      fontSize: 14,
                                      color: kText)),
                            ),
                            if (order.isUrgent)
                              Container(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 6,
                                    vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(
                                      0xFFFEF2F2),
                                  borderRadius:
                                  BorderRadius.circular(
                                      20),
                                ),
                                child: const Text('URGENT',
                                    style: TextStyle(
                                        color: Color(
                                            0xFFDC2626),
                                        fontSize: 9,
                                        fontWeight:
                                        FontWeight
                                            .w700)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${order.makingType} • ${order.stoneType} • Size: ${order.size}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: kTextSub),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Added: ${DateFormat('dd/MM/yyyy').format(order.orderDate)}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: kTextSub),
                            ),
                            Row(
                              children: [
                                if (dueSoon)
                                  Text(
                                    '${order.expectedDelivery.difference(DateTime.now()).inDays}d left • ',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(
                                            0xFFD97706),
                                        fontWeight:
                                        FontWeight
                                            .w500),
                                  ),
                                Container(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      horizontal: 7,
                                      vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor
                                        .withOpacity(0.1),
                                    borderRadius:
                                    BorderRadius.circular(
                                        20),
                                    border: Border.all(
                                        color: statusColor
                                            .withOpacity(
                                            0.2)),
                                  ),
                                  child: Text(statusLabel,
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: statusColor,
                                          fontWeight:
                                          FontWeight
                                              .w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right,
                      color: kTextSub, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
