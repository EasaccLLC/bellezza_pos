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

  @override
  void initState() {
    super.initState();
    _checkExistingConfiguration();
  }

  void _checkExistingConfiguration() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final currentUrl = SharedPreferencesService.getBaseUrl();
    final bool isConfigured = SharedPreferencesService.isConfigured;

    if (mounted) {
      setState(() {
        _checkingConfig = false;
        _showGuestOption = !isConfigured || currentUrl == AppConfig.defaultBaseUrl;
      });
    }

    if (isConfigured && currentUrl != AppConfig.defaultBaseUrl) {
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
            const SnackBar(
              content: Text('✅ تم حفظ الإعدادات بنجاح'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 1200));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainWebViewPage()),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('حدث خطأ أثناء الحفظ: $e');
      }
    }
  }

  void _enterAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainWebViewPage()),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingConfig) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings, color: Colors.orange, size: 45),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  "تهيئة النظام",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "أدخل عنوان الخادم لبدء استخدام النظام",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 30),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: DropdownButtonFormField<String>(
                              value: _selectedProtocol,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              ),
                              items: _protocols.map((e) {
                                return DropdownMenuItem(value: e, child: Text(e));
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedProtocol = v!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _urlController,
                              decoration: const InputDecoration(
                                hintText: "اسم النطاق أو IP",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "يرجى إدخال العنوان";
                                }
                                if (v.contains(" ")) {
                                  return "العنوان لا يحتوي على مسافات";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: _isLoading
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            _isLoading ? "جاري الحفظ..." : "حفظ والدخول",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isLoading ? null : _saveBaseUrl,
                        ),
                      ),

                      if (_showGuestOption) ...[
                        const SizedBox(height: 20),
                        const Text("أو", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.person_outline, color: Colors.orange),
                          label: const Text(
                            "الدخول كزائر",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: _enterAsGuest,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
