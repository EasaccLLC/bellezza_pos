import 'package:flutter/material.dart';
import 'package:bellezza_pos/services/shared_preferences_service.dart';
import 'package:bellezza_pos/config/app_config.dart';
import 'package:bellezza_pos/pages/main_webview_page.dart';

class InitialSetupPage extends StatefulWidget {
  const InitialSetupPage({super.key});

  @override
  State<InitialSetupPage> createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  final TextEditingController _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedProtocol = 'https://';
  bool _isLoading = false;
  bool _checkingConfig = true;
  bool _showGuestOption = false;

  final List<String> _protocols = ['https://', 'http://'];

  // Brand Colors
  final Color primaryOrange = const Color(0xFFEF8330);
  final Color primaryGreen = const Color(0xFF669651);

  @override
  void initState() {
    super.initState();
    _checkExistingConfiguration();
  }

  void _checkExistingConfiguration() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final currentUrl = SharedPreferencesService.getBaseUrl();
    final bool isConfigured = SharedPreferencesService.isConfigured;
    final bool guestSkipped = SharedPreferencesService.getGuestSkipped();

    if (mounted) {
      setState(() {
        _checkingConfig = false;
        _showGuestOption =
            (!isConfigured || currentUrl == AppConfig.defaultBaseUrl) &&
                !guestSkipped;
      });
    }

    if ((isConfigured && currentUrl != AppConfig.defaultBaseUrl) ||
        guestSkipped) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainWebViewPage()),
        );
      }
    }
  }

  Future<void> _saveBaseUrl() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final fullUrl = _selectedProtocol + _urlController.text.trim();
        await SharedPreferencesService.setBaseUrl(fullUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: primaryGreen,
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text("تم حفظ الإعدادات بنجاح"),
                ],
              ),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 800));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainWebViewPage()),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('خطأ في حفظ الإعدادات: $e');
      }
    }
  }

  void _enterAsGuest() async {
    await SharedPreferencesService.setGuestSkipped(true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainWebViewPage()),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingConfig) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              "assets/images/bg.jpeg",
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          // MAIN CONTENT
          Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    /// LOGO (Text logo - no circle)
                    Text(
                      "Bellezza",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryOrange,
                        fontSize: 45,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1, 2),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "تهيئة التطبيق",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "أدخل عنوان الخادم للبدء",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // WHITE CARD (Improved UI)
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white, // PURE WHITE
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 18,
                            spreadRadius: 4,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // INPUT FIELD BOX
                            Container(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                Border.all(color: primaryGreen, width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedProtocol,
                                      items: _protocols.map((e) {
                                        return DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(
                                                () => _selectedProtocol = val!);
                                      },
                                    ),
                                  ),

                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.grey.shade300,
                                  ),

                                  Expanded(
                                    child: TextFormField(
                                      controller: _urlController,
                                      decoration: const InputDecoration(
                                        hintText: "اسم الدومين أو IP",
                                        border: InputBorder.none,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "يرجى إدخال العنوان";
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveBaseUrl,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryOrange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                    color: Colors.white)
                                    : const Text(
                                  "حفظ والدخول",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            if (_showGuestOption) ...[
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: _enterAsGuest,
                                child: Text(
                                  "الدخول كزائر",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: primaryOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
