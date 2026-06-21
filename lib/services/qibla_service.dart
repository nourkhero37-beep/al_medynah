import 'dart:math';

class QiblaService {
  static const double mekkaLat = 21.4225;
  static const double mekkaLon = 39.8262;

  static double calculateQiblaDirection(double lat, double lon) {
    final dLon = (mekkaLon - lon) * pi / 180;
    final lat1 = lat * pi / 180;
    final lat2 = mekkaLat * pi / 180;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  static double computeHeading({
    required double ax,
    required double ay,
    required double az,
    required double mx,
    required double my,
    required double mz,
  }) {
    final phi = atan2(-ay, -az);
    final sinPhi = sin(phi);
    final cosPhi = cos(phi);
    final theta = atan2(
      -ax * cosPhi + az * sinPhi,
      ay * sinPhi + az * cosPhi,
    );
    final sinTheta = sin(theta);
    final cosTheta = cos(theta);

    final bx =
        mx * cosTheta + my * sinPhi * sinTheta + mz * cosPhi * sinTheta;
    final by = my * cosPhi - mz * sinPhi;

    final heading = -atan2(by, bx) * 180 / pi;
    return (heading + 360) % 360;
  }

  static double filterHeading(double newHeading, double previousHeading,
      [double factor = 0.20]) {
    double diff = newHeading - previousHeading;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return (previousHeading + factor * diff) % 360;
  }

  static double effectiveAngle(double qiblaAngle, double deviceHeading) {
    return (qiblaAngle - deviceHeading + 180) % 360;
  }
}
