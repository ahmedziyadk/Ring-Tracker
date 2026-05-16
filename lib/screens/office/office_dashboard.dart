import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../admin/add_order_screen.dart';
import '../admin/maker_orders_screen.dart';
import '../admin/order_detail_screen.dart';

class OfficeDashboard extends StatefulWidget {
  const OfficeDashboard({super.key});

  @override
  State<OfficeDashboard> createState() => _OfficeDashboardState();
}

class _OfficeDashboardState extends State<OfficeDashboard> {
  final OrderService _orderService = OrderService();

  static const Color kGold = Color(0xFFB8960C);
  static const Color kGoldLight = Color(0xFFFBF6E6);
  static const Color kBg = Color(0xFFFAFAF8);
  static const Color kCard = Colors.white;
  static const Color kText = Color(0xFF1A1814);
  static const Color kTextSub = Color(0xFF6B6350);
  static const Color kBorder = Color(0xFFE8E4DC);
  static const Color kPrimaryBlue = Color(0xFF21466F);

  String _orderDisplayId(OrderModel order) {
    if (order.orderNumber.trim().isNotEmpty) return order.orderNumber.trim();
    if (order.id.length >= 6) return order.id.substring(0, 6).toUpperCase();
    return order.id.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: kBg,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: kBg,
        foregroundColor: kText,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorder.withOpacity(0.5)),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: kText),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kGold.withOpacity(0.2), width: 1),
              ),
              child: const Icon(Icons.business_center_outlined, color: kGold, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Office',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText),
                ),
                Text(
                  'ORDER ENTRY',
                  style: TextStyle(
                    fontSize: 9,
                    color: kTextSub,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: kTextSub, size: 22),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _orderService.getOrdersCreatedBy(authProvider.user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kGold));
          }

          final orders = snapshot.data ?? [];
          orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

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
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kGold.withOpacity(0.25), width: 1),
                    ),
                    child: const Icon(Icons.receipt_long_outlined, size: 36, color: kGold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No office orders yet',
                    style: TextStyle(color: kTextSub, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: orders.length,
            itemBuilder: (context, index) => _buildOrderCard(orders[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddOrderScreen(isOfficeOrder: true)),
        ),
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: const Text('New Order', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: kCard,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              color: kBg,
              border: Border(bottom: BorderSide(color: kGold.withOpacity(0.15))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: kGoldLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kGold.withOpacity(0.25), width: 1),
                  ),
                  child: const Icon(Icons.people_outline, color: kGold, size: 24),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ring Makers',
                  style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Text(
                  'View orders by maker',
                  style: TextStyle(color: kTextSub, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _orderService.getAllMakers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kGold));
                }

                final makers = snapshot.data ?? [];
                if (makers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No ring makers found',
                      style: TextStyle(color: kTextSub, fontWeight: FontWeight.w500),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: makers.length,
                  itemBuilder: (context, index) => _buildMakerTile(context, makers[index]),
                );
              },
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Ring Tracker v1.0',
              style: TextStyle(fontSize: 11, color: kTextSub),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMakerTile(BuildContext context, Map<String, dynamic> maker) {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrdersByMaker(maker['id']),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final pending = orders.where((o) => !OrderStatus.isReady(o.status)).length;
        final urgent = orders.where((o) => o.isUrgent && !OrderStatus.isReady(o.status)).length;
        final makerName = maker['name'] ?? '';

        return ListTile(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MakerOrdersScreen(
                  makerId: maker['id'],
                  makerName: makerName,
                ),
              ),
            );
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kGoldLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGold.withOpacity(0.25), width: 1),
            ),
            child: Center(
              child: Text(
                makerName.isNotEmpty ? makerName[0].toUpperCase() : 'M',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kGold),
              ),
            ),
          ),
          title: Text(
            makerName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kText),
          ),
          subtitle: Text(
            '$pending pending${urgent > 0 ? ' - $urgent urgent' : ''}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: urgent > 0 ? const Color(0xFFDC2626) : kTextSub,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (urgent > 0)
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      urgent.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Color(0xFF6B6350), size: 18),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final orderId = _orderDisplayId(order);
    final addedDate = DateFormat('dd/MM/yyyy').format(order.orderDate);
    final dueDate = DateFormat('dd/MM/yyyy').format(order.expectedDelivery);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kGold.withOpacity(0.14), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kGold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.diamond_outlined, color: kGold, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText),
                        ),
                      ),
                      Text(
                        '#$orderId',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF8B7109), fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${order.makingType} • ${order.stoneType} • ${order.ringMakerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: kTextSub, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Added: $addedDate  •  Due: $dueDate',
                    style: const TextStyle(fontSize: 11, color: kTextSub, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFFB8B2A0), size: 22),
          ],
        ),
      ),
    );
  }
}

