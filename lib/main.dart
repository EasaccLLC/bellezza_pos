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
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'NotoNaskhArabic',
      ),

      localizationsDelegates: localizationsDelegates,

      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', ''), // Arabic (no specific country)
      ],
      locale: const Locale('ar', ''),



      home: _getInitialPage(),
    );
  }

  Widget _getInitialPage() {
    final currentUrl = SharedPreferencesService.getBaseUrl();
    final isConfigured = SharedPreferencesService.isConfigured;

    if (isConfigured && currentUrl != AppConfig.defaultBaseUrl) {
      return const MainWebViewPage();
    } else {
      return const InitialSetupPage();
    }
  }
}



Future<void> loadCustomFont(String fontFamily, String fontPath) async {
  try {
    // Load the raw font data
    final fontData = await rootBundle.load(fontPath);

    // Create a FontLoader instance
    final fontLoader = FontLoader(fontFamily);

    // Add the font data to the loader
    fontLoader.addFont(
      Future.value(fontData.buffer.asByteData()),
    );

    // Crucial: Wait for the font to be loaded into the engine
    await fontLoader.load();
    print('Custom font $fontFamily loaded successfully for screenshot!');
  } catch (e) {
    print('Error loading custom font: $e');
  }
}
const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];