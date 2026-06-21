import 'package:adhan/adhan.dart';

class PrayerTimeService {
  static ({
    double latitude,
    double longitude,
    CalculationParameters params,
    String name,
  }) regionFromTimezone(
    Duration offset,
    String Function(String) tr,
  ) {
    if (offset == const Duration(hours: 2)) {
      final p = CalculationMethod.egyptian.getParameters();
      p.madhab = Madhab.shafi;
      return (
        latitude: 30.0444,
        longitude: 31.2357,
        params: p,
        name: tr('prayer.region.egypt'),
      );
    }
    if (offset == const Duration(hours: 3)) {
      final p = CalculationMethod.turkey.getParameters();
      p.madhab = Madhab.shafi;
      return (
        latitude: 41.0082,
        longitude: 28.9784,
        params: p,
        name: tr('prayer.region.turkey'),
      );
    }
    if (offset == const Duration(hours: 4)) {
      final p = CalculationMethod.umm_al_qura.getParameters();
      p.madhab = Madhab.shafi;
      return (
        latitude: 24.4539,
        longitude: 54.3773,
        params: p,
        name: tr('prayer.region.gulf'),
      );
    }
    if (offset == const Duration(hours: 5)) {
      final p = CalculationMethod.karachi.getParameters();
      p.madhab = Madhab.hanafi;
      return (
        latitude: 33.6844,
        longitude: 73.0479,
        params: p,
        name: tr('prayer.region.pakistan'),
      );
    }
    if (offset >= const Duration(hours: -10) &&
        offset <= const Duration(hours: -5)) {
      final p = CalculationMethod.north_america.getParameters();
      p.madhab = Madhab.shafi;
      return (
        latitude: 40.7128,
        longitude: -74.0060,
        params: p,
        name: tr('prayer.region.northAmerica'),
      );
    }
    final p = CalculationMethod.muslim_world_league.getParameters();
    p.madhab = Madhab.shafi;
    if (offset >= const Duration(hours: 0) &&
        offset <= const Duration(hours: 2)) {
      return (
        latitude: 51.5074,
        longitude: -0.1278,
        params: p,
        name: tr('prayer.region.europe'),
      );
    }
    return (
      latitude: 21.4225,
      longitude: 39.8262,
      params: p,
      name: tr('prayer.region.other'),
    );
  }

  static List<DateTime> getPrayerTimesList(PrayerTimes times) {
    return [
      times.fajr,
      times.sunrise,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ];
  }

  static int getCurrentPrayerIndex(PrayerTimes times, DateTime now) {
    final prayer = times.currentPrayerByDateTime(now);
    switch (prayer) {
      case Prayer.fajr:
        return 0;
      case Prayer.sunrise:
        return 1;
      case Prayer.dhuhr:
        return 2;
      case Prayer.asr:
        return 3;
      case Prayer.maghrib:
        return 4;
      case Prayer.isha:
        return 5;
      default:
        return -1;
    }
  }

  static int getNextPrayerIndex(PrayerTimes times, DateTime now) {
    final prayer = times.nextPrayerByDateTime(now);
    switch (prayer) {
      case Prayer.fajr:
        return 0;
      case Prayer.sunrise:
        return 1;
      case Prayer.dhuhr:
        return 2;
      case Prayer.asr:
        return 3;
      case Prayer.maghrib:
        return 4;
      case Prayer.isha:
        return 5;
      default:
        return -1;
    }
  }

  static String getTimeRemaining(PrayerTimes times, DateTime now) {
    final nextPrayer = times.nextPrayerByDateTime(now);
    final nextTime = times.timeForPrayer(nextPrayer);
    if (nextTime == null) return '';

    final diff = nextTime.difference(now);
    if (diff.isNegative) return '';

    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  static String formatTime(DateTime time, String Function(String) tr) {
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0
            ? 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period =
        time.hour >= 12 ? tr('prayer.pm') : tr('prayer.am');
    return '$hour:$minute $period';
  }
}
