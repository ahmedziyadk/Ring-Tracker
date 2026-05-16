import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';

class ManageMakersScreen extends StatefulWidget {
  const ManageMakersScreen({super.key});

  @override
  State<ManageMakersScreen> createState() =>
      _ManageMakersScreenState();
}

class _ManageMakersScreenState
    extends State<ManageMakersScreen> {
  final OrderService _orderService = OrderService();

  static const Color kGold = Color(0xFFB8960C);
  static const Color kGoldLight = Color(0xFFFBF6E6);
  static const Color kGoldBorder = Color(0xFFE8D48B);
  static const Color kBg = Color(0xFFFAFAF8);
  static const Color kCard = Colors.white;
  static const Color kText = Color(0xFF1A1814);
  static const Color kTextSub = Color(0xFF9C9685);
  static const Color kBorder = Color(0xFFE8E4DC);

  void _showAddMakerDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final mobileController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: kCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: kGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Add Ring Maker',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: kText)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogTextField(
                controller: nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _dialogTextField(
                controller: emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _dialogTextField(
                controller: mobileController,
                label: 'WhatsApp Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setPasswordState) =>
                    _dialogTextField(
                      controller: passwordController,
                      label: 'Password',
                      icon: Icons.lock_outlined,
                      obscureText: obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: kTextSub,
                          size: 20,
                        ),
                        onPressed: () {
                          setDialogState(() =>
                          obscurePassword = !obscurePassword);
                        },
                      ),
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: kTextSub)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                if (nameController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    mobileController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                      content: Text(
                          'Please fill all fields')));
                  return;
                }
                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                      content: Text(
                          'Password must be at least 6 characters')));
                  return;
                }
                setDialogState(
                        () => isLoading = true);
                try {
                  final credential = await FirebaseAuth
                      .instance
                      .createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password:
                    passwordController.text.trim(),
                  );
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(credential.user!.uid)
                      .set({
                    'name': nameController.text.trim(),
                    'role': 'maker',
                    'email':
                    emailController.text.trim(),
                    'mobileNumber': mobileController.text.trim(),
                    'createdAt': Timestamp.now(),
                  });
                  await FirebaseAuth.instance
                      .signOut();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                      content: Text(
                          'Ring maker added! Please log in again.'),
                      backgroundColor:
                      Color(0xFF16A34A),
                    ));
                  }
                } on FirebaseAuthException catch (e) {
                  setDialogState(
                          () => isLoading = false);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(
                    content: Text(
                        e.message ?? 'Error occurred'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10)),
              ),
              child: isLoading
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2))
                  : const Text('Add Maker',
                  style: TextStyle(
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMakerDialog(Map<String, dynamic> maker) {
    final nameController =
    TextEditingController(text: maker['name'] ?? '');
    final mobileController =
    TextEditingController(text: maker['mobileNumber'] ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: kCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: kGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Edit Ring Maker',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: kText)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogTextField(
                controller: nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _dialogTextField(
                controller: mobileController,
                label: 'WhatsApp Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: kTextSub)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                if (nameController.text.isEmpty)
                  return;
                setDialogState(
                        () => isLoading = true);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(maker['id'])
                    .update({
                  'name': nameController.text.trim(),
                  'mobileNumber': mobileController.text.trim(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                    content: Text('Maker updated!'),
                    backgroundColor:
                    Color(0xFF16A34A),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10)),
              ),
              child: isLoading
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2))
                  : const Text('Update',
                  style: TextStyle(
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14, color: kText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextSub),
        prefixIcon: Icon(icon, color: kTextSub, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: kBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          BorderSide(color: kGold.withOpacity(0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          BorderSide(color: kGold.withOpacity(0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: kGold.withOpacity(0.5), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Manage Makers',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: kText)),
            Text('RING MAKER ACCOUNTS',
                style: TextStyle(
                    fontSize: 9,
                    color: kTextSub,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined,
                color: kGold, size: 22),
            tooltip: 'Add Maker',
            onPressed: _showAddMakerDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _orderService.getAllMakers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: kGold));
          }

          final makers = snapshot.data ?? [];

          if (makers.isEmpty) {
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
                        Icons.people_outline,
                        size: 36,
                        color: kGold),
                  ),
                  const SizedBox(height: 16),
                  const Text('No ring makers yet',
                      style: TextStyle(
                          color: kTextSub,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddMakerDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add First Maker',
                        style: TextStyle(
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: makers.length,
            itemBuilder: (context, index) {
              final maker = makers[index];
              return StreamBuilder<List<OrderModel>>(
                stream: _orderService
                    .getOrdersByMaker(maker['id']),
                builder: (context, orderSnapshot) {
                  final orders =
                      orderSnapshot.data ?? [];
                  final pending = orders
                      .where(
                          (o) => !OrderStatus.isReady(o.status))
                      .length;
                  final completed = orders
                      .where(
                          (o) => OrderStatus.isReady(o.status))
                      .length;
                  final urgent = orders
                      .where((o) =>
                  o.isUrgent &&
                      !OrderStatus.isReady(o.status))
                      .length;

                  return Container(
                    margin:
                    const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius:
                      BorderRadius.circular(18),
                      border: Border.all(
                          color: kGold.withOpacity(0.12),
                          width: 1),
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
                              color: kGold,
                              borderRadius:
                              const BorderRadius.only(
                                topLeft:
                                Radius.circular(18),
                                bottomLeft:
                                Radius.circular(18),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                          const EdgeInsets.fromLTRB(
                              16, 14, 14, 14),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: kGoldLight,
                                  borderRadius:
                                  BorderRadius.circular(
                                      14),
                                  border: Border.all(
                                      color: kGoldBorder,
                                      width: 1),
                                ),
                                child: Center(
                                  child: Text(
                                    (maker['name'] ??
                                        'M')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight:
                                        FontWeight.w700,
                                        color: kGold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(
                                      maker['name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight:
                                          FontWeight.w700,
                                          fontSize: 15,
                                          color: kText),
                                    ),
                                    const SizedBox(
                                        height: 3),
                                    Text(
                                      maker['email'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: kTextSub),
                                    ),
                                    if ((maker['mobileNumber'] ?? '')
                                        .toString()
                                        .isNotEmpty) ...[
                                      const SizedBox(
                                          height: 3),
                                      Text(
                                        maker['mobileNumber'],
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: kTextSub),
                                      ),
                                    ],
                                    const SizedBox(
                                        height: 8),
                                    Row(
                                      children: [
                                        _statPill(
                                            '${orders.length} total',
                                            kGold,
                                            kGoldLight,
                                            kGoldBorder),
                                        const SizedBox(
                                            width: 6),
                                        _statPill(
                                            '$pending pending',
                                            const Color(
                                                0xFFD97706),
                                            const Color(
                                                0xFFFFFBEB),
                                            const Color(
                                                0xFFD97706)),
                                        const SizedBox(
                                            width: 6),
                                        _statPill(
                                            '$completed ready',
                                            const Color(
                                                0xFF16A34A),
                                            const Color(
                                                0xFFF0FDF4),
                                            const Color(
                                                0xFF16A34A)),
                                      ],
                                    ),
                                    if (urgent > 0) ...[
                                      const SizedBox(
                                          height: 6),
                                      _statPill(
                                          '$urgent urgent',
                                          const Color(
                                              0xFFDC2626),
                                          const Color(
                                              0xFFFEF2F2),
                                          const Color(
                                              0xFFDC2626)),
                                    ],
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                    Icons.more_vert,
                                    color: kTextSub,
                                    size: 20),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditMakerDialog(
                                        maker);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                            Icons
                                                .edit_outlined,
                                            size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit Name'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMakerDialog,
        backgroundColor: kCard,
        foregroundColor: kGold,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: BorderSide(
              color: kGold.withOpacity(0.3), width: 1),
        ),
        icon: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: kGold,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add,
              color: Colors.white, size: 16),
        ),
        label: const Text('Add Maker',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF8B7109))),
      ),
    );
  }

  Widget _statPill(
      String label,
      Color textColor,
      Color bgColor,
      Color borderColor,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: borderColor.withOpacity(0.3), width: 1),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w600)),
    );
  }
}
