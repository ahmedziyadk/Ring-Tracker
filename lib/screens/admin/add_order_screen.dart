import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_service.dart';
import '../../services/order_service.dart';

class AddOrderScreen extends StatefulWidget {
  final bool isOfficeOrder;

  const AddOrderScreen({super.key, this.isOfficeOrder = false});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final OrderService _orderService = OrderService();
  final ImageService _imageService = ImageService();

  static const Color kGold = Color(0xFFB8960C);
  static const Color kGoldLight = Color(0xFFFBF6E6);
  static const Color kBg = Color(0xFFFAFAF8);
  static const Color kCard = Colors.white;
  static const Color kText = Color(0xFF1A1814);
  static const Color kTextSub = Color(0xFF6B6350);
  static const Color kBorder = Color(0xFFE8E4DC);

  final _customerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _stoneTypeController = TextEditingController();
  final _sizeController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _advancedAmountController = TextEditingController();
  final _modelImageController = TextEditingController();
  final _noteController = TextEditingController();

  String _countryCode = '+91';

  final List<String> _countryCodes = [
    '+91',
    '+971',
    '+966',
    '+974',
    '+965',
    '+968',
    '+973',
  ];

  String _makingType = 'Ring';
  bool _isUrgent = false;
  DateTime _orderDate = DateTime.now();
  DateTime _expectedDelivery = DateTime.now().add(const Duration(days: 20));
  String? _selectedMakerId;
  String? _selectedMakerName;
  bool _isLoading = false;
  final List<String> _imageUrls = [];
  bool _uploadingImage = false;
  bool _customerNameEditable = true;

  final List<String> _makingTypes = [
    'Ring',
    'Bracelet',
    'Pendant',
    'Necklace',
    'Earring',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isOfficeOrder) {
      _customerNameEditable = false;
      _loadOfficeCustomerName();
    }
  }

  Future<void> _loadOfficeCustomerName() async {
    final name = await _orderService.generateNextOfficeCustomerName();
    if (!mounted || _customerNameEditable) return;
    setState(() => _customerNameController.text = name);
  }

  void _enableCustomerNameEdit() {
    if (!widget.isOfficeOrder || _customerNameEditable) return;
    setState(() => _customerNameEditable = true);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _mobileController.dispose();
    _stoneTypeController.dispose();
    _sizeController.dispose();
    _totalAmountController.dispose();
    _advancedAmountController.dispose();
    _modelImageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _customerPhoneWithCountryCode() {
    final phone = _mobileController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) return '';

    final code = _countryCode.replaceAll('+', '');
    return '+$code$phone';
  }

  Future<Account?> _chooseContactAccount(List<Account> accounts) async {
    if (accounts.isEmpty) return null;
    if (accounts.length == 1) return accounts.first;

    return showModalBottomSheet<Account>(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Save contact to',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: kText,
                  ),
                ),
              ),
              ...accounts.map(
                (account) => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kGoldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_circle_outlined, color: kGold),
                  ),
                  title: Text(
                    account.name.isNotEmpty ? account.name : account.type,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                  subtitle: Text(
                    account.type,
                    style: const TextStyle(color: kTextSub),
                  ),
                  onTap: () => Navigator.pop(context, account),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _savePhoneContact() async {
    final name = _customerNameController.text.trim();
    if (widget.isOfficeOrder && !_customerNameEditable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap the generated customer name to edit before saving contact.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final phone = _customerPhoneWithCountryCode();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter customer name and mobile number first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final status = await FlutterContacts.permissions.request(
      PermissionType.readWrite,
    );

    if (status != PermissionStatus.granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contacts permission denied.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final accounts = await FlutterContacts.accounts.getAll();
    if (!mounted) return;

    final selectedAccount = await _chooseContactAccount(accounts);
    if (!mounted) return;

    if (accounts.isNotEmpty && selectedAccount == null) {
      return;
    }

    if (accounts.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No contact save location found on this phone.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final contact = Contact(
      name: Name(first: name),
      phones: [
        Phone(number: phone),
      ],
    );

    await FlutterContacts.create(contact, account: selectedAccount);

    if (!mounted) return;
    final saveLocation = selectedAccount?.name.isNotEmpty == true
        ? selectedAccount!.name
        : selectedAccount?.type ?? 'contacts';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact saved to $saveLocation.'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }


  Future<void> _selectDate(BuildContext context, bool isOrderDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isOrderDate ? _orderDate : _expectedDelivery,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kGold),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isOrderDate) {
          _orderDate = picked;
        } else {
          _expectedDelivery = picked;
        }
      });
    }
  }

  Future<void> _openWhatsAppWithOrderLink(OrderModel savedOrder) async {
    final phone = savedOrder.mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) return;

    final code = _countryCode.replaceAll('+', '');

    final orderLink =
        'https://gemstone-orders.web.app/?orderId=${savedOrder.id}&token=${savedOrder.customerToken}';

    final message = '''
Hello ${savedOrder.customerName},

Your Click Gems order is confirmed.

Order No: ${savedOrder.orderNumber}
Stone: ${savedOrder.stoneType}
Making: ${savedOrder.makingType}
Ring Size: ${savedOrder.size}

View your order details here:
$orderLink

Thank you for choosing Click Gems.
''';

    final whatsappUrl = Uri.parse(
      'https://wa.me/$code$phone?text=${Uri.encodeComponent(message)}',
    );

    if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open WhatsApp');
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMakerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a ring maker')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      var customerName = _customerNameController.text.trim();
      if (widget.isOfficeOrder && !_customerNameEditable) {
        customerName = await _orderService.reserveNextOfficeCustomerName();
        _customerNameController.text = customerName;
      }

      final order = OrderModel(
        id: '',
        orderNumber: '',
        customerToken: '',
        customerName: customerName,
        mobileNumber: _mobileController.text.trim(),
        makingType: _makingType,
        stoneType: _stoneTypeController.text.trim(),
        size: _sizeController.text.trim(),
        ringMakerId: _selectedMakerId!,
        ringMakerName: _selectedMakerName!,
        totalAmount: double.parse(_totalAmountController.text.trim()),
        advancedAmount: double.parse(_advancedAmountController.text.trim()),
        modelImageUrl: _modelImageController.text.trim(),
        imageUrls: _imageUrls,
        noteToMaker: _noteController.text.trim(),
        isUrgent: _isUrgent,
        orderDate: _orderDate,
        expectedDelivery: _expectedDelivery,
        status: 'pending',
        makerRemark: '',
        createdBy: authProvider.user?.uid ?? '',
        createdByRole: widget.isOfficeOrder ? 'office' : authProvider.role,
      );

      final docRef = await _orderService.addOrder(order);
      final savedDoc = await docRef.get();
      final savedOrder = OrderModel.fromFirestore(savedDoc);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (_mobileController.text.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order added! Opening WhatsApp...'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 2),
          ),
        );

        await _openWhatsAppWithOrderLink(savedOrder);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order added successfully.'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 2),
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          child: Container(height: 1, color: kBorder.withOpacity(0.5)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isOfficeOrder ? 'Office Order' : 'New Order',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: kText,
              ),
            ),
            Text(
              'FILL IN ORDER DETAILS',
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF8A846E),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('Customer Information', [
              _buildCustomerNameField(),
              const SizedBox(height: 12),
              _buildPhoneNumberField(),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _savePhoneContact,
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                  label: const Text(
                    'Save Contact',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kGold,
                    backgroundColor: kGoldLight,
                    side: BorderSide(color: kGold.withOpacity(0.35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Order Details', [
              _buildDropdown(),
              const SizedBox(height: 12),
              _buildTextField(
                _stoneTypeController,
                'Stone Type',
                Icons.diamond_outlined,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _sizeController,
                'Size',
                Icons.straighten_outlined,
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Ring Maker', [_buildMakerDropdown()]),
            const SizedBox(height: 16),
            _buildSection('Payment', [
              _buildTextField(
                _totalAmountController,
                'Total Amount (â‚¹)',
                Icons.currency_rupee,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _advancedAmountController,
                'Advanced Amount (â‚¹)',
                Icons.currency_rupee,
                keyboardType: TextInputType.number,
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Additional Info', [
              _buildTextField(
                _modelImageController,
                'Model Description / Reference',
                Icons.note_outlined,
                required: false,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _noteController,
                'Note to Ring Maker',
                Icons.note_outlined,
                required: false,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildDateRow(),
              const SizedBox(height: 12),
              _buildUrgentToggle(),
            ]),
            const SizedBox(height: 16),
            _buildImageUpload(),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Add Order',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGold.withOpacity(0.12), width: 1),
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
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8B7109),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCustomerNameField() {
    final field = _buildTextField(
      _customerNameController,
      widget.isOfficeOrder && !_customerNameEditable
          ? 'Generated Customer Name'
          : 'Customer Name',
      Icons.person_outline,
      readOnly: widget.isOfficeOrder && !_customerNameEditable,
      suffixIcon: widget.isOfficeOrder && !_customerNameEditable
          ? const Icon(Icons.edit_outlined, color: Color(0xFF6B6350), size: 20)
          : null,
    );

    if (!widget.isOfficeOrder || _customerNameEditable) {
      return field;
    }

    return GestureDetector(
      onTap: _enableCustomerNameEdit,
      child: AbsorbPointer(child: field),
    );
  }
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        bool required = true,
        int maxLines = 1,
        bool readOnly = false,
        Widget? suffixIcon,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 14, color: kText, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B6350), fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: const Color(0xFF6B6350), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: kBg,
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
          borderSide: BorderSide(color: kGold.withOpacity(0.5), width: 1.5),
        ),
      ),
      validator: required
          ? (val) => val == null || val.isEmpty ? 'This field is required' : null
          : null,
    );
  }

  Widget _buildPhoneNumberField() {
    return Row(
      children: [
        SizedBox(
          width: 108,
          child: DropdownButtonFormField<String>(
            value: _countryCode,
            style: const TextStyle(fontSize: 14, color: kText, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Code',
              labelStyle: const TextStyle(color: Color(0xFF6B6350), fontWeight: FontWeight.w500),
              filled: true,
              fillColor: kBg,
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
                borderSide: BorderSide(
                  color: kGold.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
            items: _countryCodes
                .map(
                  (code) => DropdownMenuItem(
                value: code,
                child: Text(code),
              ),
            )
                .toList(),
            onChanged: (val) {
              setState(() {
                _countryCode = val!;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTextField(
            _mobileController,
            'Mobile Number',
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            required: false,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _makingType,
      style: const TextStyle(fontSize: 14, color: kText, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: 'Making Type',
        labelStyle: const TextStyle(color: Color(0xFF6B6350), fontWeight: FontWeight.w500),
        prefixIcon: const Icon(
          Icons.category_outlined,
          color: Color(0xFF6B6350),
          size: 20,
        ),
        filled: true,
        fillColor: kBg,
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
          borderSide: BorderSide(color: kGold.withOpacity(0.5), width: 1.5),
        ),
      ),
      items: _makingTypes
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: (val) => setState(() => _makingType = val!),
    );
  }

  Widget _buildMakerDropdown() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _orderService.getAllMakers(),
      builder: (context, snapshot) {
        final makers = snapshot.data ?? [];

        if (makers.isEmpty) {
          return const Text(
            'No makers found',
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w600),
          );
        }

        return DropdownButtonFormField<String>(
          value: _selectedMakerId,
          style: const TextStyle(fontSize: 14, color: kText, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Select Ring Maker',
            labelStyle: const TextStyle(color: Color(0xFF6B6350), fontWeight: FontWeight.w500),
            prefixIcon: const Icon(
              Icons.person_outline,
              color: Color(0xFF6B6350),
              size: 20,
            ),
            filled: true,
            fillColor: kBg,
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
              borderSide: BorderSide(color: kGold.withOpacity(0.5), width: 1.5),
            ),
          ),
          items: makers
              .map(
                (maker) => DropdownMenuItem(
              value: maker['id'] as String,
              child: Text(maker['name'] ?? ''),
            ),
          )
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedMakerId = val;
              _selectedMakerName =
              makers.firstWhere((m) => m['id'] == val)['name'];
            });
          },
          validator: (val) => val == null ? 'Please select a maker' : null,
        );
      },
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(context, true),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBg,
                border: Border.all(color: kGold.withOpacity(0.14)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ORDER DATE',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF6B6350),
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_orderDate.day.toString().padLeft(2, '0')}/${_orderDate.month.toString().padLeft(2, '0')}/${_orderDate.year}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(context, false),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBg,
                border: Border.all(color: kGold.withOpacity(0.14)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPECTED DELIVERY',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF6B6350),
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_expectedDelivery.day.toString().padLeft(2, '0')}/${_expectedDelivery.month.toString().padLeft(2, '0')}/${_expectedDelivery.year}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isUrgent = !_isUrgent),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isUrgent ? const Color(0xFFFEF2F2) : kBg,
          border: Border.all(
            color: _isUrgent
                ? const Color(0xFFDC2626).withOpacity(0.3)
                : kGold.withOpacity(0.14),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isUrgent ? const Color(0xFFFEE2E2) : kGoldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.priority_high,
                    color: _isUrgent ? const Color(0xFFDC2626) : kGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mark as Urgent',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isUrgent ? const Color(0xFFDC2626) : kText,
                      ),
                    ),
                    Text(
                      'Highlighted in red',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _isUrgent
                            ? const Color(0xFFDC2626).withOpacity(0.7)
                            : const Color(0xFF6B6350),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Switch(
              value: _isUrgent,
              onChanged: (val) => setState(() => _isUrgent = val),
              activeColor: const Color(0xFFDC2626),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUpload() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGold.withOpacity(0.12), width: 1),
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
              const Text(
                'MODEL IMAGES',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8B7109),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_imageUrls.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _imageUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: kGoldLight,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: kGold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _imageUrls.removeAt(index)),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_uploadingImage)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(color: kGold, strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      setState(() => _uploadingImage = true);
                      final urls = await _imageService.pickAndUploadMultipleImages(
                        'temp_${DateTime.now().millisecondsSinceEpoch}',
                      );
                      if (urls.isNotEmpty) {
                        setState(() => _imageUrls.addAll(urls));
                      }
                      setState(() => _uploadingImage = false);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kGold.withOpacity(0.4)),
                      foregroundColor: kGold,
                      backgroundColor: kGoldLight,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text(
                      'Gallery',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (!kIsWeb) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        setState(() => _uploadingImage = true);
                        final url = await _imageService.takeAndUploadPhoto(
                          'temp_${DateTime.now().millisecondsSinceEpoch}',
                        );
                        if (url != null) {
                          setState(() => _imageUrls.add(url));
                        }
                        setState(() => _uploadingImage = false);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kGold.withOpacity(0.4)),
                        foregroundColor: kGold,
                        backgroundColor: kGoldLight,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text(
                        'Camera',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}


