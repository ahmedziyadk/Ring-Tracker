import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../services/pdf_service.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import 'add_order_screen.dart';
import 'order_detail_screen.dart';
import 'notifications_screen.dart';
import 'maker_orders_screen.dart';
import 'manage_makers_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final OrderService _orderService = OrderService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color kGold = Color(0xFFB8960C);
  static const Color kGoldLight = Color(0xFFFBF6E6);
  static const Color kGoldBorder = Color(0xFFE8D48B);
  static const Color kBg = Color(0xFFFAFAF8);
  static const Color kCard = Colors.white;
  static const Color kText = Color(0xFF1A1814);
  static const Color kTextSub = Color(0xFF6B6350);
  static const Color kBorder = Color(0xFFE8E4DC);
  static const Color kPrimaryBlue = Color(0xFF21466F);

  bool _isDueSoon(DateTime expectedDelivery) {
    final daysLeft = expectedDelivery.difference(DateTime.now()).inDays;
    return daysLeft <= 7 && daysLeft >= 0;
  }

  bool _isOverdue(DateTime expectedDelivery, String status) {
    return expectedDelivery.isBefore(DateTime.now()) && !OrderStatus.isReady(status);
  }

  String _orderDisplayId(OrderModel order) {
    if (order.orderNumber.trim().isNotEmpty) {
      return order.orderNumber.trim();
    }
    if (order.id.length >= 6) {
      return order.id.substring(0, 6).toUpperCase();
    }
    return order.id.toUpperCase();
  }

  bool _matchesSearch(OrderModel order, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;

    return order.customerName.toLowerCase().contains(q) ||
        order.mobileNumber.toLowerCase().contains(q) ||
        order.stoneType.toLowerCase().contains(q) ||
        order.ringMakerName.toLowerCase().contains(q) ||
        order.orderNumber.toLowerCase().contains(q) ||
        order.id.toLowerCase().contains(q) ||
        _orderDisplayId(order).toLowerCase().contains(q);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              child: const Icon(Icons.diamond_outlined, color: kGold, size: 20),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ring Tracker',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                  Text(
                    'Gemstone Order Management',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF8A846E),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<List<OrderModel>>(
            stream: _orderService.getAllOrders(),
            builder: (context, snapshot) {
              final orders = snapshot.data ?? [];
              return IconButton(
                icon: const Icon(Icons.summarize_outlined, color: Color(0xFF6B6350), size: 22),
                tooltip: 'Export All Orders PDF',
                onPressed: orders.isEmpty
                    ? null
                    : () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Generating report...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  await PdfService().generateAllOrdersPdf(orders);
                },
              );
            },
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _orderService.getNotifications(),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unread = notifications.where((n) => n['isRead'] == false).length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Color(0xFF6B6350), size: 22),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unread > 9 ? '9+' : unread.toString(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Color(0xFF6B6350), size: 22),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCards(),
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddOrderScreen()),
        ),
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        icon: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: kPrimaryBlue, size: 16),
        ),
        label: const Text(
          'New Order',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
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
                    border: Border.all(color: kGoldBorder, width: 1),
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
                  style: TextStyle(color: Color(0xFF6B6350), fontSize: 12, fontWeight: FontWeight.w500),
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
                    child: Text('No ring makers found', style: TextStyle(color: Color(0xFF6B6350))),
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
          ListTile(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageMakersScreen()),
              );
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kGoldLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kGoldBorder, width: 1),
              ),
              child: const Icon(Icons.manage_accounts_outlined, color: kGold, size: 20),
            ),
            title: const Text(
              'Manage Makers',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kText),
            ),
            subtitle: const Text(
              'Add or edit ring makers',
              style: TextStyle(fontSize: 11, color: Color(0xFF6B6350), fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF6B6350), size: 18),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Ring Tracker v1.0', style: TextStyle(fontSize: 11, color: Color(0xFF6B6350))),
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

        return ListTile(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MakerOrdersScreen(
                  makerId: maker['id'],
                  makerName: maker['name'] ?? '',
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
              border: Border.all(color: kGoldBorder, width: 1),
            ),
            child: Center(
              child: Text(
                (maker['name'] ?? 'M')[0].toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kGold),
              ),
            ),
          ),
          title: Text(
            maker['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kText),
          ),
          subtitle: Text(
            '$pending pending${urgent > 0 ? ' • $urgent urgent' : ''}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: urgent > 0 ? const Color(0xFFDC2626) : const Color(0xFF6B6350),
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

  Widget _buildSummaryCards() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getAllOrders(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final pending = orders.where((o) => o.status == 'pending').length;
        final completed = orders.where((o) => OrderStatus.isReady(o.status)).length;
        final rework = orders.where((o) => o.status == 'rework').length;
        final overdue = orders.where((o) => _isOverdue(o.expectedDelivery, o.status)).length;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          color: kBg,
          child: Row(
            children: [
              _statCard('Pending', pending, kGold, false),
              const SizedBox(width: 8),
              _statCard('Ready', completed, const Color(0xFF16A34A), false),
              const SizedBox(width: 8),
              _statCard('Rework', rework, const Color(0xFFB45309), rework > 0),
              const SizedBox(width: 8),
              _statCard('Overdue', overdue, const Color(0xFFDC2626), false),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, int count, Color color, bool showDot) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color == const Color(0xFFDC2626) && count > 0
                ? color.withOpacity(0.2)
                : kBorder.withOpacity(0.6),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF6B6350),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (showDot && count > 0)
              Positioned(
                top: 0,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: kBg,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13, color: kText, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search by customer name or order ID...',
          hintStyle: const TextStyle(color: Color(0xFF9E9886), fontSize: 13, fontWeight: FontWeight.w400),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF9E9886), size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF6B6350), size: 18),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
          filled: true,
          fillColor: kCard,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kGold.withOpacity(0.14)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kGold.withOpacity(0.14)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kGold.withOpacity(0.4)),
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kGold));
        }

        var orders = snapshot.data ?? [];
        orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

        if (_searchQuery.isNotEmpty) {
          orders = orders.where((o) => _matchesSearch(o, _searchQuery)).toList();
        }

        final urgentOrders = orders
            .where((o) => o.isUrgent && !OrderStatus.isReady(o.status) && o.status != 'rework')
            .toList();
        final overdueOrders = orders
            .where((o) => !o.isUrgent && o.status != 'rework' && _isOverdue(o.expectedDelivery, o.status))
            .toList();
        final dueSoonOrders = orders
            .where(
              (o) =>
          !o.isUrgent &&
              o.status != 'rework' &&
              !_isOverdue(o.expectedDelivery, o.status) &&
              _isDueSoon(o.expectedDelivery) &&
              !OrderStatus.isReady(o.status),
        )
            .toList();
        final pendingOrders = orders
            .where(
              (o) =>
          !o.isUrgent &&
              !_isOverdue(o.expectedDelivery, o.status) &&
              !_isDueSoon(o.expectedDelivery) &&
              (o.status == OrderStatus.pending || OrderStatus.isWithMaker(o.status)),
        )
            .toList();
        final reworkOrders = orders.where((o) => o.status == 'rework').toList();
        final completedOrders = orders.where((o) => OrderStatus.isReady(o.status)).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _buildPanel(
              title: 'Urgent Orders',
              barColor: const Color(0xFFDC2626),
              badgeColor: const Color(0xFFFEF2F2),
              badgeTextColor: const Color(0xFFDC2626),
              orders: urgentOrders,
              emptyMessage: 'No urgent orders',
              emptyIcon: Icons.priority_high,
            ),
            _buildPanel(
              title: 'Pending',
              barColor: kGold,
              badgeColor: kGoldLight,
              badgeTextColor: const Color(0xFF8B7109),
              orders: pendingOrders,
              emptyMessage: 'No pending orders',
              emptyIcon: Icons.hourglass_empty_outlined,
            ),
            _buildPanel(
              title: 'Due Soon',
              barColor: const Color(0xFFD97706),
              badgeColor: const Color(0xFFFFFBEB),
              badgeTextColor: const Color(0xFFB45309),
              orders: dueSoonOrders,
              emptyMessage: 'No orders due soon',
              emptyIcon: Icons.schedule_outlined,
            ),
            _buildPanel(
              title: 'Return / Rework',
              barColor: const Color(0xFFB45309),
              badgeColor: const Color(0xFFFFFBEB),
              badgeTextColor: const Color(0xFFB45309),
              orders: reworkOrders,
              emptyMessage: 'No rework orders',
              emptyIcon: Icons.replay_outlined,
            ),
            _buildPanel(
              title: 'Ready',
              barColor: const Color(0xFF16A34A),
              badgeColor: const Color(0xFFF0FDF4),
              badgeTextColor: const Color(0xFF15803D),
              orders: completedOrders,
              emptyMessage: 'No ready orders',
              emptyIcon: Icons.check_circle_outline,
            ),
            _buildPanel(
              title: 'Overdue',
              barColor: const Color(0xFFDC2626),
              badgeColor: const Color(0xFFFEF2F2),
              badgeTextColor: const Color(0xFFDC2626),
              orders: overdueOrders,
              emptyMessage: 'No overdue orders',
              emptyIcon: Icons.warning_amber_outlined,
              isOverdue: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPanel({
    required String title,
    required Color barColor,
    required Color badgeColor,
    required Color badgeTextColor,
    required List<OrderModel> orders,
    required String emptyMessage,
    required IconData emptyIcon,
    bool isOverdue = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: kText,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    orders.length.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: badgeTextColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(emptyIcon, size: 28, color: const Color(0xFFB8B2A0)),
                  const SizedBox(height: 8),
                  Text(
                    emptyMessage,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9E9886), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          else
            ...orders.map((order) => _buildOrderCard(order, isOverdue: isOverdue)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, {bool isOverdue = false}) {
    final dueSoon = _isDueSoon(order.expectedDelivery) && !OrderStatus.isReady(order.status);
    final days = order.expectedDelivery.difference(DateTime.now()).inDays;
    final overdueDays = DateTime.now().difference(order.expectedDelivery).inDays;

    Color iconColor = kGold;
    if (order.isUrgent) iconColor = const Color(0xFFDC2626);
    if (isOverdue) iconColor = const Color(0xFFDC2626);
    if (order.status == 'rework') iconColor = const Color(0xFFB45309);
    if (OrderStatus.isReady(order.status)) iconColor = const Color(0xFF16A34A);

    final balanceText = order.balanceAmount > 0
        ? '₹${order.balanceAmount.toStringAsFixed(0)} due'
        : 'Paid';
    final dueDate = DateFormat('dd/MM').format(order.expectedDelivery);
    final addedDate = DateFormat('dd/MM/yyyy').format(order.orderDate);
    final orderId = _orderDisplayId(order);

    final detailParts = [
      if (order.stoneType.trim().isNotEmpty) order.stoneType.trim(),
      if (order.ringMakerName.trim().isNotEmpty) order.ringMakerName.trim(),
      if (order.mobileNumber.trim().isNotEmpty) order.mobileNumber.trim(),
    ];

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kCard,
          border: Border(
            top: BorderSide(color: kBorder.withOpacity(0.55), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.diamond_outlined, color: iconColor, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.customerName.isNotEmpty
                              ? order.customerName
                              : 'Unnamed customer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: kText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '#$orderId',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8B7109),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detailParts.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6350),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B6350)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Added: $addedDate',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B6350), fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '$overdueDays day${overdueDays == 1 ? '' : 's'} overdue',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ] else if (dueSoon) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            days == 0 ? 'Due today' : '$days days left',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: order.balanceAmount > 0
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    balanceText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: order.balanceAmount > 0
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF059669),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Due: $dueDate',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B6350), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFFB8B2A0), size: 22),
          ],
        ),
      ),
    );
  }
}
