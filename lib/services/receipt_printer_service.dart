import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import '../model/receipt_model.dart';
import '../widgets/receipt_widget.dart';
import '../widgets/service_receipt_widget.dart';

class ReceiptPrinter {
  static final _printer = FlutterThermalPrinter.instance;

  /// 🖨️ طباعة الفاتورة الرئيسية والخدمات
  static Future<void> printReceipt(
      Map<String, dynamic> data,
      BuildContext context,
      ) async {
    try {
      print("🟢 بدء عملية الطباعة الكاملة");
      final receiptModel = ReceiptModel(data: data);

      // 1. أولاً: طباعة فاتورة الكاشير الرئيسية
      await _printCashierReceipt(receiptModel, context);

      // 2. ثانياً: طباعة فواتير الخدمات لكل printerIp
      await _printServiceReceipts(receiptModel, context);

      print("✅ اكتملت عملية الطباعة بنجاح");

    } catch (e) {
      print("❌ خطأ عام في الطباعة: $e");
      rethrow;
    }
  }

  /// 💰 طباعة فاتورة الكاشير الرئيسية
  static Future<void> _printCashierReceipt(ReceiptModel receiptModel, BuildContext context) async {
    try {
      final mainPrinterIp = receiptModel.printerIp;

      if (mainPrinterIp == null || mainPrinterIp.isEmpty) {
        print("⚠️ لا يوجد طابعة رئيسية للفاتورة");
        return;
      }

      print("💰 بدء طباعة فاتورة الكاشير على: $mainPrinterIp");


      // استخدام الطباعة المباشرة بدون connect
      await _printDirectViaNetwork(mainPrinterIp, receiptModel.data, context);

      print("✅ تمت طباعة فاتورة الكاشير بنجاح على: $mainPrinterIp");

    } catch (e) {
      print("❌ خطأ في طباعة فاتورة الكاشير: $e");
      print("🔍 تفاصيل الخطأ: ${e.toString()}");
    }
  }

  /// 🔧 طباعة فواتير الخدمات
  static Future<void> _printServiceReceipts(ReceiptModel receiptModel, BuildContext context) async {
    try {
      final orderDetails = receiptModel.orderDetails;

      if (orderDetails.isEmpty) {
        print("ℹ️ لا توجد خدمات للطباعة");
        return;
      }

      print("🛠️ بدء طباعة ${orderDetails.length} فاتورة خدمة");

      // طباعة فاتورة خدمة لكل printerIp
      for (final entry in orderDetails.entries) {
        final printerIp = entry.key;
        final services = entry.value;

        print("🖨️ معالجة طابعة الخدمة: $printerIp بها ${services.length} خدمة");

        for (final service in services) {
          await _printSingleServiceReceipt(receiptModel, printerIp, service, context);
        }
      }

      print("✅ اكتملت طباعة فواتير الخدمات");

    } catch (e) {
      print("❌ خطأ في طباعة فواتير الخدمات: $e");
    }
  }

  /// 🛠️ طباعة فاتورة خدمة واحدة
  static Future<void> _printSingleServiceReceipt(
      ReceiptModel receiptModel,
      String printerIp,
      ProductItem service,
      BuildContext context,
      ) async {
    try {
      print("🛠️ بدء طباعة فاتورة الخدمة على: $printerIp - ${service.name}");

      // إنشاء فاتورة الخدمة
      final serviceWidget = ServiceReceiptWidget(
        receiptModel: receiptModel,
        printerIp: printerIp,
        serviceItem: service,
      );

      // استخدام الطباعة المباشرة للخدمة
      await _printServiceDirectViaNetwork(printerIp, serviceWidget, context);

      print("✅ تمت طباعة فاتورة الخدمة: ${service.name} على $printerIp");

    } catch (e) {
      print("❌ خطأ في طباعة فاتورة الخدمة $printerIp: $e");
      print("🔍 تفاصيل الخطأ: ${e.toString()}");
    }
  }

  /// 🌐 الطباعة المباشرة عبر الشبكة للفاتورة الرئيسية
  static Future<void> _printDirectViaNetwork(
      String printerIp,
      Map<String, dynamic> data,
      BuildContext context,
      ) async {
    try {
      final port = 9100; // المنفذ الافتراضي للطابعات الحرارية

      print("🌐 محاولة الطباعة المباشرة على: $printerIp:$port");

      // إنشاء bytes الفاتورة
      final bytes = await _generateReceiptBytes(data, context);
      print("📦 حجم البيانات المُنشأة: ${bytes.length} bytes");

      // استخدام FlutterThermalPrinterNetwork للطباعة المباشرة
      final networkPrinter = FlutterThermalPrinterNetwork(printerIp, port: port);

      print("🔌 محاولة الاتصال بالطابعة...");
      await networkPrinter.connect();
      print("✅ تم الاتصال بالطابعة");

      print("🖨️ بدء إرسال البيانات للطباعة...");
      await networkPrinter.printTicket(bytes);
      print("✅ تم إرسال البيانات بنجاح");

      print("🔌 قطع الاتصال...");
      await networkPrinter.disconnect();
      print("✅ تم قطع الاتصال");

    } catch (e) {
      print("❌ خطأ في الطباعة المباشرة على $printerIp: $e");

      // محاولة بديلة باستخدام الطباعة عبر الصورة
      print("🔄 جارٍ تجربة الطريقة البديلة...");
      await _printViaImageAlternative(printerIp, data, context);
    }
  }

  /// 🌐 الطباعة المباشرة عبر الشبكة للخدمات
  static Future<void> _printServiceDirectViaNetwork(
      String printerIp,
      ServiceReceiptWidget serviceWidget,
      BuildContext context,
      ) async {
    try {
      final port = 9100;

      print("🌐 محاولة الطباعة المباشرة للخدمة على: $printerIp:$port");

      // إنشاء bytes فاتورة الخدمة
      final bytes = await _generateServiceReceiptBytes(serviceWidget, context);
      print("📦 حجم بيانات الخدمة: ${bytes.length} bytes");

      // استخدام FlutterThermalPrinterNetwork للطباعة المباشرة
      final networkPrinter = FlutterThermalPrinterNetwork(printerIp, port: port);

      print("🔌 محاولة الاتصال بطابعة الخدمة...");
      await networkPrinter.connect();
      print("✅ تم الاتصال بطابعة الخدمة");

      print("🖨️ بدء إرسال بيانات الخدمة...");
      await networkPrinter.printTicket(bytes);
      print("✅ تم إرسال بيانات الخدمة بنجاح");

      print("🔌 قطع الاتصال...");
      await networkPrinter.disconnect();
      print("✅ تم قطع الاتصال");

    } catch (e) {
      print("❌ خطأ في الطباعة المباشرة للخدمة على $printerIp: $e");

      // محاولة بديلة للخدمة
      print("🔄 جارٍ تجربة الطريقة البديلة للخدمة...");
      await _printServiceViaImageAlternative(printerIp, serviceWidget, context);
    }
  }

  /// 🖼️ طريقة بديلة للطباعة عبر الصورة (للنسخة الرئيسية)
  static Future<void> _printViaImageAlternative(
      String printerIp,
      Map<String, dynamic> data,
      BuildContext context,
      ) async {
    try {
      print("🖼️ استخدام الطريقة البديلة للطباعة...");

      final receiptModel = ReceiptModel(data: data);
      final widget = ReceiptWidget(receiptModel: receiptModel);

      // استخدام printWidget مع خيارات مختلفة
      final printer = Printer(
        name: 'Alternative Printer - $printerIp',
        address: '$printerIp:9100',
        connectionType: ConnectionType.NETWORK,
      );

      print("🔌 محاولة الاتصال بالطريقة البديلة...");
      final connected = await _printer.connect(printer);

      if (connected) {
        print("✅ تم الاتصال بالطريقة البديلة");

        await _printer.printWidget(
          context,
          printer: printer,
          cutAfterPrinted: true,
          widget: widget,
        );

        await _printer.disconnect(printer);
        print("✅ تمت الطباعة بالطريقة البديلة");
      } else {
        print("❌ فشل الاتصال بالطريقة البديلة");
        throw Exception("فشل الاتصال بالطابعة $printerIp");
      }

    } catch (e) {
      print("❌ خطأ في الطريقة البديلة: $e");
      rethrow;
    }
  }

  /// 🖼️ طريقة بديلة للطباعة عبر الصورة (للخدمات)
  static Future<void> _printServiceViaImageAlternative(
      String printerIp,
      ServiceReceiptWidget serviceWidget,
      BuildContext context,
      ) async {
    try {
      print("🖼️ استخدام الطريقة البديلة لطباعة الخدمة...");

      final printer = Printer(
        name: 'Alternative Service Printer - $printerIp',
        address: '$printerIp:9100',
        connectionType: ConnectionType.NETWORK,
      );

      print("🔌 محاولة الاتصال بالطريقة البديلة للخدمة...");
      final connected = await _printer.connect(printer);

      if (connected) {
        print("✅ تم الاتصال بالطريقة البديلة للخدمة");

        await _printer.printWidget(
          context,
          printer: printer,
          cutAfterPrinted: true,
          widget: serviceWidget,
        );

        await _printer.disconnect(printer);
        print("✅ تمت طباعة الخدمة بالطريقة البديلة");
      } else {
        print("❌ فشل الاتصال بالطريقة البديلة للخدمة");
        throw Exception("فشل الاتصال بطابعة الخدمة $printerIp");
      }

    } catch (e) {
      print("❌ خطأ في الطريقة البديلة للخدمة: $e");
      rethrow;
    }
  }

  static Future<List<int>> _generateReceiptBytes(
      Map<String, dynamic> data,
      BuildContext context,
      ) async {
    try {
      print("📸 جاري إنشاء صورة الفاتورة...");
      final receiptModel = ReceiptModel(data: data);
      final widget = ReceiptWidget(receiptModel: receiptModel);

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      Uint8List screenshotBytes = await FlutterThermalPrinter.instance.screenShotWidget(
        context,
        generator: generator,
        widget: widget,
      );

      if (context.mounted) {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Image.memory(screenshotBytes),
                  ),
                ),
              );
            });
      }

      print("📸 تم إنشاء الصورة بحجم: ${screenshotBytes.length} bytes");

      List<int> finalBytes = [];
      finalBytes.addAll(screenshotBytes);
      finalBytes.addAll([0x0A, 0x0A, 0x0A]); // إضافة أسطر فارغة
      finalBytes.addAll([0x1B, 0x69]); // أمر قطع الورق

      print("📦 الحجم النهائي للبيانات: ${finalBytes.length} bytes");

      return finalBytes;
    } catch (e) {
      print("❌ خطأ في _generateReceiptBytes: $e");
      rethrow;
    }
  }

  static Future<List<int>> _generateServiceReceiptBytes(
      ServiceReceiptWidget serviceWidget,
      BuildContext context,
      ) async {
    try {
      print("📸 جاري إنشاء صورة فاتورة الخدمة...");

      List<int> screenshotBytes = await FlutterThermalPrinter.instance.screenShotWidget(
        context,
        widget: serviceWidget,
      );

      print("📸 تم إنشاء صورة الخدمة بحجم: ${screenshotBytes.length} bytes");

      List<int> finalBytes = [];
      finalBytes.addAll(screenshotBytes);
      finalBytes.addAll([0x0A, 0x0A, 0x0A]);
      finalBytes.addAll([0x1B, 0x69]);

      print("📦 الحجم النهائي لبيانات الخدمة: ${finalBytes.length} bytes");

      return finalBytes;
    } catch (e) {
      print("❌ خطأ في _generateServiceReceiptBytes: $e");
      rethrow;
    }
  }
}