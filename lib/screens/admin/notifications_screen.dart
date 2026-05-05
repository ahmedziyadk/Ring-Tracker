import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/order_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifications',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: kText)),
            Text('MAKER UPDATES',
                style: TextStyle(
                    fontSize: 9,
                    color: kTextSub,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                orderService.markAllNotificationsRead(),
            child: const Text('Mark all read',
                style: TextStyle(
                    color: kGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: orderService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: kGold));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
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
                        Icons.notifications_none_outlined,
                        size: 36,
                        color: kGold),
                  ),
                  const SizedBox(height: 16),
                  const Text('No notifications yet',
                      style: TextStyle(
                          color: kTextSub,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  const Text(
                      'Maker remarks will appear here',
                      style: TextStyle(
                          color: kTextSub, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              final isRead = n['isRead'] ?? false;
              final createdAt = n['createdAt'] != null
                  ? (n['createdAt'] as dynamic).toDate()
                  : DateTime.now();

              return GestureDetector(
                onTap: () => orderService
                    .markNotificationRead(n['id']),
                child: Container(
                  margin:
                  const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isRead ? kCard : kGoldLight,
                    borderRadius:
                    BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? kBorder.withOpacity(0.5)
                          : kGoldBorder,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (!isRead)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            decoration: BoxDecoration(
                              color: kGold,
                              borderRadius:
                              const BorderRadius.only(
                                topLeft:
                                Radius.circular(16),
                                bottomLeft:
                                Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            isRead ? 14 : 16, 14, 14, 14),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isRead
                                    ? kBg
                                    : kGoldLight,
                                borderRadius:
                                BorderRadius.circular(
                                    12),
                                border: Border.all(
                                  color: isRead
                                      ? kBorder
                                      : kGoldBorder,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                color: isRead
                                    ? kTextSub
                                    : kGold,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n['makerName'] ??
                                              'Ring Maker',
                                          style: TextStyle(
                                            fontWeight:
                                            FontWeight
                                                .w700,
                                            fontSize: 14,
                                            color: isRead
                                                ? kText
                                                : kGold,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration:
                                          const BoxDecoration(
                                            color: kGold,
                                            shape: BoxShape
                                                .circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    n['customerName'] !=
                                        null
                                        ? 'Order: ${n['customerName']}'
                                        : 'New remark',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: kTextSub),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding:
                                    const EdgeInsets
                                        .all(10),
                                    decoration:
                                    BoxDecoration(
                                      color: isRead
                                          ? kBg
                                          : Colors.white,
                                      borderRadius:
                                      BorderRadius
                                          .circular(10),
                                      border: Border.all(
                                        color: isRead
                                            ? kBorder
                                            : kGoldBorder
                                            .withOpacity(
                                            0.5),
                                      ),
                                    ),
                                    child: Text(
                                      n['message'] ??
                                          'No message',
                                      style:
                                      const TextStyle(
                                          fontSize: 13,
                                          color: kText),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat(
                                        'dd/MM/yyyy • HH:mm')
                                        .format(createdAt),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: kTextSub),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}