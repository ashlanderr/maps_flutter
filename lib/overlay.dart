import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:maps_flutter/util.dart';

abstract class MapOverlay {
  void paint(Canvas canvas, Size size, MapPosition pos);
}

class Marker {
  final GeoPoint location;
  final Color color;

  Marker({this.location, this.color});
}

class MarkersOverlay implements MapOverlay {
  static final _markerPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red;

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
    _markerPaint.color = marker.color ?? Colors.red;
    canvas.drawOval(Rect.fromCircle(
      center: p,
      radius: 4.0
    ), _markerPaint);
  }
}

class Polyline {
  final List<GeoPoint> points;

  Polyline({this.points});
}

class PolylinesOverlay implements MapOverlay {
  static final _polylinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.green
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
    canvas.drawPoints(PointMode.polygon, points, _polylinePaint);
  }
}