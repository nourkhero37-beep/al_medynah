import 'package:al_medynah/main.dart';
import 'package:al_medynah/screens/splash.dart';
import 'package:al_medynah/services/locale_service.dart';
import 'package:flutter/material.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  static const Color goldColor = Color(0xFFB8964E);
  static const Color darkBrown = Color(0xFF3E2A0F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5ECD7),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    size: 40,
                    color: goldColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Choose your language',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkBrown,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'اختر لغتك  •  Dilinizi seçin',
                  style: TextStyle(
                    fontSize: 13,
                    color: darkBrown.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 40),
                _LanguageOption(
                  label: 'العربية',
                  flag: '🇸🇦',
                  onTap: () => _select(context, const Locale('ar')),
                ),
                const SizedBox(height: 12),
                _LanguageOption(
                  label: 'English',
                  flag: '🇬🇧',
                  onTap: () => _select(context, const Locale('en')),
                ),
                const SizedBox(height: 12),
                _LanguageOption(
                  label: 'Türkçe',
                  flag: '🇹🇷',
                  onTap: () => _select(context, const Locale('tr')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _select(BuildContext context, Locale locale) async {
    await LocaleService.setLocale(locale);
    appLocaleNotifier.value = locale;
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String flag;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.flag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 1,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Text(
                  flag,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3E2A0F),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFFB8964E),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}