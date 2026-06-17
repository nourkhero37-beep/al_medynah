import 'dart:async';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/services/audio_manager_api.dart';
import 'package:al_medynah/screens/language_selection_page.dart';
import 'package:al_medynah/screens/splash.dart';
import 'package:al_medynah/services/locale_service.dart';
import 'package:al_medynah/features/quran/tafseer/tafseer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

final ValueNotifier<Locale> appLocaleNotifier =
    ValueNotifier(const Locale('ar'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await AudioManager().loadSelectedReciter();
  unawaited(TafseerService().precacheAllTafseer());
  runApp(const Almedinah());
}

class Almedinah extends StatefulWidget {
  const Almedinah({super.key});

  @override
  State<Almedinah> createState() => _AlmedinahState();
}

class _AlmedinahState extends State<Almedinah> {
  bool _showLanguageSelection = false;

  @override
  void initState() {
    super.initState();
    _initLocale();
    appLocaleNotifier.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initLocale() async {
    final hasLocale = await LocaleService.hasLocale();
    if (!hasLocale) {
      setState(() => _showLanguageSelection = true);
    }
    final locale = await LocaleService.getLocale();
    appLocaleNotifier.value = locale;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
            Locale('tr'),
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supported) {
            if (locale != null) {
              for (final s in supported) {
                if (s.languageCode == locale.languageCode) return s;
              }
            }
            return const Locale('ar');
          },
          home: _showLanguageSelection
              ? const LanguageSelectionPage()
              : const SplashScreen(),
        );
      },
    );
  }
}
