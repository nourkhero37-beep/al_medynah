import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:al_medynah/l10n/app_localizations.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  static const Color tealColor = Color(0xFF2493B4);
  static const Color tealDark = Color(0xFF1E7FA0);

  PrayerTimes? _prayerTimes;
  bool _isLoading = true;
  String? _errorMessage;
  String _locationName = '';
  late Timer _timer;
  DateTime _now = DateTime.now();

  // أسماء الصلوات بالعربي
  final List<Map<String, dynamic>> _prayerNames = [
    {'name': 'الفجر', 'icon': Icons.brightness_3_rounded},
    {'name': 'الشروق', 'icon': Icons.wb_twilight_rounded},
    {'name': 'الظهر', 'icon': Icons.wb_sunny_rounded},
    {'name': 'العصر', 'icon': Icons.cloud_rounded},
    {'name': 'المغرب', 'icon': Icons.nights_stay_rounded},
    {'name': 'العشاء', 'icon': Icons.dark_mode_rounded},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrayerTimes());
    // تحديث الوقت كل ثانية
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final offset = DateTime.now().timeZoneOffset;
      final region = _regionFromTimezone(offset);

      final coordinates = Coordinates(region.latitude, region.longitude);
      final params = region.params;

      final date = DateComponents.from(DateTime.now());
      final prayerTimes = PrayerTimes(coordinates, date, params);

      setState(() {
        _prayerTimes = prayerTimes;
        _locationName = region.name;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).tr('prayer.error.calculate');
        _isLoading = false;
      });
    }
  }

  ({
    double latitude,
    double longitude,
    CalculationParameters params,
    String name,
  })
  _regionFromTimezone(Duration offset) {
    if (offset == const Duration(hours: 2)) {
      final p = CalculationMethod.egyptian.getParameters();
      p.madhab = Madhab.shafi;
      return (latitude: 30.0444, longitude: 31.2357, params: p, name: AppLocalizations.of(context).tr('prayer.region.egypt'));
    }
    if (offset == const Duration(hours: 3)) {
      final p = CalculationMethod.turkey.getParameters();
      p.madhab = Madhab.shafi;
      return (latitude: 41.0082, longitude: 28.9784, params: p, name: AppLocalizations.of(context).tr('prayer.region.turkey'));
    }
    if (offset == const Duration(hours: 4)) {
      final p = CalculationMethod.umm_al_qura.getParameters();
      p.madhab = Madhab.shafi;
      return (latitude: 24.4539, longitude: 54.3773, params: p, name: AppLocalizations.of(context).tr('prayer.region.gulf'));
    }
    if (offset == const Duration(hours: 5)) {
      final p = CalculationMethod.karachi.getParameters();
      p.madhab = Madhab.hanafi;
      return (
        latitude: 33.6844,
        longitude: 73.0479,
        params: p,
        name: AppLocalizations.of(context).tr('prayer.region.pakistan'),
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
        name: AppLocalizations.of(context).tr('prayer.region.northAmerica'),
      );
    }
    // Europe or fallback
    final p = CalculationMethod.muslim_world_league.getParameters();
    p.madhab = Madhab.shafi;
    if (offset >= const Duration(hours: 0) &&
        offset <= const Duration(hours: 2)) {
      return (latitude: 51.5074, longitude: -0.1278, params: p, name: AppLocalizations.of(context).tr('prayer.region.europe'));
    }
    return (
      latitude: 21.4225,
      longitude: 39.8262,
      params: p,
      name: AppLocalizations.of(context).tr('prayer.region.other'),
    );
  }

  List<DateTime> _getPrayerTimesList() {
    if (_prayerTimes == null) return [];
    return [
      _prayerTimes!.fajr,
      _prayerTimes!.sunrise,
      _prayerTimes!.dhuhr,
      _prayerTimes!.asr,
      _prayerTimes!.maghrib,
      _prayerTimes!.isha,
    ];
  }

  // الصلاة الحالية أو القادمة
  int _getCurrentPrayerIndex() {
    if (_prayerTimes == null) return -1;
    final prayer = _prayerTimes!.currentPrayerByDateTime(_now);
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

  int _getNextPrayerIndex() {
    if (_prayerTimes == null) return -1;
    final prayer = _prayerTimes!.nextPrayerByDateTime(_now);
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

  // الوقت المتبقي للصلاة القادمة
  String _getTimeRemaining() {
    if (_prayerTimes == null) return '';
    final nextPrayer = _prayerTimes!.nextPrayerByDateTime(_now);
    final nextTime = _prayerTimes!.timeForPrayer(nextPrayer);
    if (nextTime == null) return '';

    final diff = nextTime.difference(_now);
    if (diff.isNegative) return '';

    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0
        ? 12
        : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? AppLocalizations.of(context).tr('prayer.pm') : AppLocalizations.of(context).tr('prayer.am');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: tealColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppLocalizations.of(context).tr('prayer.appBar.title'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'GE SS Two',
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: _loadPrayerTimes,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: tealColor),
              )
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off_rounded,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: tealDark.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tealColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _loadPrayerTimes,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(AppLocalizations.of(context).tr('prayer.retry')),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // كارد الوقت المتبقي
                    _buildNextPrayerCard(),
                    const SizedBox(height: 16),
                    // قائمة الصلوات
                    ..._buildPrayerCards(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNextPrayerCard() {
    final nextIndex = _getNextPrayerIndex();
    final timeRemaining = _getTimeRemaining();
    final nextName = nextIndex >= 0 ? _prayerNames[nextIndex]['name'] : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [tealColor, tealDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: tealColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // الموقع
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                _locationName,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // الوقت الحالي
          Text(
            _formatTime(_now),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          // الصلاة القادمة
          Text(
            AppLocalizations.of(context).tr('prayer.next', {'name': nextName}),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          // الوقت المتبقي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppLocalizations.of(context).tr('prayer.remaining', {'time': timeRemaining}),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPrayerCards() {
    final times = _getPrayerTimesList();
    final currentIndex = _getCurrentPrayerIndex();
    final nextIndex = _getNextPrayerIndex();

    return List.generate(_prayerNames.length, (index) {
      final isCurrent = index == currentIndex;
      final isNext = index == nextIndex;
      final time = times[index];

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCurrent
              ? tealColor
              : isNext
              ? tealColor.withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isNext
              ? Border.all(color: tealColor.withValues(alpha: 0.5), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // الوقت
            Text(
              _formatTime(time),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.white : tealDark,
              ),
            ),

            const Spacer(),

            // اسم الصلاة
            Text(
              _prayerNames[index]['name'],
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.white : tealDark,
              ),
            ),

            const SizedBox(width: 12),

            // الأيقونة
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCurrent
                    ? Colors.white.withValues(alpha: 0.2)
                    : tealColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _prayerNames[index]['icon'],
                color: isCurrent ? Colors.white : tealColor,
                size: 20,
              ),
            ),

            // علامة الصلاة الحالية
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context).tr('prayer.now'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            if (isNext && !isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tealColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context).tr('prayer.upcoming'),
                  style: TextStyle(
                    color: tealColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}


