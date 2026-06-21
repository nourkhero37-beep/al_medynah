import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

class HomePageHelper {
  static String toWesternNumerals(String s) {
    return String.fromCharCodes(s.codeUnits.map((code) {
      if (code >= 0x0660 && code <= 0x0669) {
        return code - 0x0660 + 48;
      }
      if (code >= 0x06F0 && code <= 0x06F9) {
        return code - 0x06F0 + 48;
      }
      return code;
    }));
  }

  static String formatHijriDate(String localeCode) {
    final locale = switch (localeCode) {
      'ar' => 'ar',
      _ => 'en',
    };
    HijriCalendar.setLocal(locale);
    return HijriCalendar.fromDate(DateTime.now()).fullDate();
  }

  static String currentLanguageName(
    AppLocalizations loc,
    Locale currentLocale,
  ) {
    switch (currentLocale.languageCode) {
      case 'ar':
        return loc.tr('lang.arabic');
      case 'en':
        return loc.tr('lang.english');
      case 'tr':
        return loc.tr('lang.turkish');
      default:
        return loc.tr('lang.arabic');
    }
  }
}
