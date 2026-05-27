import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  static const Color goldColor = Color(0xFFB8964E);
  static const Color darkBrown = Color(0xFF3E2A0F);
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
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final granted = await Geolocator.requestPermission();
        if (granted == LocationPermission.denied ||
            granted == LocationPermission.deniedForever) {
          setState(() {
            _errorMessage =
                'يرجى السماح بالوصول إلى الموقع\nلتحديد اتجاه القبلة';
            _isLoading = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _calculateQibla(position.latitude, position.longitude);
      _locationName = '°، °';

      setState(() => _isLoading = false);

      _accelSub = accelerometerEventStream().listen((event) {
        _ax = event.x;
        _ay = event.y;
        _az = event.z;
      });

      _magnetoSub = magnetometerEventStream().listen((event) {
        final heading = _computeHeading(
          _ax,
          _ay,
          _az,
          event.x,
          event.y,
          event.z,
        );
        if (mounted) setState(() => _deviceHeading = heading);
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'تعذر الوصول إلى المستشعرات\nالرجاء التحقق من الإعدادات';
        _isLoading = false;
      });
    }
  }

  void _calculateQibla(double lat, double lon) {
    final lat1 = lat * pi / 180;
    final lon1 = lon * pi / 180;
    final lat2 = mekkaLat * pi / 180;
    final lon2 = mekkaLon * pi / 180;

    final x = sin(lon2 - lon1) * cos(lat2);
    final y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1);

    var angle = atan2(x, y) * 180 / pi;
    if (angle < 0) angle += 360;
    _qiblaAngle = angle;
  }

  double _computeHeading(
    double ax,
    double ay,
    double az,
    double mx,
    double my,
    double mz,
  ) {
    if (az.abs() < 0.001 && ay.abs() < 0.001) return _deviceHeading;

    final roll = atan2(ay, az);
    final pitch = atan2(-ax, ay * sin(roll) + az * cos(roll));

    final mx2 = mx * cos(pitch) + mz * sin(pitch);
    final my2 =
        mx * sin(roll) * sin(pitch) +
        my * cos(roll) -
        mz * sin(roll) * cos(pitch);

    var heading = atan2(-my2, mx2) * 180 / pi;
    if (heading < 0) heading += 360;
    return heading;
  }

  double get _effectiveAngle {
    var angle = _qiblaAngle - _deviceHeading;
    if (angle < 0) angle += 360;
    if (angle >= 360) angle -= 360;
    return angle;
  }

  String _directionLabel(double angle) {
    if (angle >= 315 || angle < 45) return 'شمالاً';
    if (angle >= 45 && angle < 135) return 'شرقاً';
    if (angle >= 135 && angle < 225) return 'جنوباً';
    return 'غرباً';
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
            'القبلة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B6914)),
              )
            : _errorMessage != null
            ? _buildError()
            : _buildCompass(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              style: TextStyle(fontSize: 15, color: darkBrown.withOpacity(0.7)),
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
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initSensors();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'اتجاه القبلة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        'شمال',
                        style: TextStyle(
                          color: goldColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Text(
                        'جنوب',
                        style: TextStyle(
                          color: darkBrown.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '°',
                  style: const TextStyle(
                    color: goldColor,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _directionLabel(_qiblaAngle),
                  style: TextStyle(
                    color: darkBrown.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildLocationInfo(),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
                    color: goldColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'موقعك الحالي',
                    style: TextStyle(
                      color: darkBrown,
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
                      color: goldColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _locationName,
                      style: const TextStyle(color: goldColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoChip('اتجاه الجهاز', '°'),
                  _infoChip('اتجاه القبلة', '°'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: darkBrown.withOpacity(0.5), fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: darkBrown,
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
      ..color = const Color(0xFFB8964E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, ringPaint);

    final innerRingPaint = Paint()
      ..color = const Color(0xFFB8964E).withOpacity(0.3)
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
              ? const Color(0xFFB8964E)
              : const Color(0xFFB8964E).withOpacity(0.4)
          ..strokeWidth = isCardinal ? 2.5 : 1.5,
      );
    }

    _drawLabel(canvas, center, radius, 0, 'N', const Color(0xFFB8964E));
    _drawLabel(
      canvas,
      center,
      radius,
      90,
      'E',
      const Color(0xFF3E2A0F).withOpacity(0.4),
    );
    _drawLabel(
      canvas,
      center,
      radius,
      180,
      'S',
      const Color(0xFF3E2A0F).withOpacity(0.4),
    );
    _drawLabel(
      canvas,
      center,
      radius,
      270,
      'W',
      const Color(0xFF3E2A0F).withOpacity(0.4),
    );

    // Qibla arrow
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(effectiveAngleRad);

    final shaftPaint = Paint()
      ..color = const Color(0xFFB8964E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(0, -radius * 0.15),
      Offset(0, -radius * 0.75),
      shaftPaint,
    );

    final arrowPaint = Paint()
      ..color = const Color(0xFFB8964E)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, -radius * 0.82);
    path.lineTo(-12, -radius * 0.55);
    path.lineTo(12, -radius * 0.55);
    path.close();
    canvas.drawPath(path, arrowPaint);

    canvas.restore();

    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFFB8964E));
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
