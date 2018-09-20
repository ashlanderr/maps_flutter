import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:maps_flutter/util.dart';

abstract class MapOverlay {
  void paint(Canvas canvas, Size size, MapPosition pos);
}

abstract class Marker {
  GeoPoint get location;
  Size get size;

  void paint(Canvas canvas, Offset position);
}

class CircleMarker implements Marker {
  static final _markerPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red;

  GeoPoint _location;
  Color _color;
  double _radius;

  GeoPoint get location => _location;
  Size get size => Size(_radius * 2, _radius * 2);

  CircleMarker({
    GeoPoint location,
    Color color = Colors.red,
    double radius = 4.0
  }) {
    _location = location;
    _color = color;
    _radius = radius;
  }

  @override
  void paint(Canvas canvas, Offset position) {
    _markerPaint.color = _color;

    canvas.drawOval(Rect.fromCircle(
      center: position,
      radius: _radius,
    ), _markerPaint);
  }
}

class MarkersOverlay implements MapOverlay {
  final List<Marker> markers;

  MarkersOverlay({this.markers});

  @override
  void paint(Canvas canvas, Size size, MapPosition pos) {
    for (final marker in markers) {
      _paintMarker(canvas, size, pos, marker);
    }
  }

  void _paintMarker(Canvas canvas, Size size, MapPosition pos, Marker marker) {
    final p = geo2screen(marker.location, pos, size);
    marker.paint(canvas, p);
  }
}

class Polyline {
  final List<GeoPoint> points;
  final Color color;
  final double width;

  Polyline({
    this.points,
    this.color = Colors.red,
    this.width = 2.0,
  });
}

class PolylinesOverlay implements MapOverlay {
  static final _polylinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.green
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = 2.0;

  final List<Polyline> polylines;

  PolylinesOverlay({this.polylines});

  @override
  void paint(Canvas canvas, Size size, MapPosition pos) {
    for (final polyline in polylines) {
      _paintPolyline(canvas, size, pos, polyline);
    }
  }

  void _paintPolyline(Canvas canvas, Size size, MapPosition pos, Polyline polyline) {
    final points = polyline
      .points
      .map((p) => geo2screen(p, pos, size))
      .toList();

    _polylinePaint.color = polyline.color;
    _polylinePaint.strokeWidth = polyline.width;

    canvas.drawPoints(PointMode.polygon, points, _polylinePaint);
  }
}