import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/main.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  static const Color tealColor = Color(0xFF2493B4);
  static const Color tealDark = Color(0xFF1E7FA0);
  static const double mekkaLat = 21.4225;
  static const double mekkaLon = 39.8262;

  bool _isLoading = true;
  String? _errorMessage;
  double _qiblaAngle = 0;
  double _deviceHeading = 0;
  String _locationName = '';

  double _ax = 0, _ay = 0, _az = 0;
  StreamSubscription? _accelSub;
  StreamSubscription? _magnetoSub;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _magnetoSub?.cancel();
    super.dispose();
  }

  Future<void> _initSensors() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
          setState(() {
            _errorMessage = AppLocalizations.of(context).tr('qibla.error.location');
            _isLoading = false;
          });
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _qiblaAngle = _calculateQiblaDirection(pos.latitude, pos.longitude);
      _locationName = ', ';

      _accelSub = accelerometerEventStream().listen((e) {
        _ax = e.x;
        _ay = e.y;
        _az = e.z;
      });

      _magnetoSub = magnetometerEventStream().listen((e) {
        final mx = e.x;
        final my = e.y;
        final mz = e.z;

        final phi = atan2(-_ay, -_az);
        final theta = atan2(-_ax * cos(phi) + _az * sin(phi), _ay * sin(phi) + _az * cos(phi));

        final bx = mx * cos(theta) + my * sin(phi) * sin(theta) + mz * cos(phi) * sin(theta);
        final by = my * cos(phi) - mz * sin(phi);

        final heading = atan2(-by, bx) * 180 / pi;
        if (mounted) {
          setState(() => _deviceHeading = (heading + 360) % 360);
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).tr('qibla.error.sensors');
        _isLoading = false;
      });
    }
  }

  double _calculateQiblaDirection(double lat, double lon) {
    final dLon = (mekkaLon - lon) * pi / 180;
    final lat1 = lat * pi / 180;
    final lat2 = mekkaLat * pi / 180;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  double get _effectiveAngle => (_qiblaAngle - _deviceHeading + 360) % 360;

  String _directionLabel(double angle) {
    if (angle >= 337.5 || angle < 22.5) return AppLocalizations.of(context).tr('qibla.north');
    if (angle < 67.5) return AppLocalizations.of(context).tr('qibla.northEast');
    if (angle < 112.5) return AppLocalizations.of(context).tr('qibla.east');
    if (angle < 157.5) return AppLocalizations.of(context).tr('qibla.southEast');
    if (angle < 202.5) return AppLocalizations.of(context).tr('qibla.south');
    if (angle < 247.5) return AppLocalizations.of(context).tr('qibla.southWest');
    if (angle < 292.5) return AppLocalizations.of(context).tr('qibla.west');
    return AppLocalizations.of(context).tr('qibla.northWest');
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
                AppLocalizations.of(context).tr('qibla.appBar.title'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'GE SS Two',
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: isDark ? const Color(0xFFD4B88A) : tealColor),
                  )
                : _errorMessage != null
                ? _buildError(isDark)
                : _buildCompass(isDark),
          ),
        );
      },
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initSensors();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context).tr('qibla.retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context).tr('qibla.heading'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFD4B88A) : null,
                  ),
                ),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CustomPaint(
                        painter: _QiblaCompassPainter(
                          _effectiveAngle * pi / 180,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      child: Text(
                        AppLocalizations.of(context).tr('qibla.north'),
                        style: TextStyle(
                          color: tealColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Text(
                        AppLocalizations.of(context).tr('qibla.south'),
                        style: TextStyle(
                          color: isDark ? Colors.white38 : tealDark.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '${(_effectiveAngle).toStringAsFixed(0)}\u00B0',
                  style: const TextStyle(
                    color: tealColor,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _directionLabel(_qiblaAngle),
                  style: TextStyle(
                    color: isDark ? Colors.white54 : tealDark.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildLocationInfo(isDark),
      ],
    );
  }

  Widget _buildLocationInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF333333) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: tealColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).tr('qibla.location'),
                    style: TextStyle(
                      color: isDark ? const Color(0xFFD4B88A) : tealDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tealColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _locationName,
                      style: const TextStyle(color: tealColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoChip(AppLocalizations.of(context).tr('qibla.deviceHeading'), '${_deviceHeading.toStringAsFixed(0)}\u00B0', isDark),
                  _infoChip(AppLocalizations.of(context).tr('qibla.heading'), '${_qiblaAngle.toStringAsFixed(0)}\u00B0', isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white38 : tealDark.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: isDark ? const Color(0xFFD4B88A) : tealDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _QiblaCompassPainter extends CustomPainter {
  final double effectiveAngleRad;

  _QiblaCompassPainter(this.effectiveAngleRad);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    final ringPaint = Paint()
      ..color = const Color(0xFF2493B4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, ringPaint);

    final innerRingPaint = Paint()
      ..color = const Color(0xFF2493B4).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.92, innerRingPaint);

    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * pi / 180;
      final isCardinal = i % 3 == 0;
      final innerR = radius * (isCardinal ? 0.82 : 0.88);
      final outerR = radius * 0.95;

      final dx1 = center.dx + innerR * sin(angle);
      final dy1 = center.dy - innerR * cos(angle);
      final dx2 = center.dx + outerR * sin(angle);
      final dy2 = center.dy - outerR * cos(angle);

      canvas.drawLine(
        Offset(dx1, dy1),
        Offset(dx2, dy2),
        Paint()
          ..color = isCardinal
              ? const Color(0xFF2493B4)
              : const Color(0xFF2493B4).withValues(alpha: 0.4)
          ..strokeWidth = isCardinal ? 2.5 : 1.5,
      );
    }

    _drawLabel(canvas, center, radius, 0, 'N', const Color(0xFF2493B4));
    _drawLabel(
      canvas,
      center,
      radius,
      90,
      'E',
      const Color(0xFF1E7FA0).withValues(alpha: 0.4),
    );
    _drawLabel(
      canvas,
      center,
      radius,
      180,
      'S',
      const Color(0xFF1E7FA0).withValues(alpha: 0.4),
    );
    _drawLabel(
      canvas,
      center,
      radius,
      270,
      'W',
      const Color(0xFF1E7FA0).withValues(alpha: 0.4),
    );

    // Qibla arrow
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(effectiveAngleRad);

    final shaftPaint = Paint()
      ..color = const Color(0xFF2493B4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(0, -radius * 0.15),
      Offset(0, -radius * 0.75),
      shaftPaint,
    );

    final arrowPaint = Paint()
      ..color = const Color(0xFF2493B4)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, -radius * 0.82);
    path.lineTo(-12, -radius * 0.55);
    path.lineTo(12, -radius * 0.55);
    path.close();
    canvas.drawPath(path, arrowPaint);

    canvas.restore();

    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFF2493B4));
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double degrees,
    String text,
    Color color,
  ) {
    final rad = degrees * pi / 180;
    final r = radius + 16;
    final x = center.dx + r * sin(rad);
    final y = center.dy - r * cos(rad);

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _QiblaCompassPainter oldDelegate) =>
      oldDelegate.effectiveAngleRad != effectiveAngleRad;
}
