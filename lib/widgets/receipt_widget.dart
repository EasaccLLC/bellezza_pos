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
      textDirection: ui.TextDirection.rtl,
      child: Container(
        width: 200,
        child: Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Directionality(   // ضمان RTL لكل العناصر الداخلية
              textDirection: ui.TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
        ),
      ),
    );
  }


  Widget _buildHeaderWithLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_getCompanyData()['imageUrl'] != null && _getCompanyData()['imageUrl'].toString().isNotEmpty)
          Container(
            height: 60,
            child: Center(
              child: _buildCompanyLogo(
                  _getFullImageUrl(_getCompanyData()['imageUrl']),
                  _getCompanyData()['ar'] ?? receiptModel.vendorBranchName ?? 'المتجر'
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          _getCompanyData()['ar'] ?? receiptModel.vendorBranchName ?? 'المتجر',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (_getCompanyData()['location'] != null)
          Text(
            'العنوان: ${_getCompanyData()['location']}',
            style: const TextStyle(
              fontSize: 12,
              height: 1.2,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: const Text(
            'فاتورة ضريبية مبسطة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

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
            return _buildLogoImage(File(snapshot.data!), companyName);
          }
          return _buildNetworkLogoWithCache(imageUrl, companyName);
        },
      ),
    );
  }

  Future<String?> _getCachedLogoPath(String imageUrl, String companyName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPath = prefs.getString('cached_logo_path');
      final cachedUrl = prefs.getString('cached_logo_url');
      if (cachedPath != null && cachedUrl == imageUrl) {
        final file = File(cachedPath);
        if (await file.exists()) return cachedPath;
      }
      return await _downloadAndCacheLogo(imageUrl, companyName);
    } catch (e) {
      return null;
    }
  }

  Future<String?> _downloadAndCacheLogo(String imageUrl, String companyName) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/company_logo_${companyName.hashCode}.png';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_logo_path', filePath);
        await prefs.setString('cached_logo_url', imageUrl);
        return filePath;
      }
    } catch (e) {}
    return null;
  }

  Widget _buildLogoImage(File imageFile, String companyName) {
    return Image.file(imageFile, fit: BoxFit.contain);
  }

  Widget _buildNetworkLogoWithCache(String imageUrl, String companyName) {
    _downloadAndCacheLogo(imageUrl, companyName);
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => _buildLogoPlaceholder(companyName),
      errorWidget: (context, url, error) => _buildLogoPlaceholder(companyName),
    );
  }

  Widget _buildLogoPlaceholder(String companyName) {
    return Center(
      child: Text(
        companyName.split(' ').take(2).join(' '),
        style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInvoiceInfo() {
    return Container(
      padding: const EdgeInsets.all(5), // تعديل الحواف
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        textDirection: ui.TextDirection.rtl, // اتجاه عربي للمعلومات
        children: [
          const Text(
            'معلومات الفاتورة',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Divider(color: Colors.black, height: 1),
          _buildInfoRow('رقم الفاتورة', '${receiptModel.receiptCode ?? "N/A"}'),
          _buildInfoRow('التاريخ', _formatDate(receiptModel.receiveDate ?? receiptModel.openDay)),
          _buildDualInfoRow(
            label1: 'الكاشير', value1: receiptModel.cashierName ?? 'N/A',
            label2: 'المتخصص', value2: receiptModel.specialistName ?? 'N/A',
          ),
          _buildInfoRow('العميل', _getClientName()),
          if (receiptModel.clientPhone != null && receiptModel.clientPhone!.isNotEmpty)
            _buildInfoRow('هاتف العميل', receiptModel.clientPhone!),
          _buildDualInfoRow(
            label1: 'الفرع', value1: receiptModel.vendorBranchName ?? '',
            label2: 'طريقة الدفع', value2: receiptModel.paymethodName ?? 'نقدي',
          ),
          if (receiptModel.orderTypeName != null)
            _buildInfoRow('نوع الطلب', receiptModel.orderTypeName!),
        ],
      ),
    );
  }

  Widget _buildProductsTable() {
    final allProducts = receiptModel.orderDetails.values.expand((e) => e).toList();
    if (allProducts.isEmpty) return const Center(child: Text('لا توجد عناصر', style: TextStyle(fontSize: 12)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('الخدمات', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
          child: Row(
            children: const [
              Expanded(flex: 5, child: Center(child: Text('المنتج / الخدمة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
              Expanded(flex: 2, child: Center(child: Text('الكمية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
              Expanded(flex: 3, child: Center(child: Text('السعر', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
              Expanded(flex: 3, child: Center(child: Text('الإجمالي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
        for (final product in allProducts) _buildProductRow(product),
      ],
    );
  }

  Widget _buildProductRow(ProductItem product) {
    return Row(
      children: [
        Expanded(flex: 5, child: Text(product.name, style: const TextStyle(fontSize: 10))),
        Expanded(flex: 2, child: Center(child: Text('${product.quantity}', style: const TextStyle(fontSize: 10)))),
        Expanded(flex: 3, child: Center(child: Text(_formatCurrency(product.price), style: const TextStyle(fontSize: 10)))),
        Expanded(flex: 3, child: Center(child: Text(_formatCurrency(product.total), style: const TextStyle(fontSize: 10)))),
      ],
    );
  }

  Widget _buildTotalsSection() {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Column(
        children: [
          _buildTotalRow('المجموع', _formatCurrency(receiptModel.subtotal)),
          if (receiptModel.discountPercent > 0) _buildTotalRow('نسبة الخصم', '${receiptModel.discountPercent}%'),
          if (receiptModel.discountTotal > 0) _buildTotalRow('قيمة الخصم', _formatCurrency(receiptModel.discountTotal)),
          if (receiptModel.deliveryFee > 0) _buildTotalRow('رسوم التوصيل', _formatCurrency(receiptModel.deliveryFee)),
          _buildTotalRow('الضريبة', _formatCurrency(receiptModel.tax)),
          _buildTotalRow('المبلغ المستحق', _formatCurrency(receiptModel.totalAfterDiscount), isTotal: true),
          _buildTotalRow('طريقة الدفع', receiptModel.paymethodName ?? 'نقدي'),
        ],
      ),
    );
  }

  Widget _buildQrCodeSection() {
    if (receiptModel.qrCodeData == null || receiptModel.qrCodeData!.isEmpty) return const SizedBox();
    return Center(
      child: QrImageView(
        data: receiptModel.qrCodeData!,
        version: QrVersions.auto,
        size: 100.0,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildFooter() {
    final companyData = _getCompanyData();
    return Column(
      children: [
        if (companyData['phoneNumber'] != null) Text('هاتف: ${companyData['phoneNumber']}', style: const TextStyle(fontSize: 10)),
        if (companyData['taxnumber'] != null) Text('الرقم الضريبي: ${companyData['taxnumber']}', style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 4),
        // تم حذف رقم السيريال
      ],
    );
  }

  Map<String, dynamic> _getCompanyData() {
    if (receiptModel.data.containsKey('Company') && receiptModel.data['Company'] is Map) {
      return Map<String, dynamic>.from(receiptModel.data['Company']);
    }
    return {};
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: const TextStyle(fontSize: 10)),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDualInfoRow({required String label1, required String value1, required String label2, required String value2}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text('$label1: $value1', style: const TextStyle(fontSize: 10))),
          Expanded(child: Text('$label2: $value2', style: const TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: TextStyle(fontSize: isTotal ? 12 : 10, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(label, style: TextStyle(fontSize: isTotal ? 12 : 10, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  String _getClientName() => (receiptModel.clientName?.isEmpty == true) ? 'عميل' : (receiptModel.clientName ?? 'عميل');

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(double amount) => '${amount.toStringAsFixed(2)} ر.س';
}
