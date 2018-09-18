import 'dart:math';
import 'dart:ui';

const TILE_SIZE = 256.0;

class GeoPoint {
  final double latitude;
  final double longitude;

  GeoPoint(this.latitude, this.longitude);
}

class MapPosition {
  final double offsetX;
  final double offsetY;
  final double zoom;

  MapPosition(this.offsetX, this.offsetY, this.zoom);
}

double tile2lng(x) {
  return (x * 360 - 180);
}

double tile2lat(y) {
  final n = pi - 2 * pi * y;
  return (180 / pi * atan(0.5 * (exp(n) - exp(-n))));
}

double lng2tile(lng) {
  return (lng + 180) / 360;
}

double lat2tile(lat) {
  final r = lat / 180 * pi;
  return (1 - (log(tan(r) + (1 / cos(r))) / pi)) / 2;
}

Offset geo2screen(GeoPoint point, MapPosition pos, Size size) {
  final y = lat2tile(point.latitude);
  final x = lng2tile(point.longitude);

  final cx = size.width / 2.0 - ((pos.offsetX - x) * pos.zoom * TILE_SIZE);
  final cy = size.height / 2.0 - ((pos.offsetY - y) * pos.zoom * TILE_SIZE);

  return Offset(cx, cy);
}