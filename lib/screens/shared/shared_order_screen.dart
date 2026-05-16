import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../models/shared_order_draft.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_service.dart';
import '../../services/order_service.dart';

class SharedOrderScreen extends StatefulWidget {
  final SharedOrderDraft draft;

  const SharedOrderScreen({super.key, required this.draft});

  @override
  State<SharedOrderScreen> createState() => _SharedOrderScreenState();
}

class _SharedOrderScreenState extends State<SharedOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();
  final _imageService = ImageService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _stoneController = TextEditingController();
  final _sizeController = TextEditingController();
  final _totalController = TextEditingController();
  final _advanceController = TextEditingController();
  final _noteController = TextEditingController();

  static const Color kGold = Color(0xFFB8960C);
  static const Color kBg = Color(0xFFFAFAF8);
  static const Color kText = Color(0xFF1A1814);
  static const Color kTextSub = Color(0xFF6B6350);

  String _makingType = 'Ring';
  String? _selectedMakerId;
  String? _selectedMakerName;
  bool _isUrgent = false;
  bool _isSaving = false;

  final _makingTypes = const [
    'Ring',
    'Bracelet',
    'Pendant',
    'Necklace',
    'Earring',
  ];

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _nameController.text = draft.customerName;
    _phoneController.text = draft.phoneNumber;
    _stoneController.text = draft.stoneType;
    _sizeController.text = draft.ringSize;
    _totalController.text = draft.totalAmount;
    _advanceController.text = draft.advanceAmount;
    _noteController.text = draft.note;
    _makingType = _makingTypes.contains(draft.makingType) ? draft.makingType : 'Ring';
    _isUrgent = draft.urgent;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _stoneController.dispose();
    _sizeController.dispose();
    _totalController.dispose();
    _advanceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMakerId == null || _selectedMakerName == null) {
      _showMessage('Select ring maker before creating order.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uploadKey = 'shared_${DateTime.now().millisecondsSinceEpoch}';
      final imageUrls = <String>[];

      for (final path in widget.draft.imagePaths) {
        final url = await _imageService.uploadSharedImage(path, uploadKey);
        if (url != null) imageUrls.add(url);
      }

      final now = DateTime.now();
      final order = OrderModel(
        id: '',
        orderNumber: '',
        customerToken: '',
        customerName: _nameController.text.trim(),
        mobileNumber: _phoneController.text.trim(),
        makingType: _makingType,
        stoneType: _stoneController.text.trim(),
        size: _sizeController.text.trim(),
        ringMakerId: _selectedMakerId!,
        ringMakerName: _selectedMakerName!,
        totalAmount: double.tryParse(_totalController.text.trim()) ?? 0,
        advancedAmount: double.tryParse(_advanceController.text.trim()) ?? 0,
        modelImageUrl: _noteController.text.trim(),
        imageUrls: imageUrls,
        noteToMaker: '',
        isUrgent: _isUrgent,
        orderDate: now,
        expectedDelivery: now.add(const Duration(days: 20)),
        status: 'pending',
        makerRemark: '',
        createdBy: authProvider.user?.uid ?? '',
        createdByRole: authProvider.role,
      );

      await _orderService.addOrder(order);

      if (!mounted) return;
      _showMessage('Order created successfully.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not create order: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(useMaterial3: true),
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          foregroundColor: kText,
          title: const Text(
            'Create Order',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              _buildImagePreview(),
              const SizedBox(height: 14),
              _buildMakerDropdown(),
              const SizedBox(height: 14),
              _field(_nameController, 'Customer name', Icons.person_outline),
              _field(_phoneController, 'Phone', Icons.phone_outlined,
                  keyboardType: TextInputType.phone, required: false),
              Row(
                children: [
                  Expanded(child: _buildTypeDropdown()),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_sizeController, 'Size', Icons.straighten)),
                ],
              ),
              _field(_stoneController, 'Stone', Icons.diamond_outlined),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _totalController,
                      'Total',
                      Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      _advanceController,
                      'Advance',
                      Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      required: false,
                    ),
                  ),
                ],
              ),
              _buildUrgentSwitch(),
              _field(
                _noteController,
                'Note',
                Icons.notes_outlined,
                required: false,
                maxLines: 3,
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _createOrder,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _isSaving ? 'Creating...' : 'CREATE ORDER',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final imagePaths = widget.draft.imagePaths;
    if (imagePaths.isEmpty) {
      return _panel(
        child: const Row(
          children: [
            Icon(Icons.image_not_supported_outlined, color: kTextSub),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No image received. You can still create the order.',
                style: TextStyle(color: kTextSub, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: FutureBuilder<Uint8List>(
          future: XFile(imagePaths.first).readAsBytes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const ColoredBox(
                color: Colors.white,
                child: Center(child: CircularProgressIndicator(color: kGold)),
              );
            }
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: const Text('Image preview unavailable'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMakerDropdown() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _orderService.getAllMakers(),
      builder: (context, snapshot) {
        final makers = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          value: _selectedMakerId,
          items: makers
              .map(
                (maker) => DropdownMenuItem<String>(
                  value: maker['id'] as String,
                  child: Text((maker['name'] ?? '').toString()),
                ),
              )
              .toList(),
          onChanged: (value) {
            final maker = makers.firstWhere((m) => m['id'] == value);
            setState(() {
              _selectedMakerId = value;
              _selectedMakerName = (maker['name'] ?? '').toString();
            });
          },
          validator: (value) => value == null ? 'Select ring maker' : null,
          decoration: _decoration('SELECT RING MAKER', Icons.handyman_outlined),
        );
      },
    );
  }

  Widget _buildTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _makingType,
        items: _makingTypes
            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
            .toList(),
        onChanged: (value) => setState(() => _makingType = value ?? 'Ring'),
        decoration: _decoration('Type', Icons.category_outlined),
      ),
    );
  }

  Widget _buildUrgentSwitch() {
    return _panel(
      child: SwitchListTile(
        value: _isUrgent,
        onChanged: (value) => setState(() => _isUrgent = value),
        contentPadding: EdgeInsets.zero,
        title: const Text('Urgent', style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle: const Text('Mark this order as urgent'),
        activeColor: const Color(0xFFDC2626),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: required
            ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
            : null,
        decoration: _decoration(label, icon),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E4DC)),
      ),
      child: child,
    );
  }
}
