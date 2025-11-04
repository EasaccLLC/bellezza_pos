import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../model/receipt_model.dart';
import '../services/shared_preferences_service.dart';

class ServiceReceiptWidget extends StatelessWidget {
  final ReceiptModel receiptModel;
  final String printerIp;
  final ProductItem serviceItem;

  const ServiceReceiptWidget({
    super.key,
    required this.receiptModel,
    required this.printerIp,
    required this.serviceItem,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: 250, // تصغير العرض
        child: Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildServiceHeader(),
                const SizedBox(height: 6),
                const Divider(thickness: 1, color: Colors.black),
                _buildServiceInfo(),
                const SizedBox(height: 6),
                const Divider(thickness: 1, color: Colors.black),
                _buildServiceDetails(),
                const SizedBox(height: 6),
                const Divider(thickness: 1, color: Colors.black),
                _buildSpecialistSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceHeader() {
    final companyData = _getCompanyData();
    final companyName = companyData['ar'] ?? receiptModel.vendorBranchName ?? 'المتجر';
    final companyLocation = companyData['location'];
    final imageUrl = companyData['imageUrl'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // اللوجو
        if (imageUrl != null && imageUrl.toString().isNotEmpty)
          Container(
            height: 40, // تصغير الارتفاع
            child: Center(
              child: _buildCompanyLogo(_getFullImageUrl(imageUrl), companyName),
            ),
          ),

        const SizedBox(height: 4),

        // اسم الشركة
        Text(
          companyName,
          style: const TextStyle(
            fontSize: 14, // تصغير حجم الخط
            fontWeight: FontWeight.bold,
            height: 1.1,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 2),

        // عنوان الشركة
        if (companyLocation != null)
          Text(
            companyLocation,
            style: const TextStyle(
              fontSize: 10, // تصغير حجم الخط
              height: 1.1,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

        const SizedBox(height: 4),

        // نوع الفاتورة
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 1),
            borderRadius: BorderRadius.circular(4),
            color: Colors.blue[50],
          ),
          child: const Text(
            'فاتورة خدمة',
            style: TextStyle(
              fontSize: 12, // تصغير حجم الخط
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceInfo() {
    final clientName = _getClientName();
    final receiptCode = receiptModel.receiptCode ?? "N/A";
    final date = _formatDate(receiptModel.receiveDate);
    final cashierName = receiptModel.cashierName ?? 'N/A';
    final branchName = receiptModel.vendorBranchName ?? '';
    final clientPhone = receiptModel.clientPhone;

    return Container(
      padding: const EdgeInsets.all(6), // تصغير البادنج
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[50],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'معلومات الخدمة',
            style: TextStyle(
              fontSize: 12, // تصغير حجم الخط
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // الصف الأول: رقم الفاتورة والتاريخ
          _buildCompactInfoRow('رقم الفاتورة', receiptCode),
          _buildCompactInfoRow('التاريخ', date),

          // الصف الثاني: الكاشير والعميل
          _buildCompactInfoRow('الكاشير', cashierName),
          _buildCompactInfoRow('العميل', clientName),

          // الصف الثالث: الفرع
          _buildCompactInfoRow('الفرع', branchName),

          // هاتف العميل إذا موجود
          if (clientPhone != null && clientPhone.isNotEmpty)
            _buildCompactInfoRow('هاتف العميل', clientPhone),
        ],
      ),
    );
  }

  Widget _buildServiceDetails() {
    return Container(
      padding: const EdgeInsets.all(6), // تصغير البادنج
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'تفاصيل الخدمة',
            style: TextStyle(
              fontSize: 12, // تصغير حجم الخط
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // اسم الخدمة
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              serviceItem.name,
              style: const TextStyle(
                fontSize: 12, // تصغير حجم الخط
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 6),

          // تفاصيل الخدمة المختصرة
          _buildCompactDetailRow('الصالة', serviceItem.hallName ?? 'غير محدد'),
          _buildCompactDetailRow('الكمية', '${serviceItem.quantity}'),

          if (serviceItem.reservationDate != null)
            _buildCompactDetailRow('موعد الحجز', _formatDate(serviceItem.reservationDate)),
        ],
      ),
    );
  }

  Widget _buildSpecialistSection() {
    final specialistName = serviceItem.specialistName ?? 'غير محدد';
    final printerName = serviceItem.printerName ?? printerIp;

    return Container(
      padding: const EdgeInsets.all(6), // تصغير البادنج
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(4),
        color: Colors.green[50],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'المتخصص المسؤول',
            style: TextStyle(
              fontSize: 12, // تصغير حجم الخط
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Text(
                  specialistName,
                  style: const TextStyle(
                    fontSize: 12, // تصغير حجم الخط
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  'طابعة: $printerName',
                  style: const TextStyle(
                    fontSize: 10, // تصغير حجم الخط
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== الدوال المساعدة ==========

  Widget _buildCompactDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 10, // تصغير حجم الخط
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10, // تصغير حجم الخط
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 10, // تصغير حجم الخط
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10, // تصغير حجم الخط
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  String get _baseUrl {
    final url = SharedPreferencesService.getBaseUrl();
    return url;
  }

  String _getFullImageUrl(String imagePath) {
    final baseUrl = _baseUrl;

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    if (imagePath.startsWith('/')) {
      return '$baseUrl${imagePath.substring(1)}';
    }

    return '$baseUrl$imagePath';
  }

  Widget _buildCompanyLogo(String imageUrl, String companyName) {
    return SizedBox(
      width: 60, // تصغير العرض
      height: 30, // تصغير الارتفاع
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
        if (await file.exists()) {
          return cachedPath;
        }
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
        final filePath = '${directory.path}/service_logo_${companyName.hashCode}.png';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_logo_path', filePath);
        await prefs.setString('cached_logo_url', imageUrl);
        return filePath;
      }
    } catch (e) {
      print("خطأ في تحميل صورة الخدمة: $e");
    }
    return null;
  }

  Widget _buildLogoImage(File imageFile, String companyName) {
    return Container(
      width: 50, // تصغير العرض
      height: 25, // تصغير الارتفاع
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.file(
          imageFile,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildLogoPlaceholder(companyName);
          },
        ),
      ),
    );
  }

  Widget _buildNetworkLogoWithCache(String imageUrl, String companyName) {
    _downloadAndCacheLogo(imageUrl, companyName);
    return Container(
      width: 50, // تصغير العرض
      height: 25, // تصغير الارتفاع
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => _buildLogoPlaceholder(companyName),
          errorWidget: (context, url, error) => _buildLogoPlaceholder(companyName),
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(String companyName) {
    return Container(
      width: 50, // تصغير العرض
      height: 25, // تصغير الارتفاع
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Text(
          companyName.split(' ').take(1).join(' '),
          style: const TextStyle(
            fontSize: 8, // تصغير حجم الخط
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Map<String, dynamic> _getCompanyData() {
    if (receiptModel.data.containsKey('Company') && receiptModel.data['Company'] is Map) {
      return Map<String, dynamic>.from(receiptModel.data['Company']);
    }
    return {};
  }

  String _getClientName() {
    final clientName = receiptModel.clientName;
    return (clientName?.isEmpty == true) ? 'عميل' : (clientName ?? 'عميل');
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} ر.س';
  }
}