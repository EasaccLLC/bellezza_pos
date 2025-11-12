import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../main.dart';

class LocalizationsPortal extends StatelessWidget {
  const LocalizationsPortal({
    super.key,
    required this.child,
    // Renamed for clarity: this is the context of the *parent* app
    required this.originalContext,
  });

  // Renamed context to originalContext to avoid shadow naming in build()
  final BuildContext originalContext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(originalContext);

    return Localizations(
      locale: locale,
      delegates: localizationsDelegates,
      child: Directionality(
        textDirection: TextDirection.rtl,
        // 2. THEME & MATERIAL: Essential for font rendering, styling, and text consistency
        child: Theme(
          data: ThemeData(
            // **IMPORTANT**: If you have a custom Arabic font (e.g., Cairo)
            // included in your project assets, specify its name here.

            // Chanage Font App Recipt Printer
            fontFamily: 'NotoNaskhArabic',
          ),
          child: Material(
            child: child,
          ),
        ),
      ),
    );
  }
}