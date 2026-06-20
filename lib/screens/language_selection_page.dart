import 'package:al_medynah/main.dart';
import 'package:al_medynah/screens/splash.dart';
import 'package:al_medynah/services/locale_service.dart';
import 'package:flutter/material.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  static const Color darkBrown = Color(0xFF3E2A0F);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appDarkModeNotifier,
      builder: (context, isDark, _) {
        final textScale = MediaQuery.of(context).size.width / 430;
        final scale = textScale.clamp(0.75, 1.3);

        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/background2.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: isDark
                    ? Colors.black.withValues(alpha: 0.75)
                    : Colors.black.withValues(alpha: 0.12),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF8B6914).withValues(alpha: 0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                appDarkModeNotifier.value = !appDarkModeNotifier.value;
                              },
                              icon: Icon(
                                isDark ? Icons.light_mode : Icons.dark_mode,
                                color: isDark
                                    ? const Color(0xFFD4B88A)
                                    : const Color(0xFF795548),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
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
                                    color: const Color(0xFFD4B88A).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.translate_rounded,
                                    size: 40,
                                    color: Color(0xFFD4B88A),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Choose your language',
                                  style: TextStyle(
                                    fontFamily: 'GE SS Two',
                                    fontSize: 22 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFFD4B88A)
                                        : const Color(0xFF795548),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'اختر لغتك  •  Dilinizi seçin',
                                  style: TextStyle(
                                    fontFamily: 'GE SS Two',
                                    fontSize: 13 * scale,
                                    color: isDark
                                        ? Colors.white70
                                        : darkBrown.withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                _LanguageOption(
                                  label: 'العربية',
                                  flag: '🇸🇦',
                                  isDark: isDark,
                                  scale: scale,
                                  onTap: () => _select(context, const Locale('ar')),
                                ),
                                const SizedBox(height: 12),
                                _LanguageOption(
                                  label: 'English',
                                  flag: '🇬🇧',
                                  isDark: isDark,
                                  scale: scale,
                                  onTap: () => _select(context, const Locale('en')),
                                ),
                                const SizedBox(height: 12),
                                _LanguageOption(
                                  label: 'Türkçe',
                                  flag: '🇹🇷',
                                  isDark: isDark,
                                  scale: scale,
                                  onTap: () => _select(context, const Locale('tr')),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
  final bool isDark;
  final double scale;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.flag,
    required this.isDark,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF8B6914).withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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
                style: TextStyle(
                  fontFamily: 'GE SS Two',
                  fontSize: 17 * scale,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFD4B88A)
                      : const Color(0xFFFF9800),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark
                    ? const Color(0xFFD4B88A)
                    : const Color(0xFF3E2A0F),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
