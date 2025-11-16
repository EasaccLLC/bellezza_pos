import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/receipt_model.dart';
import '../services/shared_preferences_service.dart';

class ReceiptWidget extends StatelessWidget {
  final ReceiptModel receiptModel;

  const ReceiptWidget({super.key, required this.receiptModel});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,   // RTL حقيقي
      child: Container(
        width: 200,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              _buildHeaderWithLogo(),
              const SizedBox(height: 6),
              const Divider(thickness: 2, color: Colors.black),
              _buildInvoiceInfo(),
              const SizedBox(height: 6),
              const Divider(thickness: 1, color: Colors.black),
              _buildProductsTable(),
              const SizedBox(height: 6),
              const Divider(thickness: 2, color: Colors.black),
              _buildTotalsSection(),
              const SizedBox(height: 6),
              _buildQrCodeSection(),
              const SizedBox(height: 6),
              const Divider(thickness: 2, color: Colors.black),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------

  Widget _buildHeaderWithLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_getCompanyData()['imageUrl'] != null &&
            _getCompanyData()['imageUrl'].toString().isNotEmpty)
          SizedBox(
            height: 60,
            child: Center(
              child: _buildCompanyLogo(
                _getFullImageUrl(_getCompanyData()['imageUrl']),
                _getCompanyData()['ar'] ??
                    receiptModel.vendorBranchName ??
                    'المتجر',
              ),
            ),
          ),

        const SizedBox(height: 4),

        Text(
          _getCompanyData()['ar'] ??
              receiptModel.vendorBranchName ??
              'المتجر',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 4),

        if (_getCompanyData()['location'] != null)
          Text(
            'العنوان: ${_getCompanyData()['location']}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: const Text(
            'فاتورة ضريبية مبسطة',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // --------- IMAGE FUNCTIONS ----------

  String get _baseUrl => SharedPreferencesService.getBaseUrl();

  String _getFullImageUrl(String imagePath) {
    final baseUrl = _baseUrl;
    if (imagePath.startsWith('http')) return imagePath;
    if (imagePath.startsWith('/')) return '$baseUrl${imagePath.substring(1)}';
    return '$baseUrl$imagePath';
  }

  Widget _buildCompanyLogo(String imageUrl, String companyName) {
    return SizedBox(
      width: 100,
      height: 50,
      child: FutureBuilder<String?>(
        future: _getCachedLogoPath(imageUrl, companyName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLogoPlaceholder(companyName);
          }
          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(File(snapshot.data!), fit: BoxFit.contain);
          }
          return CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) => _buildLogoPlaceholder(companyName),
            errorWidget: (_, __, ___) => _buildLogoPlaceholder(companyName),
          );
        },
      ),
    );
  }

  Future<String?> _getCachedLogoPath(String url, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_logo_path');
      final oldUrl = prefs.getString('cached_logo_url');

      if (cached != null && oldUrl == url) {
        final file = File(cached);
        if (await file.exists()) return cached;
      }

      return await _downloadAndCacheLogo(url, name);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _downloadAndCacheLogo(String url, String name) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/logo_${name.hashCode}.png';
        final file = File(path);
        await file.writeAsBytes(res.bodyBytes);

        final prefs = await SharedPreferences.getInstance();
        prefs.setString('cached_logo_path', path);
        prefs.setString('cached_logo_url', url);

        return path;
      }
    } catch (_) {}

    return null;
  }

  Widget _buildLogoPlaceholder(String name) {
    return Center(
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------- INVOICE INFO ----------------

  Widget _buildInvoiceInfo() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'معلومات الفاتورة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.black),
            _buildInfoRow('رقم الفاتورة', '${receiptModel.receiptCode ?? "N/A"}'),
            _buildInfoRow('التاريخ', _formatDate(receiptModel.receiveDate ?? receiptModel.openDay)),
            _buildInfoRow('الكاشير', receiptModel.cashierName ?? 'N/A'),
            _buildInfoRow('المتخصص', receiptModel.specialistName ?? 'N/A'),
            _buildInfoRow('العميل', _getClientName()),
            if (receiptModel.clientPhone != null)
              _buildInfoRow('هاتف العميل', receiptModel.clientPhone!),
            _buildInfoRow('الفرع', receiptModel.vendorBranchName ?? ''),
            _buildInfoRow('طريقة الدفع', receiptModel.paymethodName ?? 'نقدي'),
            if (receiptModel.orderTypeName != null)
              _buildInfoRow('نوع الطلب', receiptModel.orderTypeName!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        textDirection: ui.TextDirection.rtl,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

// ---------------- PRODUCTS TABLE ----------------

  Widget _buildProductsTable() {
    final allProducts = receiptModel.orderDetails.values.expand((e) => e).toList();

    if (allProducts.isEmpty) {
      return const Center(child: Text('لا توجد عناصر', style: TextStyle(fontSize: 12)));
    }

    return Column(
      children: [
        const SizedBox(height: 4),
        const Text(
          'الخدمات',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            color: Colors.grey.shade300,
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: const [
              Expanded(child: Center(child: Text('المنتج / الخدمة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('الكمية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('السعر', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('الإجمالي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
        const SizedBox(height: 2),
        ...List.generate(allProducts.length, (index) {
          final p = allProducts[index];
          final isEven = index % 2 == 0;
          return _buildProductRow(p, isEven: isEven);
        }),
      ],
    );
  }

  Widget _buildProductRow(ProductItem p, {bool isEven = false}) {
    return Container(
      color: isEven ? Colors.grey.shade100 : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              p.name,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(child: Text('${p.quantity}', style: const TextStyle(fontSize: 11))),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text(_formatCurrency(p.price), style: const TextStyle(fontSize: 11))),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text(_formatCurrency(p.total), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }


  // ---------------- TOTALS ----------------

  Widget _buildTotalsSection() {
    return Column(
      children: [
        _buildTotalRow('المجموع', _formatCurrency(receiptModel.subtotal)),
        if (receiptModel.discountPercent > 0)
          _buildTotalRow('نسبة الخصم', '${receiptModel.discountPercent}%'),
        if (receiptModel.discountTotal > 0)
          _buildTotalRow('قيمة الخصم', _formatCurrency(receiptModel.discountTotal)),
        if (receiptModel.deliveryFee > 0)
          _buildTotalRow('رسوم التوصيل', _formatCurrency(receiptModel.deliveryFee)),
        _buildTotalRow('الضريبة', _formatCurrency(receiptModel.tax)),
        _buildTotalRow('المبلغ المستحق', _formatCurrency(receiptModel.totalAfterDiscount), isTotal: true),
        _buildTotalRow('طريقة الدفع', receiptModel.paymethodName ?? 'نقدي'),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: isTotal ? 12 : 10, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: isTotal ? 12 : 10)),
          ],
        ),
      ),
    );
  }

  // ---------------- QR ----------------

  Widget _buildQrCodeSection() {
    if (receiptModel.qrCodeData == null || receiptModel.qrCodeData!.isEmpty) {
      return const SizedBox();
    }

    return Center(
      child: QrImageView(
        data: receiptModel.qrCodeData!,
        size: 100,
        foregroundColor: Colors.black,
      ),
    );
  }

  // ---------------- FOOTER ----------------

  Widget _buildFooter() {
    final c = _getCompanyData();
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Column(
        children: [
          if (c['phoneNumber'] != null)
            Text('هاتف: ${c['phoneNumber']}', style: const TextStyle(fontSize: 10)),
          if (c['taxnumber'] != null)
            Text('الرقم الضريبي: ${c['taxnumber']}', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // ---------------- HELPERS ----------------

  Map<String, dynamic> _getCompanyData() {
    if (receiptModel.data.containsKey('Company') &&
        receiptModel.data['Company'] is Map) {
      return Map<String, dynamic>.from(receiptModel.data['Company']);
    }
    return {};
  }

  String _getClientName() {
    return (receiptModel.clientName?.isEmpty ?? true)
        ? 'عميل'
        : receiptModel.clientName!;
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final d = DateTime.parse(date).toLocal();
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} ر.س';
  }
}

