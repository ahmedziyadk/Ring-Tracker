import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../services/order_service.dart';
import '../../services/pdf_service.dart';
import 'edit_order_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  static const Color kGold = Color(0xFFB8960C);
  static const Color kGoldLight = Color(0xFFFBF6E6);
  static const Color kGoldBorder = Color(0xFFE8D48B);
  static const Color kBg = Color(0xFFFAFAF8);
  static const Color kCard = Colors.white;
  static const Color kText = Color(0xFF1A1814);
  static const Color kTextSub = Color(0xFF9C9685);
  static const Color kBorder = Color(0xFFE8E4DC);

  bool get _isDueSoon {
    final daysLeft =
        order.expectedDelivery.difference(DateTime.now()).inDays;
    return daysLeft <= 7 &&
        daysLeft >= 0 &&
        !OrderStatus.isReady(order.status);
  }

  int get _daysLeft =>
      order.expectedDelivery.difference(DateTime.now()).inDays;

  String _whatsAppPhoneNumber(String mobileNumber) {
    final digits = mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) return '91$digits';
    return digits;
  }

  Future<void> _resendWhatsAppLink(BuildContext context) async {
    final phone = _whatsAppPhoneNumber(order.mobileNumber);
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No mobile number found for this order.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (order.customerToken.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer link token is missing for this order.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final orderLink =
        'https://gemstone-orders.web.app/?orderId=${order.id}&token=${order.customerToken}';

    final message = '''
Hello ${order.customerName},

Your Click Gems order is confirmed.

Order No: ${order.orderNumber}
Stone: ${order.stoneType}
Making: ${order.makingType}
Ring Size: ${order.size}

View your order details here:
$orderLink

Thank you for choosing Click Gems.
''';

    final whatsappUrl = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendOrderToMaker(BuildContext context) async {
    if (order.ringMakerId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No ring maker is assigned to this order.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final makerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(order.ringMakerId)
        .get();

    if (!context.mounted) return;

    final makerData = makerDoc.data();
    final makerPhone = _whatsAppPhoneNumber(
      (makerData?['mobileNumber'] ?? '').toString(),
    );

    if (makerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maker WhatsApp number is not saved. Add it in Manage Makers.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final makerName = (makerData?['name'] ?? order.ringMakerName).toString();
    final orderDate = DateFormat('dd/MM/yyyy').format(order.orderDate);
    final expectedDate = DateFormat('dd/MM/yyyy').format(order.expectedDelivery);
    final makerRemark = order.makerRemark.trim();
    final orderLink =
        'https://gemstone-orders.web.app/?orderId=${order.id}&token=${order.customerToken}&view=maker';

    final message = '''
Hello $makerName,

New order assigned to you.

Order No: ${order.orderNumber}
Customer: ${order.customerName}
Making: ${order.makingType}
Size: ${order.size}
Order Date: $orderDate
സമയ പരിധി: $expectedDate
Ring Maker Remark: ${makerRemark.isEmpty ? '-' : makerRemark}

View order details here:
$orderLink

Please update the order status in Ring Tracker.
''';

    final whatsappUrl = Uri.parse(
      'https://wa.me/$makerPhone?text=${Uri.encodeComponent(message)}',
    );

    if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final OrderService orderService = OrderService();
    final PdfService pdfService = PdfService();

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
            Text(order.customerName,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: kText)),
            const Text('ORDER DETAILS',
                style: TextStyle(
                    fontSize: 9,
                    color: kTextSub,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_outlined,
                color: Color(0xFF16A34A), size: 22),
            tooltip: 'Resend WhatsApp Link',
            onPressed: () => _resendWhatsAppLink(context),
          ),
          IconButton(
            icon: const Icon(Icons.handyman_outlined,
                color: Color(0xFF2563EB), size: 22),
            tooltip: 'Send Order to Maker',
            onPressed: () => _sendOrderToMaker(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined,
                color: kGold, size: 22),
            tooltip: 'Export PDF',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: kCard,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20)),
                ),
                builder: (_) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 18,
                            decoration: BoxDecoration(
                              color: kGold,
                              borderRadius:
                              BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Export PDF',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: kText,
                                  letterSpacing: -0.3)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                          'Choose what to include',
                          style: TextStyle(
                              fontSize: 12,
                              color: kTextSub)),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Generating full PDF...'),
                                  duration:
                                  Duration(seconds: 1)),
                            );
                            await pdfService.generateOrderPdf(
                                order,
                                includePayment: true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGold,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                            const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                              Icons.receipt_long_outlined),
                          label: const Text('Full Order Sheet',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                  FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4),
                        child: Text(
                          'Includes all details with payment amounts',
                          style: TextStyle(
                              fontSize: 11,
                              color: kTextSub),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Generating maker sheet...'),
                                  duration:
                                  Duration(seconds: 1)),
                            );
                            await pdfService.generateOrderPdf(
                                order,
                                includePayment: false);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color:
                                kGold.withOpacity(0.4)),
                            foregroundColor: kGold,
                            backgroundColor: kGoldLight,
                            padding:
                            const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                              Icons.person_outline),
                          label: const Text(
                              'Ring Maker Sheet',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                  FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4),
                        child: Text(
                          'Order details only — payment info hidden',
                          style: TextStyle(
                              fontSize: 11,
                              color: kTextSub),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: kTextSub),
            onSelected: (value) async {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          EditOrderScreen(order: order)),
                );
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: kCard,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(16)),
                    title: const Text('Delete Order',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: kText)),
                    content: const Text(
                        'Are you sure you want to delete this order?',
                        style: TextStyle(color: kTextSub)),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        child: Text('Cancel',
                            style: TextStyle(
                                color: kTextSub)),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(
                                color: Color(0xFFDC2626))),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await orderService.deleteOrder(order.id);
                  if (context.mounted)
                    Navigator.pop(context);
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Order')),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Order')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (order.isUrgent) _buildUrgentBanner(),
          if (_isDueSoon) _buildDueSoonBanner(),
          _buildStatusCard(context, orderService),
          const SizedBox(height: 12),
          _buildInfoCard('Customer Information', [
            _infoRow('Name', order.customerName),
            _infoRow('Mobile', order.mobileNumber),
          ]),
          const SizedBox(height: 12),
          _buildInfoCard('Order Details', [
            _infoRow('Making Type', order.makingType),
            _infoRow('Stone Type', order.stoneType),
            _infoRow('Size', order.size),
            _infoRow('Ring Maker', order.ringMakerName),
          ]),
          const SizedBox(height: 12),
          _buildInfoCard('Payment', [
            _infoRow('Total Amount',
                '₹${order.totalAmount.toStringAsFixed(0)}'),
            _infoRow('Advanced',
                '₹${order.advancedAmount.toStringAsFixed(0)}'),
            _infoRow(
                'Balance Due',
                '₹${order.balanceAmount.toStringAsFixed(0)}',
                valueColor: const Color(0xFFDC2626)),
          ]),
          const SizedBox(height: 12),
          _buildInfoCard('Dates', [
            _infoRow('Order Date',
                DateFormat('dd/MM/yyyy').format(order.orderDate)),
            _infoRow(
                'Expected Delivery',
                DateFormat('dd/MM/yyyy')
                    .format(order.expectedDelivery),
                valueColor: _isDueSoon
                    ? const Color(0xFFD97706)
                    : null),
          ]),
          if (order.noteToMaker.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoCard('Note to Ring Maker', [
              Text(order.noteToMaker,
                  style: const TextStyle(
                      fontSize: 13, color: kTextSub)),
            ]),
          ],
          if (order.modelImageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoCard('Model Reference', [
              Text(order.modelImageUrl,
                  style: const TextStyle(
                      fontSize: 13, color: kGold)),
            ]),
          ],
          if (order.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildImagesCard(context),
          ],
          const SizedBox(height: 12),
          _buildRemarkCard(context, orderService),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUrgentBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFDC2626).withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.priority_high,
              color: Color(0xFFDC2626), size: 18),
          SizedBox(width: 8),
          Text('URGENT ORDER',
              style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildDueSoonBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFD97706).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule,
              color: Color(0xFFD97706), size: 18),
          const SizedBox(width: 8),
          Text(
            _daysLeft == 0
                ? 'Due TODAY!'
                : 'Due in $_daysLeft day${_daysLeft == 1 ? '' : 's'}',
            style: const TextStyle(
                color: Color(0xFFD97706),
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
      BuildContext context, OrderService orderService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: kGold.withOpacity(0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: kGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text('ORDER STATUS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B7109),
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: [OrderStatus.pending, OrderStatus.ready]
                .map((status) {
              final isSelected = order.status == status ||
                  (status == OrderStatus.ready && OrderStatus.isReady(order.status));
              final color = status == OrderStatus.ready
                  ? const Color(0xFF16A34A)
                  : kGold;
              final label = status == OrderStatus.ready ? 'Ready' : 'Pending';
              return SizedBox(
                width: 120,
                child: GestureDetector(
                  onTap: isSelected
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Confirm Status Change', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              content: Text(
                                'Change order status to "$label"?',
                                style: const TextStyle(fontSize: 14),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B6350))),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            orderService.updateStatus(order.id, status);
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected ? null : Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : color,
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
      ),
    );
  }

  Widget _buildImagesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: kGold.withOpacity(0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: kGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text('MODEL IMAGES',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B7109),
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: order.imageUrls.length,
            itemBuilder: (context, index) =>
                GestureDetector(
                  onTap: () =>
                      _showFullImage(context, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
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
                              strokeWidth: 2,
                              color: kGold)),
                      errorBuilder: (_, __, ___) => Container(
                        color: kGoldLight,
                        child: const Icon(
                            Icons.broken_image_outlined,
                            color: kGold),
                      ),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, int initialIndex) {
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
                        loadingBuilder: (context, child,
                            progress) =>
                        progress == null
                            ? child
                            : const Center(
                            child:
                            CircularProgressIndicator(
                                color:
                                Colors.white)),
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

  Widget _buildRemarkCard(
      BuildContext context, OrderService orderService) {
    final remarkController =
    TextEditingController(text: order.makerRemark);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: kGold.withOpacity(0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: kGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text('RING MAKER REMARK',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B7109),
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: remarkController,
            maxLines: 3,
            style:
            const TextStyle(fontSize: 14, color: kText),
            decoration: InputDecoration(
              hintText: 'Add remark or update...',
              hintStyle:
              const TextStyle(color: Color(0xFFB4AE9E)),
              filled: true,
              fillColor: kBg,
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await orderService.updateMakerRemark(
                    order.id, remarkController.text);
                if (context.mounted) {
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Save Remark',
                  style: TextStyle(
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: kGold.withOpacity(0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: kGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(title.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B7109),
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    color: kTextSub, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? kText)),
          ),
        ],
      ),
    );
  }
}
