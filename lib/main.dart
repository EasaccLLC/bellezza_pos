import 'package:bellezza_pos/services/shared_preferences_service.dart';
import 'package:bellezza_pos/pages/main_webview_page.dart';
import 'package:flutter/material.dart';
import 'package:bellezza_pos/config/app_config.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bellezza_pos/pages/initial_setup_page.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferencesService.init();
  await loadCustomFont('NotoNaskhArabic', 'assets/fonts/NotoNaskhArabic.ttf');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
        fontFamily: 'NotoNaskhArabic',
      ),
      localizationsDelegates: localizationsDelegates,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', ''),
      ],
      locale: const Locale('ar', ''),
      home: _getInitialPage(),
    );
  }

  Widget _getInitialPage() {
    final currentUrl = SharedPreferencesService.getBaseUrl();
    final isConfigured = SharedPreferencesService.isConfigured;
    final guestSkipped = SharedPreferencesService.getGuestSkipped();

    if ((isConfigured && currentUrl != AppConfig.defaultBaseUrl) || guestSkipped) {
      return const MainWebViewPage();
    } else {
      return const InitialSetupPage();
    }
  }
}

Future<void> loadCustomFont(String fontFamily, String fontPath) async {
  try {
    final fontData = await rootBundle.load(fontPath);
    final fontLoader = FontLoader(fontFamily);
    fontLoader.addFont(Future.value(fontData.buffer.asByteData()));
    await fontLoader.load();
    print('Custom font $fontFamily loaded successfully!');
  } catch (e) {
    print('Error loading custom font: $e');
  }
}

const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
