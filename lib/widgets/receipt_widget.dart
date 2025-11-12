import 'package:flutter/material.dart';
import '../model/receipt_model.dart';

class ReceiptWidget extends StatelessWidget {
  final ReceiptModel receiptModel;

  const ReceiptWidget({super.key, required this.receiptModel});

  @override
  Widget build(BuildContext context) {
    final items = receiptModel.orderDetails.values.expand((i) => i).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: Colors.white,
        width: 100, // that is width
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(),
            const SizedBox(height: 3),
            const Divider(thickness: 0.5),
            _buildInfoSection(),
            const Divider(thickness: 0.5),
            _buildTableHeader(),
            const Divider(thickness: 0.5),
            ...items.map((e) => _buildItemRow(e)).toList(),
            const Divider(thickness: 0.5),
            _buildTotalsSection(),
            const SizedBox(height: 4),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          receiptModel.vendorName ?? 'اسم المنشأة',
          style: const TextStyle(fontSize: 10,),
          textAlign: TextAlign.center,
        ),
        if (receiptModel.vendorBranchName != null)
          Text(receiptModel.vendorBranchName!, style: const TextStyle(fontSize: 6)),
        if (receiptModel.location != null)
          Text(receiptModel.location!, style: const TextStyle(fontSize: 6)),
        if (receiptModel.clientPhone != null)
          Text('📞 ${receiptModel.clientPhone!}', style: const TextStyle(fontSize: 6)),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('رقم الفاتورة', receiptModel.receiptCode ?? '-'),
        _infoRow('التاريخ', receiptModel.receiveDate ?? '-'),
        _infoRow('الكاشير', receiptModel.cashierName ?? '-'),
        if (receiptModel.clientName != null)
          _infoRow('العميل', receiptModel.clientName!),
        if (receiptModel.orderTypeName != null)
          _infoRow('نوع الطلب', receiptModel.orderTypeName!),
        if (receiptModel.paymethodName != null)
          _infoRow('طريقة الدفع', receiptModel.paymethodName!),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 6)),
        Text(value, style: const TextStyle(fontSize: 6)),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: const [
        Expanded(flex: 4, child: Text('المنتج', textAlign: TextAlign.center, style: TextStyle(fontSize: 6))),
        Expanded(flex: 1, child: Text('الكمية', textAlign: TextAlign.center, style: TextStyle(fontSize: 6))),
        Expanded(flex: 2, child: Text('السعر', textAlign: TextAlign.center, style: TextStyle(fontSize: 6))),
        Expanded(flex: 2, child: Text('الإجمالي', textAlign: TextAlign.center, style: TextStyle(fontSize: 6))),
      ],
    );
  }

  Widget _buildItemRow(ProductItem item) {
    return Row(
      children: [
        Expanded(flex: 4, child: Text(item.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 6))),
        Expanded(flex: 1, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 6))),
        Expanded(flex: 2, child: Text(item.price.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(fontSize: 6))),
        Expanded(flex: 2, child: Text(item.total.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(fontSize: 6))),
      ],
    );
  }

  Widget _buildTotalsSection() {
    return Column(
      children: [
        _totalRow('الإجمالي الفرعي', receiptModel.subtotal),
        if (receiptModel.discountTotal > 0)
          _totalRow('الخصم', -receiptModel.discountTotal),
        if (receiptModel.tax > 0)
          _totalRow('الضريبة', receiptModel.tax),
        if (receiptModel.deliveryFee > 0)
          _totalRow('رسوم التوصيل', receiptModel.deliveryFee),
        const Divider(thickness: 0.5),
        _totalRow('الإجمالي النهائي', receiptModel.totalAfterDiscount,
            isBold: true, fontSize: 8),
      ],
    );
  }

  Widget _totalRow(String title, double value,
      {bool isBold = false, double fontSize = 6}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
              fontSize: fontSize,
            )),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(thickness: 0.5),
        if (receiptModel.qrCodeData != null)
          Image.network(receiptModel.qrCodeData!,
              width: 20, height: 20, errorBuilder: (_, __, ___) => const SizedBox()),
        const SizedBox(height: 2),
        const Text('شكراً لزيارتكم ❤️',
            style: TextStyle(fontSize: 6)),
        Text('Powered by بليزا',
            style: TextStyle(fontSize: 5, color: Colors.grey)),
      ],
    );
  }
}
