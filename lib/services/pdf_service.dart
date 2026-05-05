import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart';
import 'package:android_intent_plus/android_intent.dart';

class PdfService {
  Future<void> generateOrderPdf(OrderModel order,
      {bool includePayment = true}) async {
    final pdf = pw.Document();

    final List<pw.ImageProvider> images = [];
    for (final url in order.imageUrls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          images.add(pw.MemoryImage(response.bodyBytes));
        }
      } catch (e) {
        // skip
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1A1814'),
              borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(10)),
            ),
            child: pw.Row(
              mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Ring Tracker',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 22,
                            fontWeight:
                            pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Order Details',
                        style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 13)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.end,
                  children: [
                    if (order.isUrgent)
                      pw.Container(
                        padding: const pw.EdgeInsets
                            .symmetric(
                            horizontal: 10,
                            vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex(
                              '#EF4444'),
                          borderRadius:
                          const pw.BorderRadius.all(
                              pw.Radius.circular(
                                  20)),
                        ),
                        child: pw.Text('URGENT',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 11,
                                fontWeight:
                                pw.FontWeight
                                    .bold)),
                      ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10),
                    ),
                    if (!includePayment)
                      pw.Container(
                        margin: const pw.EdgeInsets
                            .only(top: 4),
                        padding: const pw.EdgeInsets
                            .symmetric(
                            horizontal: 8,
                            vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex(
                              '#B8960C'),
                          borderRadius:
                          const pw.BorderRadius.all(
                              pw.Radius.circular(
                                  20)),
                        ),
                        child: pw.Text('For Ring Maker',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 9,
                                fontWeight:
                                pw.FontWeight
                                    .bold)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildSection('Customer Information', [
            _buildRow(
                'Order Number',
                order.orderNumber.isNotEmpty
                    ? order.orderNumber
                    : '#${order.id.substring(0, 6).toUpperCase()}'),
            _buildRow(
                'Customer Name', order.customerName),
            _buildRow(
                'Mobile Number', order.mobileNumber),
          ]),
          pw.SizedBox(height: 12),
          _buildSection('Order Details', [
            _buildRow('Making Type', order.makingType),
            _buildRow('Stone Type', order.stoneType),
            _buildRow('Size', order.size),
            _buildRow('Ring Maker', order.ringMakerName),
          ]),
          pw.SizedBox(height: 12),
          if (includePayment) ...[
            _buildSection('Payment Details', [
              _buildRow('Total Amount',
                  '₹${order.totalAmount.toStringAsFixed(0)}'),
              _buildRow('Advanced Paid',
                  '₹${order.advancedAmount.toStringAsFixed(0)}'),
              _buildRow('Balance Due',
                  '₹${order.balanceAmount.toStringAsFixed(0)}',
                  valueColor:
                  PdfColor.fromHex('#EF4444')),
            ]),
            pw.SizedBox(height: 12),
          ],
          _buildSection('Dates & Status', [
            _buildRow('Order Date',
                DateFormat('dd/MM/yyyy')
                    .format(order.orderDate)),
            _buildRow('Expected Delivery',
                DateFormat('dd/MM/yyyy')
                    .format(order.expectedDelivery)),
            _buildRow(
                'Current Status',
                order.status == 'in_progress'
                    ? 'In Progress'
                    : order.status == 'rework'
                    ? 'Return / Rework'
                    : order.status[0].toUpperCase() +
                    order.status.substring(1)),
          ]),
          if (order.noteToMaker.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildSection('Note', [
              pw.Text(order.noteToMaker,
                  style: const pw.TextStyle(
                      fontSize: 12)),
            ]),
          ],
          if (order.modelImageUrl.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildSection('Model Reference', [
              pw.Text(order.modelImageUrl,
                  style: const pw.TextStyle(
                      fontSize: 12)),
            ]),
          ],
          if (order.makerRemark.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildSection('Ring Maker Remark', [
              pw.Text(order.makerRemark,
                  style: const pw.TextStyle(
                      fontSize: 12)),
            ]),
          ],
          if (images.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColor.fromHex('#E8E4DC'),
                    width: 0.5),
                borderRadius:
                const pw.BorderRadius.all(
                    pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment:
                pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('MODEL IMAGES',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight:
                          pw.FontWeight.bold,
                          color: PdfColor.fromHex(
                              '#B8960C'),
                          letterSpacing: 0.8)),
                  pw.SizedBox(height: 12),
                  ...images.map((img) => pw.Column(
                    children: [
                      pw.Container(
                          width: double.infinity,
                          height: 300,
                          child: pw.Image(img,
                              fit: pw.BoxFit
                                  .contain)),
                      pw.SizedBox(height: 12),
                    ],
                  )),
                ],
              ),
            ),
          ],
          pw.SizedBox(height: 20),
          pw.Divider(
              color: PdfColor.fromHex('#E8E4DC')),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Ring Tracker • Gemstone Order Management',
              style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );

    final fileName = includePayment
        ? '${order.customerName}_full_order.pdf'
        : '${order.customerName}_maker_order.pdf';

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: fileName,
    );
  }

  Future<void> generateAndShareCustomerPdf(
      OrderModel order) async {
    final pdf = pw.Document();

    final List<pw.ImageProvider> images = [];
    for (final url in order.imageUrls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          images.add(pw.MemoryImage(response.bodyBytes));
        }
      } catch (e) {
        // skip
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1A1814'),
              borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(10)),
            ),
            child: pw.Row(
              mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Ring Tracker',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 22,
                            fontWeight:
                            pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Order Confirmation',
                        style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 13)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets
                          .symmetric(
                          horizontal: 12,
                          vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex(
                            '#B8960C'),
                        borderRadius:
                        const pw.BorderRadius.all(
                            pw.Radius.circular(
                                20)),
                      ),
                      child: pw.Text(
                        order.orderNumber.isNotEmpty
                            ? order.orderNumber
                            : '#${order.id.substring(0, 6).toUpperCase()}',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 13,
                            fontWeight:
                            pw.FontWeight.bold),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      DateFormat('dd/MM/yyyy')
                          .format(DateTime.now()),
                      style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FBF6E6'),
              borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(10)),
              border: pw.Border.all(
                  color: PdfColor.fromHex('#E8D48B'),
                  width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment:
              pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Dear ${order.customerName},',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color:
                      PdfColor.fromHex('#1A1814')),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Thank you for your order! Here are your order details. We will notify you once your order is ready.',
                  style: pw.TextStyle(
                      fontSize: 12,
                      color:
                      PdfColor.fromHex('#5C5648')),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _buildSection('Order Details', [
            _buildRow(
                'Order Number',
                order.orderNumber.isNotEmpty
                    ? order.orderNumber
                    : '#${order.id.substring(0, 6).toUpperCase()}'),
            _buildRow('Making Type', order.makingType),
            _buildRow('Stone Type', order.stoneType),
            _buildRow('Size', order.size),
          ]),
          pw.SizedBox(height: 12),
          _buildSection('Payment Details', [
            _buildRow('Total Amount',
                '₹${order.totalAmount.toStringAsFixed(0)}'),
            _buildRow('Advanced Paid',
                '₹${order.advancedAmount.toStringAsFixed(0)}',
                valueColor:
                PdfColor.fromHex('#059669')),
            _buildRow(
                'Balance Due',
                '₹${order.balanceAmount.toStringAsFixed(0)}',
                valueColor: order.balanceAmount > 0
                    ? PdfColor.fromHex('#EF4444')
                    : PdfColor.fromHex('#059669')),
          ]),
          pw.SizedBox(height: 12),
          _buildSection('Dates', [
            _buildRow('Order Date',
                DateFormat('dd/MM/yyyy')
                    .format(order.orderDate)),
            _buildRow('Expected Delivery',
                DateFormat('dd/MM/yyyy')
                    .format(order.expectedDelivery)),
          ]),
          if (order.modelImageUrl.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildSection('Model Reference', [
              pw.Text(order.modelImageUrl,
                  style: const pw.TextStyle(
                      fontSize: 12)),
            ]),
          ],
          if (images.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColor.fromHex('#E8D48B'),
                    width: 0.5),
                borderRadius:
                const pw.BorderRadius.all(
                    pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment:
                pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('MODEL IMAGES',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight:
                          pw.FontWeight.bold,
                          color: PdfColor.fromHex(
                              '#B8960C'),
                          letterSpacing: 0.8)),
                  pw.SizedBox(height: 12),
                  ...images.map((img) => pw.Column(
                    children: [
                      pw.Container(
                          width: double.infinity,
                          height: 300,
                          child: pw.Image(img,
                              fit: pw.BoxFit
                                  .contain)),
                      pw.SizedBox(height: 12),
                    ],
                  )),
                ],
              ),
            ),
          ],
          pw.SizedBox(height: 20),
          pw.Divider(
              color: PdfColor.fromHex('#E8D48B')),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Ring Tracker • Gemstone Order Management • Thank you for your business!',
              style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromHex('#B8960C')),
            ),
          ),
        ],
      ),
    );

    final Uint8List pdfBytes = await pdf.save();

    final tempDir = await getTemporaryDirectory();

    final safeName = order.customerName
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    final file = File(
      '${tempDir.path}/${safeName}_order_confirmation.pdf',
    );

    await file.writeAsBytes(pdfBytes);

    final phone = order.mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');

    final intent = AndroidIntent(
      action: 'android.intent.action.SEND',
      type: 'application/pdf',
      package: 'com.whatsapp.w4b',
      arguments: {
        'android.intent.extra.STREAM': file.uri.toString(),
        'android.intent.extra.TEXT':
        'Hello ${order.customerName}! 🙏\n'
            'Your order ${order.orderNumber} has been placed successfully.\n'
            'Please find your order confirmation PDF attached.\n\n'
            'Thank you for choosing Click Gems! 💎',
        'jid': '91$phone@s.whatsapp.net',
      },
    );

    await intent.launch();
  }

  Future<void> generateAllOrdersPdf(
      List<OrderModel> orders) async {
    final pdf = pw.Document();

    final urgent = orders
        .where((o) =>
    o.isUrgent && o.status != 'completed')
        .toList();
    final pending = orders
        .where((o) =>
    !o.isUrgent && o.status == 'pending')
        .toList();
    final inProgress = orders
        .where((o) =>
    !o.isUrgent && o.status == 'in_progress')
        .toList();
    final completed = orders
        .where((o) => o.status == 'completed')
        .toList();
    final overdue = orders
        .where((o) =>
    o.expectedDelivery
        .isBefore(DateTime.now()) &&
        o.status != 'completed')
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1A1814'),
              borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(10)),
            ),
            child: pw.Row(
              mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Ring Tracker',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 22,
                            fontWeight:
                            pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('All Orders Report',
                        style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 13)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 11),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Total Orders: ${orders.length}',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 11,
                          fontWeight:
                          pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                  color: PdfColor.fromHex('#E8D48B'),
                  width: 0.5),
              borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment:
              pw.MainAxisAlignment.spaceAround,
              children: [
                _summaryItem(
                    'Urgent', urgent.length, '#EF4444'),
                _summaryItem(
                    'Pending',
                    pending.length +
                        inProgress.length,
                    '#B8960C'),
                _summaryItem('Completed',
                    completed.length, '#059669'),
                _summaryItem('Overdue',
                    overdue.length, '#DC2626'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          if (urgent.isNotEmpty) ...[
            _buildPdfSectionHeader(
                'URGENT ORDERS', '#EF4444'),
            pw.SizedBox(height: 8),
            _buildOrdersTable(urgent),
            pw.SizedBox(height: 16),
          ],
          if (overdue.isNotEmpty) ...[
            _buildPdfSectionHeader(
                'OVERDUE ORDERS', '#DC2626'),
            pw.SizedBox(height: 8),
            _buildOrdersTable(overdue),
            pw.SizedBox(height: 16),
          ],
          if (pending.isNotEmpty ||
              inProgress.isNotEmpty) ...[
            _buildPdfSectionHeader(
                'PENDING ORDERS', '#B8960C'),
            pw.SizedBox(height: 8),
            _buildOrdersTable(
                [...pending, ...inProgress]),
            pw.SizedBox(height: 16),
          ],
          if (completed.isNotEmpty) ...[
            _buildPdfSectionHeader(
                'COMPLETED ORDERS', '#059669'),
            pw.SizedBox(height: 8),
            _buildOrdersTable(completed),
            pw.SizedBox(height: 16),
          ],
          pw.Divider(
              color: PdfColor.fromHex('#E8D48B')),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Ring Tracker • Gemstone Order Management • ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
      'all_orders_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.pdf',
    );
  }

  pw.Widget _summaryItem(
      String label, int count, String color) {
    return pw.Column(
      children: [
        pw.Text(
          count.toString(),
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex(color),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(label,
            style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey)),
      ],
    );
  }

  pw.Widget _buildPdfSectionHeader(
      String title, String color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex(color).shade(0.15),
        borderRadius: const pw.BorderRadius.all(
            pw.Radius.circular(6)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 14,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex(color),
              borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(2)),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex(color),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildOrdersTable(
      List<OrderModel> orders) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColor.fromHex('#E8D48B'),
        width: 0.5,
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(1.3),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#FBF6E6'),
          ),
          children: [
            _tableHeader('Customer'),
            _tableHeader('Type'),
            _tableHeader('Stone'),
            _tableHeader('Maker'),
            _tableHeader('Total'),
            _tableHeader('Balance'),
            _tableHeader('Delivery'),
          ],
        ),
        ...orders.map((order) => pw.TableRow(
          decoration: pw.BoxDecoration(
            color: orders.indexOf(order) % 2 == 0
                ? PdfColors.white
                : PdfColor.fromHex('#FFFDF7'),
          ),
          children: [
            _tableCell(order.customerName),
            _tableCell(order.makingType),
            _tableCell(order.stoneType),
            _tableCell(order.ringMakerName),
            _tableCell(
                '₹${order.totalAmount.toStringAsFixed(0)}'),
            _tableCellColored(
              '₹${order.balanceAmount.toStringAsFixed(0)}',
              order.balanceAmount > 0
                  ? PdfColor.fromHex('#DC2626')
                  : PdfColor.fromHex('#059669'),
            ),
            _tableCell(DateFormat('dd/MM/yy')
                .format(order.expectedDelivery)),
          ],
        )),
      ],
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 6, vertical: 6),
      child: pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#8B7109'),
        ),
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  pw.Widget _tableCellColored(
      String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: color),
      ),
    );
  }

  pw.Widget _buildSection(
      String title, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
            color: PdfColor.fromHex('#E8D48B'),
            width: 0.5),
        borderRadius: const pw.BorderRadius.all(
            pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding:
            const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 3,
                  height: 12,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#B8960C'),
                    borderRadius:
                    const pw.BorderRadius.all(
                        pw.Radius.circular(2)),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color:
                    PdfColor.fromHex('#8B7109'),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _buildRow(String label, String value,
      {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color:
                  valueColor ?? PdfColors.black,
                )),
          ),
        ],
      ),
    );
  }
}
