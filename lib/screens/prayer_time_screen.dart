import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/main.dart';
import 'package:al_medynah/services/prayer_time_service.dart';

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

  final List<Map<String, dynamic>> _prayerNames = [
    {'name': '\u0627\u0644\u0641\u062C\u0631', 'icon': Icons.brightness_3_rounded},
    {'name': '\u0627\u0644\u0634\u0631\u0648\u0642', 'icon': Icons.wb_twilight_rounded},
    {'name': '\u0627\u0644\u0638\u0647\u0631', 'icon': Icons.wb_sunny_rounded},
    {'name': '\u0627\u0644\u0639\u0635\u0631', 'icon': Icons.cloud_rounded},
    {'name': '\u0627\u0644\u0645\u063A\u0631\u0628', 'icon': Icons.nights_stay_rounded},
    {'name': '\u0627\u0644\u0639\u0634\u0627\u0621', 'icon': Icons.dark_mode_rounded},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrayerTimes());
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
      final region = PrayerTimeService.regionFromTimezone(offset, AppLocalizations.of(context).tr);

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







  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appDarkModeNotifier,
      builder: (context, isDark, _) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF1A1A2E) : tealColor,
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
                ? Center(
                    child: CircularProgressIndicator(color: isDark ? const Color(0xFFD4B88A) : tealColor),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_rounded,
                          size: 64,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white54 : tealDark.withValues(alpha: 0.7),
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
                        _buildNextPrayerCard(),
                        const SizedBox(height: 16),
                        ..._buildPrayerCards(isDark),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildNextPrayerCard() {
    final nextIndex = PrayerTimeService.getNextPrayerIndex(_prayerTimes!, _now);
    final timeRemaining = PrayerTimeService.getTimeRemaining(_prayerTimes!, _now);
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
          Text(
            PrayerTimeService.formatTime(_now, AppLocalizations.of(context).tr),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).tr('prayer.next', {'name': nextName}),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
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

  List<Widget> _buildPrayerCards(bool isDark) {
    final times = PrayerTimeService.getPrayerTimesList(_prayerTimes!);
    final currentIndex = PrayerTimeService.getCurrentPrayerIndex(_prayerTimes!, _now);
    final nextIndex = PrayerTimeService.getNextPrayerIndex(_prayerTimes!, _now);

    return List.generate(_prayerNames.length, (index) {
      final isCurrent = index == currentIndex;
      final isNext = index == nextIndex;
      final time = times[index];
      final defaultCardColor = isDark ? const Color(0xFF333333) : Colors.white;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCurrent
              ? tealColor
              : isNext
              ? tealColor.withValues(alpha: 0.15)
              : defaultCardColor,
          borderRadius: BorderRadius.circular(16),
          border: isNext
              ? Border.all(color: tealColor.withValues(alpha: 0.5), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              PrayerTimeService.formatTime(time, AppLocalizations.of(context).tr),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.white : (isDark ? const Color(0xFFD4B88A) : tealDark),
              ),
            ),

            const Spacer(),

            Text(
              _prayerNames[index]['name'],
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.white : (isDark ? Colors.white70 : tealDark),
              ),
            ),

            const SizedBox(width: 12),

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

