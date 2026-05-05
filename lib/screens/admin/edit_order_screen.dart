// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:intl/intl.dart';
// import '../../models/order_model.dart';
// import '../../services/order_service.dart';
// import '../../services/image_service.dart';
//
// class EditOrderScreen extends StatefulWidget {
//   final OrderModel order;
//   const EditOrderScreen({super.key, required this.order});
//
//   @override
//   State<EditOrderScreen> createState() =>
//       _EditOrderScreenState();
// }
//
// class _EditOrderScreenState extends State<EditOrderScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final OrderService _orderService = OrderService();
//   final ImageService _imageService = ImageService();
//
//   static const Color kGold = Color(0xFFB8960C);
//   static const Color kGoldLight = Color(0xFFFBF6E6);
//   static const Color kGoldBorder = Color(0xFFE8D48B);
//   static const Color kBg = Color(0xFFFAFAF8);
//   static const Color kCard = Colors.white;
//   static const Color kText = Color(0xFF1A1814);
//   static const Color kTextSub = Color(0xFF9C9685);
//   static const Color kBorder = Color(0xFFE8E4DC);
//
//   late TextEditingController _customerNameController;
//   late TextEditingController _mobileController;
//   late TextEditingController _stoneTypeController;
//   late TextEditingController _sizeController;
//   late TextEditingController _totalAmountController;
//   late TextEditingController _advancedAmountController;
//   late TextEditingController _modelImageController;
//   late TextEditingController _noteController;
//
//   late String _makingType;
//   late bool _isUrgent;
//   late DateTime _orderDate;
//   late DateTime _expectedDelivery;
//   late String _selectedMakerId;
//   late String _selectedMakerName;
//   late List<String> _imageUrls;
//   bool _isLoading = false;
//   bool _uploadingImage = false;
//
//   final List<String> _makingTypes = [
//     'Ring', 'Bracelet', 'Pendant', 'Necklace', 'Earring'
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _customerNameController =
//         TextEditingController(text: widget.order.customerName);
//     _mobileController =
//         TextEditingController(text: widget.order.mobileNumber);
//     _stoneTypeController =
//         TextEditingController(text: widget.order.stoneType);
//     _sizeController =
//         TextEditingController(text: widget.order.size);
//     _totalAmountController = TextEditingController(
//         text: widget.order.totalAmount.toStringAsFixed(0));
//     _advancedAmountController = TextEditingController(
//         text: widget.order.advancedAmount.toStringAsFixed(0));
//     _modelImageController =
//         TextEditingController(text: widget.order.modelImageUrl);
//     _noteController =
//         TextEditingController(text: widget.order.noteToMaker);
//     _makingType = widget.order.makingType;
//     _isUrgent = widget.order.isUrgent;
//     _orderDate = widget.order.orderDate;
//     _expectedDelivery = widget.order.expectedDelivery;
//     _selectedMakerId = widget.order.ringMakerId;
//     _selectedMakerName = widget.order.ringMakerName;
//     _imageUrls = List<String>.from(widget.order.imageUrls);
//   }
//
//   @override
//   void dispose() {
//     _customerNameController.dispose();
//     _mobileController.dispose();
//     _stoneTypeController.dispose();
//     _sizeController.dispose();
//     _totalAmountController.dispose();
//     _advancedAmountController.dispose();
//     _modelImageController.dispose();
//     _noteController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _selectDate(
//       BuildContext context, bool isOrderDate) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate:
//       isOrderDate ? _orderDate : _expectedDelivery,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//       builder: (context, child) => Theme(
//         data: Theme.of(context).copyWith(
//           colorScheme:
//           const ColorScheme.light(primary: kGold),
//         ),
//         child: child!,
//       ),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isOrderDate) {
//           _orderDate = picked;
//         } else {
//           _expectedDelivery = picked;
//         }
//       });
//     }
//   }
//
//   Future<void> _updateOrder() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _isLoading = true);
//     try {
//       await _orderService.updateOrder(widget.order.id, {
//         'customerName': _customerNameController.text.trim(),
//         'mobileNumber': _mobileController.text.trim(),
//         'makingType': _makingType,
//         'stoneType': _stoneTypeController.text.trim(),
//         'size': _sizeController.text.trim(),
//         'ringMakerId': _selectedMakerId,
//         'ringMakerName': _selectedMakerName,
//         'totalAmount':
//         double.parse(_totalAmountController.text),
//         'advancedAmount':
//         double.parse(_advancedAmountController.text),
//         'modelImageUrl': _modelImageController.text.trim(),
//         'imageUrls': _imageUrls,
//         'noteToMaker': _noteController.text.trim(),
//         'isUrgent': _isUrgent,
//         'orderDate': _orderDate,
//         'expectedDelivery': _expectedDelivery,
//       });
//       if (mounted) {
//         Navigator.pop(context);
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Order updated successfully!'),
//             backgroundColor: Color(0xFF16A34A),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text('Error: $e'),
//               backgroundColor: Colors.red),
//         );
//       }
//     }
//     setState(() => _isLoading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kBg,
//       appBar: AppBar(
//         backgroundColor: kBg,
//         foregroundColor: kText,
//         elevation: 0,
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(
//               height: 1,
//               color: kBorder.withOpacity(0.5)),
//         ),
//         title: const Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Edit Order',
//                 style: TextStyle(
//                     fontWeight: FontWeight.w700,
//                     fontSize: 16,
//                     color: kText)),
//             Text('UPDATE ORDER DETAILS',
//                 style: TextStyle(
//                     fontSize: 9,
//                     color: kTextSub,
//                     letterSpacing: 1.5,
//                     fontWeight: FontWeight.w600)),
//           ],
//         ),
//       ),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             _buildSection('Customer Information', [
//               _buildTextField(_customerNameController,
//                   'Customer Name', Icons.person_outline),
//               const SizedBox(height: 12),
//               _buildTextField(_mobileController,
//                   'Mobile Number', Icons.phone_outlined,
//                   keyboardType: TextInputType.phone),
//             ]),
//             const SizedBox(height: 16),
//             _buildSection('Order Details', [
//               _buildDropdown(),
//               const SizedBox(height: 12),
//               _buildTextField(_stoneTypeController,
//                   'Stone Type', Icons.diamond_outlined),
//               const SizedBox(height: 12),
//               _buildTextField(_sizeController, 'Size',
//                   Icons.straighten_outlined),
//             ]),
//             const SizedBox(height: 16),
//             _buildSection(
//                 'Ring Maker', [_buildMakerDropdown()]),
//             const SizedBox(height: 16),
//             _buildSection('Payment', [
//               _buildTextField(
//                 _totalAmountController,
//                 'Total Amount (₹)',
//                 Icons.currency_rupee,
//                 keyboardType: TextInputType.number,
//               ),
//               const SizedBox(height: 12),
//               _buildTextField(
//                 _advancedAmountController,
//                 'Advanced Amount (₹)',
//                 Icons.currency_rupee,
//                 keyboardType: TextInputType.number,
//               ),
//             ]),
//             const SizedBox(height: 16),
//             _buildSection('Additional Info', [
//               _buildTextField(
//                   _modelImageController,
//                   'Model Description / Reference',
//                   Icons.note_outlined,
//                   required: false),
//               const SizedBox(height: 12),
//               _buildTextField(
//                   _noteController,
//                   'Note to Ring Maker',
//                   Icons.note_outlined,
//                   required: false,
//                   maxLines: 3),
//               const SizedBox(height: 12),
//               _buildDateRow(),
//               const SizedBox(height: 12),
//               _buildUrgentToggle(),
//             ]),
//             const SizedBox(height: 16),
//             _buildImageUpload(),
//             const SizedBox(height: 24),
//             SizedBox(
//               height: 50,
//               child: ElevatedButton(
//                 onPressed:
//                 _isLoading ? null : _updateOrder,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: kGold,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius:
//                     BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: _isLoading
//                     ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: 2))
//                     : const Text('Update Order',
//                     style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600)),
//               ),
//             ),
//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSection(
//       String title, List<Widget> children) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: kCard,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//             color: kGold.withOpacity(0.12), width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 3,
//                 height: 14,
//                 decoration: BoxDecoration(
//                   color: kGold,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Text(title.toUpperCase(),
//                   style: const TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFF8B7109),
//                       letterSpacing: 1.5)),
//             ],
//           ),
//           const SizedBox(height: 14),
//           ...children,
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTextField(
//       TextEditingController controller,
//       String label,
//       IconData icon, {
//         TextInputType keyboardType = TextInputType.text,
//         bool required = true,
//         int maxLines = 1,
//       }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboardType,
//       maxLines: maxLines,
//       style: const TextStyle(fontSize: 14, color: kText),
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: const TextStyle(color: kTextSub),
//         prefixIcon:
//         Icon(icon, color: kTextSub, size: 20),
//         filled: true,
//         fillColor: kBg,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide:
//           BorderSide(color: kGold.withOpacity(0.14)),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide:
//           BorderSide(color: kGold.withOpacity(0.14)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//               color: kGold.withOpacity(0.5), width: 1.5),
//         ),
//       ),
//       validator: required
//           ? (val) => val == null || val.isEmpty
//           ? 'This field is required'
//           : null
//           : null,
//     );
//   }
//
//   Widget _buildDropdown() {
//     return DropdownButtonFormField<String>(
//       value: _makingType,
//       style: const TextStyle(fontSize: 14, color: kText),
//       decoration: InputDecoration(
//         labelText: 'Making Type',
//         labelStyle: const TextStyle(color: kTextSub),
//         prefixIcon: const Icon(Icons.category_outlined,
//             color: kTextSub, size: 20),
//         filled: true,
//         fillColor: kBg,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide:
//           BorderSide(color: kGold.withOpacity(0.14)),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide:
//           BorderSide(color: kGold.withOpacity(0.14)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//               color: kGold.withOpacity(0.5), width: 1.5),
//         ),
//       ),
//       items: _makingTypes
//           .map((type) => DropdownMenuItem(
//           value: type, child: Text(type)))
//           .toList(),
//       onChanged: (val) =>
//           setState(() => _makingType = val!),
//     );
//   }
//
//   Widget _buildMakerDropdown() {
//     return StreamBuilder<List<Map<String, dynamic>>>(
//       stream: _orderService.getAllMakers(),
//       builder: (context, snapshot) {
//         final makers = snapshot.data ?? [];
//         if (makers.isEmpty) {
//           return Text(_selectedMakerName,
//               style: const TextStyle(fontSize: 13));
//         }
//         return DropdownButtonFormField<String>(
//           value:
//           makers.any((m) => m['id'] == _selectedMakerId)
//               ? _selectedMakerId
//               : null,
//           style:
//           const TextStyle(fontSize: 14, color: kText),
//           decoration: InputDecoration(
//             labelText: 'Select Ring Maker',
//             labelStyle:
//             const TextStyle(color: kTextSub),
//             prefixIcon: const Icon(Icons.person_outline,
//                 color: kTextSub, size: 20),
//             filled: true,
//             fillColor: kBg,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                   color: kGold.withOpacity(0.14)),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                   color: kGold.withOpacity(0.14)),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                   color: kGold.withOpacity(0.5),
//                   width: 1.5),
//             ),
//           ),
//           items: makers
//               .map((maker) => DropdownMenuItem(
//             value: maker['id'] as String,
//             child: Text(maker['name'] ?? ''),
//           ))
//               .toList(),
//           onChanged: (val) {
//             setState(() {
//               _selectedMakerId = val!;
//               _selectedMakerName = makers
//                   .firstWhere((m) => m['id'] == val)['name'];
//             });
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildDateRow() {
//     return Row(
//       children: [
//         Expanded(
//           child: GestureDetector(
//             onTap: () => _selectDate(context, true),
//             child: Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: kBg,
//                 border: Border.all(
//                     color: kGold.withOpacity(0.14)),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 crossAxisAlignment:
//                 CrossAxisAlignment.start,
//                 children: [
//                   const Text('ORDER DATE',
//                       style: TextStyle(
//                           fontSize: 9,
//                           color: kTextSub,
//                           letterSpacing: 0.8,
//                           fontWeight: FontWeight.w600)),
//                   const SizedBox(height: 4),
//                   Text(
//                     DateFormat('dd/MM/yyyy')
//                         .format(_orderDate),
//                     style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: kText),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: GestureDetector(
//             onTap: () => _selectDate(context, false),
//             child: Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: kBg,
//                 border: Border.all(
//                     color: kGold.withOpacity(0.14)),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 crossAxisAlignment:
//                 CrossAxisAlignment.start,
//                 children: [
//                   const Text('EXPECTED DELIVERY',
//                       style: TextStyle(
//                           fontSize: 9,
//                           color: kTextSub,
//                           letterSpacing: 0.8,
//                           fontWeight: FontWeight.w600)),
//                   const SizedBox(height: 4),
//                   Text(
//                     DateFormat('dd/MM/yyyy')
//                         .format(_expectedDelivery),
//                     style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: kText),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildUrgentToggle() {
//     return GestureDetector(
//       onTap: () =>
//           setState(() => _isUrgent = !_isUrgent),
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: _isUrgent
//               ? const Color(0xFFFEF2F2)
//               : kBg,
//           border: Border.all(
//             color: _isUrgent
//                 ? const Color(0xFFDC2626)
//                 .withOpacity(0.3)
//                 : kGold.withOpacity(0.14),
//           ),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           mainAxisAlignment:
//           MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 36,
//                   height: 36,
//                   decoration: BoxDecoration(
//                     color: _isUrgent
//                         ? const Color(0xFFFEE2E2)
//                         : kGoldLight,
//                     borderRadius:
//                     BorderRadius.circular(10),
//                   ),
//                   child: Icon(Icons.priority_high,
//                       color: _isUrgent
//                           ? const Color(0xFFDC2626)
//                           : kGold,
//                       size: 20),
//                 ),
//                 const SizedBox(width: 12),
//                 Column(
//                   crossAxisAlignment:
//                   CrossAxisAlignment.start,
//                   children: [
//                     Text('Mark as Urgent',
//                         style: TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                             color: _isUrgent
//                                 ? const Color(0xFFDC2626)
//                                 : kText)),
//                     Text('Highlighted in red',
//                         style: TextStyle(
//                             fontSize: 11,
//                             color: _isUrgent
//                                 ? const Color(0xFFDC2626)
//                                 .withOpacity(0.7)
//                                 : kTextSub)),
//                   ],
//                 ),
//               ],
//             ),
//             Switch(
//               value: _isUrgent,
//               onChanged: (val) =>
//                   setState(() => _isUrgent = val),
//               activeColor: const Color(0xFFDC2626),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildImageUpload() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: kCard,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//             color: kGold.withOpacity(0.12), width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 3,
//                 height: 14,
//                 decoration: BoxDecoration(
//                   color: kGold,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               const Text('MODEL IMAGES',
//                   style: TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFF8B7109),
//                       letterSpacing: 1.5)),
//             ],
//           ),
//           const SizedBox(height: 14),
//           if (_imageUrls.isNotEmpty) ...[
//             GridView.builder(
//               shrinkWrap: true,
//               physics:
//               const NeverScrollableScrollPhysics(),
//               gridDelegate:
//               const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 3,
//                 crossAxisSpacing: 8,
//                 mainAxisSpacing: 8,
//               ),
//               itemCount: _imageUrls.length,
//               itemBuilder: (context, index) => Stack(
//                 children: [
//                   ClipRRect(
//                     borderRadius:
//                     BorderRadius.circular(10),
//                     child: Image.network(
//                       _imageUrls[index],
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       height: double.infinity,
//                       errorBuilder: (_, __, ___) =>
//                           Container(
//                             color: kGoldLight,
//                             child: const Icon(
//                                 Icons.broken_image_outlined,
//                                 color: kGold),
//                           ),
//                     ),
//                   ),
//                   Positioned(
//                     top: 4,
//                     right: 4,
//                     child: GestureDetector(
//                       onTap: () => setState(
//                               () => _imageUrls.removeAt(index)),
//                       child: Container(
//                         width: 22,
//                         height: 22,
//                         decoration: const BoxDecoration(
//                           color: Color(0xFFDC2626),
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(Icons.close,
//                             size: 13,
//                             color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 10),
//           ],
//           if (_uploadingImage)
//             Center(
//               child: Padding(
//                 padding:
//                 const EdgeInsets.symmetric(vertical: 8),
//                 child: CircularProgressIndicator(
//                     color: kGold, strokeWidth: 2),
//               ),
//             )
//           else
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () async {
//                       setState(
//                               () => _uploadingImage = true);
//                       final urls = await _imageService
//                           .pickAndUploadMultipleImages(
//                           'temp_${DateTime.now().millisecondsSinceEpoch}');
//                       if (urls.isNotEmpty) {
//                         setState(
//                                 () => _imageUrls.addAll(urls));
//                       }
//                       setState(
//                               () => _uploadingImage = false);
//                     },
//                     style: OutlinedButton.styleFrom(
//                       side: BorderSide(
//                           color: kGold.withOpacity(0.4)),
//                       foregroundColor: kGold,
//                       backgroundColor: kGoldLight,
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 10),
//                     ),
//                     icon: const Icon(
//                         Icons.photo_library_outlined,
//                         size: 18),
//                     label: const Text('Gallery'),
//                   ),
//                 ),
//                 if (!kIsWeb) ...[
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () async {
//                         setState(
//                                 () => _uploadingImage = true);
//                         final url = await _imageService
//                             .takeAndUploadPhoto(
//                             'temp_${DateTime.now().millisecondsSinceEpoch}');
//                         if (url != null) {
//                           setState(
//                                   () => _imageUrls.add(url));
//                         }
//                         setState(
//                                 () => _uploadingImage = false);
//                       },
//                       style: OutlinedButton.styleFrom(
//                         side: BorderSide(
//                             color: kGold.withOpacity(0.4)),
//                         foregroundColor: kGold,
//                         backgroundColor: kGoldLight,
//                         padding:
//                         const EdgeInsets.symmetric(
//                             vertical: 10),
//                       ),
//                       icon: const Icon(
//                           Icons.camera_alt_outlined,
//                           size: 18),
//                       label: const Text('Camera'),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//         ],
//       ),
//     );
//   }
// }





import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/image_service.dart';

class EditOrderScreen extends StatefulWidget {
  final OrderModel order;

  const EditOrderScreen({super.key, required this.order});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final OrderService _orderService = OrderService();
  final ImageService _imageService = ImageService();

  static const Color kGold = Color(0xFFB8960C);
  static const Color kGoldLight = Color(0xFFFBF6E6);
  static const Color kGoldBorder = Color(0xFFE8D48B);
  static const Color kBg = Color(0xFFFAFAF8);
  static const Color kCard = Colors.white;
  static const Color kText = Color(0xFF1A1814);
  static const Color kTextSub = Color(0xFF9C9685);
  static const Color kBorder = Color(0xFFE8E4DC);

  late TextEditingController _customerNameController;
  late TextEditingController _mobileController;
  late TextEditingController _stoneTypeController;
  late TextEditingController _sizeController;
  late TextEditingController _totalAmountController;
  late TextEditingController _advancedAmountController;
  late TextEditingController _modelImageController;
  late TextEditingController _noteController;

  String _countryCode = '+91';

  final List<String> _countryCodes = [
    '+91', // India
    '+971', // UAE
    '+966', // Saudi Arabia
    '+974', // Qatar
    '+965', // Kuwait
    '+968', // Oman
    '+973', // Bahrain
  ];

  late String _makingType;
  late bool _isUrgent;
  late DateTime _orderDate;
  late DateTime _expectedDelivery;
  late String _selectedMakerId;
  late String _selectedMakerName;
  late List<String> _imageUrls;
  bool _isLoading = false;
  bool _uploadingImage = false;

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

    _customerNameController =
        TextEditingController(text: widget.order.customerName);
    _mobileController = TextEditingController(text: widget.order.mobileNumber);
    _stoneTypeController = TextEditingController(text: widget.order.stoneType);
    _sizeController = TextEditingController(text: widget.order.size);
    _totalAmountController = TextEditingController(
      text: widget.order.totalAmount.toStringAsFixed(0),
    );
    _advancedAmountController = TextEditingController(
      text: widget.order.advancedAmount.toStringAsFixed(0),
    );
    _modelImageController =
        TextEditingController(text: widget.order.modelImageUrl);
    _noteController = TextEditingController(text: widget.order.noteToMaker);

    _makingType = widget.order.makingType;
    _isUrgent = widget.order.isUrgent;
    _orderDate = widget.order.orderDate;
    _expectedDelivery = widget.order.expectedDelivery;
    _selectedMakerId = widget.order.ringMakerId;
    _selectedMakerName = widget.order.ringMakerName;
    _imageUrls = List<String>.from(widget.order.imageUrls);
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

  Future<void> _updateOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _orderService.updateOrder(widget.order.id, {
        'customerName': _customerNameController.text.trim(),
        'mobileNumber': _mobileController.text.trim(),
        'makingType': _makingType,
        'stoneType': _stoneTypeController.text.trim(),
        'size': _sizeController.text.trim(),
        'ringMakerId': _selectedMakerId,
        'ringMakerName': _selectedMakerName,
        'totalAmount': double.parse(_totalAmountController.text.trim()),
        'advancedAmount': double.parse(_advancedAmountController.text.trim()),
        'modelImageUrl': _modelImageController.text.trim(),
        'imageUrls': _imageUrls,
        'noteToMaker': _noteController.text.trim(),
        'isUrgent': _isUrgent,
        'orderDate': _orderDate,
        'expectedDelivery': _expectedDelivery,
      });

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Order',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: kText,
              ),
            ),
            Text(
              'UPDATE ORDER DETAILS',
              style: TextStyle(
                fontSize: 9,
                color: kTextSub,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
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
              _buildTextField(
                _customerNameController,
                'Customer Name',
                Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildPhoneNumberField(),
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
                'Total Amount (₹)',
                Icons.currency_rupee,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _advancedAmountController,
                'Advanced Amount (₹)',
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
                onPressed: _isLoading ? null : _updateOrder,
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
                  'Update Order',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
                  fontWeight: FontWeight.w700,
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

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        bool required = true,
        int maxLines = 1,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: kText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextSub),
        prefixIcon: Icon(icon, color: kTextSub, size: 20),
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
            style: const TextStyle(fontSize: 14, color: kText),
            decoration: InputDecoration(
              labelText: 'Code',
              labelStyle: const TextStyle(color: kTextSub),
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
      style: const TextStyle(fontSize: 14, color: kText),
      decoration: InputDecoration(
        labelText: 'Making Type',
        labelStyle: const TextStyle(color: kTextSub),
        prefixIcon: const Icon(
          Icons.category_outlined,
          color: kTextSub,
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
          return Text(
            _selectedMakerName,
            style: const TextStyle(fontSize: 13),
          );
        }

        return DropdownButtonFormField<String>(
          value: makers.any((m) => m['id'] == _selectedMakerId)
              ? _selectedMakerId
              : null,
          style: const TextStyle(fontSize: 14, color: kText),
          decoration: InputDecoration(
            labelText: 'Select Ring Maker',
            labelStyle: const TextStyle(color: kTextSub),
            prefixIcon: const Icon(
              Icons.person_outline,
              color: kTextSub,
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
              _selectedMakerId = val!;
              _selectedMakerName =
              makers.firstWhere((m) => m['id'] == val)['name'];
            });
          },
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
                    style: TextStyle(
                      fontSize: 9,
                      color: kTextSub,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_orderDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
                    style: TextStyle(
                      fontSize: 9,
                      color: kTextSub,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_expectedDelivery),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
                        fontWeight: FontWeight.w600,
                        color: _isUrgent ? const Color(0xFFDC2626) : kText,
                      ),
                    ),
                    Text(
                      'Highlighted in red',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isUrgent
                            ? const Color(0xFFDC2626).withOpacity(0.7)
                            : kTextSub,
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
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
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
                    label: const Text('Gallery'),
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
                      label: const Text('Camera'),
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
