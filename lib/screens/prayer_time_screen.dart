import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  static const Color goldColor = Color(0xFFB8964E);
  static const Color darkBrown = Color(0xFF3E2A0F);

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
    _loadPrayerTimes();
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
        _errorMessage = 'تعذر حساب أوقات الصلاة';
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
      return (latitude: 30.0444, longitude: 31.2357, params: p, name: 'مصر');
    }
    if (offset == const Duration(hours: 3)) {
      final p = CalculationMethod.turkey.getParameters();
      p.madhab = Madhab.shafi;
      return (latitude: 41.0082, longitude: 28.9784, params: p, name: 'تركيا');
    }
    if (offset == const Duration(hours: 4)) {
      final p = CalculationMethod.umm_al_qura.getParameters();
      p.madhab = Madhab.shafi;
      return (latitude: 24.4539, longitude: 54.3773, params: p, name: 'الخليج');
    }
    if (offset == const Duration(hours: 5)) {
      final p = CalculationMethod.karachi.getParameters();
      p.madhab = Madhab.hanafi;
      return (
        latitude: 33.6844,
        longitude: 73.0479,
        params: p,
        name: 'باكستان',
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
        name: 'أمريكا الشمالية',
      );
    }
    // Europe or fallback
    final p = CalculationMethod.muslim_world_league.getParameters();
    p.madhab = Madhab.shafi;
    if (offset >= const Duration(hours: 0) &&
        offset <= const Duration(hours: 2)) {
      return (latitude: 51.5074, longitude: -0.1278, params: p, name: 'أوروبا');
    }
    return (
      latitude: 21.4225,
      longitude: 39.8262,
      params: p,
      name: 'منطقة أخرى',
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
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5ECD7),
        appBar: AppBar(
          backgroundColor: const Color(0xFF8B6914),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'أوقات الصلاة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
                child: CircularProgressIndicator(color: Color(0xFF8B6914)),
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
                        color: darkBrown.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6914),
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
                      label: const Text('إعادة المحاولة'),
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
          colors: [Color(0xFF8B6914), Color(0xFFB8964E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B6914).withValues(alpha: 0.3),
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
            'الصلاة القادمة: $nextName',
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
              'متبقي $timeRemaining',
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
              ? const Color(0xFF8B6914)
              : isNext
              ? goldColor.withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isNext
              ? Border.all(color: goldColor.withValues(alpha: 0.5), width: 1.5)
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
                color: isCurrent ? Colors.white : darkBrown,
              ),
            ),

            const Spacer(),

            // اسم الصلاة
            Text(
              _prayerNames[index]['name'],
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.white : darkBrown,
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
                    : goldColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _prayerNames[index]['icon'],
                color: isCurrent ? Colors.white : const Color(0xFF8B6914),
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
                child: const Text(
                  'الآن',
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
                  color: goldColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'قادمة',
                  style: TextStyle(
                    color: Color(0xFF8B6914),
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
