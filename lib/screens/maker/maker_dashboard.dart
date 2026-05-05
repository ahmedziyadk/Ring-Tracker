import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';

class MakerDashboard extends StatefulWidget {
  const MakerDashboard({super.key});

  @override
  State<MakerDashboard> createState() =>
      _MakerDashboardState();
}

class _MakerDashboardState extends State<MakerDashboard> {
  final OrderService _orderService = OrderService();

  static const Color kGold = Color(0xFFB8960C);
  static const Color kGoldLight = Color(0xFFFBF6E6);
  static const Color kGoldBorder = Color(0xFFE8D48B);
  static const Color kBg = Color(0xFFFAFAF8);
  static const Color kCard = Colors.white;
  static const Color kText = Color(0xFF1A1814);
  static const Color kTextSub = Color(0xFF9C9685);
  static const Color kBorder = Color(0xFFE8E4DC);

  bool _isDueSoon(DateTime expectedDelivery) {
    final daysLeft =
        expectedDelivery.difference(DateTime.now()).inDays;
    return daysLeft <= 7 && daysLeft >= 0;
  }

  int _daysLeft(DateTime expectedDelivery) =>
      expectedDelivery.difference(DateTime.now()).inDays;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: kGold.withOpacity(0.2), width: 1),
              ),
              child: const Icon(Icons.diamond_outlined,
                  color: kGold, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ring Tracker',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kText,
                        letterSpacing: -0.3)),
                Text(
                  authProvider.makerName.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 9,
                      color: kTextSub,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined,
                color: kTextSub, size: 22),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _orderService
            .getOrdersByMaker(authProvider.user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: kGold));
          }

          final orders = snapshot.data ?? [];
          final urgent = orders
              .where((o) =>
          o.isUrgent && o.status != 'completed' && o.status != 'rework')
              .toList();
          final dueSoon = orders
              .where((o) =>
          !o.isUrgent &&
              _isDueSoon(o.expectedDelivery) &&
              o.status != 'completed' &&
              o.status != 'rework')
              .toList();
          final normal = orders
              .where((o) =>
          !o.isUrgent &&
              !_isDueSoon(o.expectedDelivery) &&
              o.status != 'completed' &&
              o.status != 'rework')
              .toList();
          final rework = orders
              .where((o) => o.status == 'rework')
              .toList();
          final completed = orders
              .where((o) => o.status == 'completed')
              .toList();

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
                  const Text('No orders assigned yet',
                      style: TextStyle(
                          color: kTextSub,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return ListView(
            padding:
            const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (urgent.isNotEmpty) ...[
                _buildSectionHeader('Urgent Orders',
                    urgent.length, const Color(0xFFDC2626),
                    const Color(0xFFFEF2F2),
                    const Color(0xFFDC2626)),
                ...urgent.map((o) => _buildOrderCard(o)),
                const SizedBox(height: 8),
              ],
              if (dueSoon.isNotEmpty) ...[
                _buildSectionHeader('Due Soon',
                    dueSoon.length, const Color(0xFFD97706),
                    const Color(0xFFFFFBEB),
                    const Color(0xFFB45309)),
                ...dueSoon.map((o) => _buildOrderCard(o)),
                const SizedBox(height: 8),
              ],
              if (normal.isNotEmpty) ...[
                _buildSectionHeader('Pending Orders',
                    normal.length, kGold,
                    kGoldLight,
                    const Color(0xFF8B7109)),
                ...normal.map((o) => _buildOrderCard(o)),
                const SizedBox(height: 8),
              ],
              if (rework.isNotEmpty) ...[
                _buildSectionHeader(
                    'Return / Rework',
                    rework.length,
                    const Color(0xFFB45309),
                    const Color(0xFFFFFBEB),
                    const Color(0xFFB45309)),
                ...rework.map((o) => _buildOrderCard(o)),
                const SizedBox(height: 8),
              ],
              if (completed.isNotEmpty) ...[
                _buildSectionHeader('Completed',
                    completed.length,
                    const Color(0xFF16A34A),
                    const Color(0xFFF0FDF4),
                    const Color(0xFF15803D)),
                ...completed.map((o) => _buildOrderCard(o)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      String title,
      int count,
      Color barColor,
      Color badgeColor,
      Color badgeTextColor,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kText,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 11, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 11,
                  color: badgeTextColor,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dueSoon = _isDueSoon(order.expectedDelivery) &&
        order.status != 'completed';
    final days = _daysLeft(order.expectedDelivery);

    Color accentColor = kGold;
    if (order.isUrgent) accentColor = const Color(0xFFDC2626);
    if (order.status == 'rework')
      accentColor = const Color(0xFFB45309);
    if (order.status == 'completed')
      accentColor = const Color(0xFF16A34A);

    return Container(
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
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(0, 4, 14, 4),
          leading: Container(
            width: 3,
            height: double.infinity,
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(order.customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: kText,
                              letterSpacing: -0.2)),
                    ),
                    if (order.isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: const Text('URGENT',
                            style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 9,
                                fontWeight:
                                FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                    if (!order.isUrgent && dueSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: Text(
                          days == 0
                              ? 'Due today'
                              : '$days days left',
                          style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    if (order.status == 'rework')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: const Text('REWORK',
                            style: TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 9,
                                fontWeight:
                                FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${order.makingType} • ${order.stoneType} • Due: ${DateFormat('dd/MM/yyyy').format(order.expectedDelivery)}',
                  style: const TextStyle(
                      fontSize: 12, color: kTextSub),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: kTextSub),
                    const SizedBox(width: 3),
                    Text(
                      'Added: ${DateFormat('dd/MM/yyyy').format(order.orderDate)}',
                      style: const TextStyle(
                          fontSize: 11, color: kTextSub),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Divider(
                      color: kGold.withOpacity(0.1),
                      height: 1),
                  const SizedBox(height: 12),
                  if (order.isUrgent && dueSoon)
                    Container(
                      margin:
                      const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius:
                        BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFD97706)
                                .withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 14,
                              color: Color(0xFFD97706)),
                          const SizedBox(width: 6),
                          Text(
                            days == 0
                                ? 'Due TODAY!'
                                : 'Due in $days day${days == 1 ? '' : 's'}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFD97706),
                                fontWeight:
                                FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  _infoRow('Size', order.size),
                  _infoRow('Stone', order.stoneType),
                  if (order.noteToMaker.isNotEmpty)
                    _infoRow('Note', order.noteToMaker),
                  if (order.modelImageUrl.isNotEmpty)
                    _infoRow(
                        'Reference', order.modelImageUrl),
                  if (order.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 12,
                          decoration: BoxDecoration(
                            color: kGold,
                            borderRadius:
                            BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('MODEL IMAGES',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8B7109),
                                letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: order.imageUrls.length,
                      itemBuilder: (context, index) =>
                          GestureDetector(
                            onTap: () => _showFullImage(
                                context, order, index),
                            child: ClipRRect(
                              borderRadius:
                              BorderRadius.circular(10),
                              child: Image.network(
                                order.imageUrls[index],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child,
                                    progress) =>
                                progress == null
                                    ? child
                                    : Center(
                                    child:
                                    CircularProgressIndicator(
                                        strokeWidth:
                                        2,
                                        color:
                                        kGold)),
                                errorBuilder: (_, __, ___) =>
                                    Container(
                                      color: kGoldLight,
                                      child: const Icon(
                                          Icons
                                              .broken_image_outlined,
                                          color: kGold),
                                    ),
                              ),
                            ),
                          ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _buildRemarkSection(order),
                  const SizedBox(height: 14),
                  _buildStatusButtons(order),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(
      BuildContext context, OrderModel order, int initialIndex) {
    final pageController =
    PageController(initialPage: initialIndex);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: order.imageUrls.length,
              itemBuilder: (context, index) =>
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    panEnabled: true,
                    scaleEnabled: true,
                    child: Center(
                      child: Image.network(
                        order.imageUrls[index],
                        fit: BoxFit.contain,
                        loadingBuilder:
                            (context, child, progress) =>
                        progress == null
                            ? child
                            : const Center(
                            child:
                            CircularProgressIndicator(
                                color: Colors
                                    .white)),
                      ),
                    ),
                  ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Text(
                '${initialIndex + 1} / ${order.imageUrls.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: kTextSub, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kText)),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarkSection(OrderModel order) {
    final remarkController =
    TextEditingController(text: order.makerRemark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: kGold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            const Text('YOUR REMARK',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B7109),
                    letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: remarkController,
          maxLines: 2,
          style:
          const TextStyle(fontSize: 13, color: kText),
          decoration: InputDecoration(
            hintText: 'Add update or remark...',
            hintStyle:
            const TextStyle(color: Color(0xFFB4AE9E)),
            filled: true,
            fillColor: kBg,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: kGold.withOpacity(0.14)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: kGold.withOpacity(0.14)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: kGold.withOpacity(0.5),
                  width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await _orderService.updateMakerRemark(
                  order.id, remarkController.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Remark saved!'),
                      backgroundColor:
                      Color(0xFF16A34A)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kGold,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
              const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Save Remark',
                style: TextStyle(
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButtons(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: kGold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            const Text('UPDATE STATUS',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B7109),
                    letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: ['pending', 'in_progress', 'rework', 'completed']
              .map((status) {
            final isSelected = order.status == status;
            Color color;
            String label;
            switch (status) {
              case 'completed':
                color = const Color(0xFF16A34A);
                label = 'Completed';
                break;
              case 'in_progress':
                color = const Color(0xFF2563EB);
                label = 'In Progress';
                break;
              case 'rework':
                color = const Color(0xFFB45309);
                label = 'Rework';
                break;
              default:
                color = kGold;
                label = 'Pending';
            }
            return Expanded(
              child: GestureDetector(
                onTap: () => _orderService.updateStatus(
                    order.id, status),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                      vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color
                        : color.withOpacity(0.08),
                    borderRadius:
                    BorderRadius.circular(10),
                    border: isSelected
                        ? null
                        : Border.all(
                        color:
                        color.withOpacity(0.2)),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
