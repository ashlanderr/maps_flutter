import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
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
  Color _innerColor;
  double _innerRadius;
  Color _outerColor;
  double _outerRadius;
  double _fullSize;

  GeoPoint get location => _location;
  Size get size => Size(_fullSize, _fullSize);

  CircleMarker({
    @required GeoPoint location,
    Color innerColor,
    double innerRadius,
    Color outerColor,
    double outerRadius,
  }) {
    assert(location != null);
    assert(innerRadius == null || innerRadius >= 0.0);
    assert(outerRadius == null || outerRadius >= 0.0);

    _location = location;
    _innerColor = innerColor;
    _innerRadius = innerRadius;
    _outerColor = outerColor;
    _outerRadius = outerRadius;

    _fullSize = max(innerRadius ?? 0, outerRadius ?? 0) * 2;
  }

  @override
  void paint(Canvas canvas, Offset position) {
    if (_outerColor != null && _outerRadius != null) {
      _markerPaint.color = _outerColor;

      canvas.drawOval(Rect.fromCircle(
        center: position,
        radius: _outerRadius,
      ), _markerPaint);
    }

    if (_innerColor != null && _innerRadius != null) {
      _markerPaint.color = _innerColor;

      canvas.drawOval(Rect.fromCircle(
        center: position,
        radius: _innerRadius,
      ), _markerPaint);
    }
  }
}

class ImageMarker implements Marker {
  static final _markerPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red;

  GeoPoint _location;
  Image _image;
  Offset _anchor;
  Color _color;
  Size _size;

  GeoPoint get location => _location;
  Size get size => _size;

  ImageMarker({
    @required GeoPoint location,
    @required Image image,
    Offset anchor,
    Color color,
    Size size
  }) {
    assert(location != null);

    _location = location;
    _image = image;
    _anchor = anchor ?? Offset(0.5, 1.0);
    _color = color ?? Colors.white;
    _size = size ?? Size(32.0, 32.0);
  }

  @override
  void paint(Canvas canvas, Offset position) {
    if (_image == null) return;

    final srcRect = Rect.fromLTWH(
      0.0,
      0.0,
      _image.width.toDouble(),
      _image.height.toDouble()
    );

    final destRect = Rect.fromLTWH(
      position.dx - _anchor.dx * _size.width,
      position.dy - _anchor.dy * _size.height,
      _size.width,
      _size.height
    );

    _markerPaint.color = _color;
    canvas.drawImageRect(_image, srcRect, destRect, _markerPaint);
  }
}

class MarkersOverlay implements MapOverlay {
  final List<Marker> markers;

  MarkersOverlay({
    @required this.markers
  }) {
    assert(this.markers != null);
  }

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
  final Color innerColor;
  final double innerWidth;
  final Color outerColor;
  final double outerWidth;

  Polyline({
    @required this.points,
    this.innerColor,
    this.innerWidth,
    this.outerColor,
    this.outerWidth,
  }) {
    assert(this.points != null);
    assert(this.innerWidth == null || this.innerWidth >= 0.0);
    assert(this.outerWidth == null || this.outerWidth >= 0.0);
  }
}

class PolylinesOverlay implements MapOverlay {
  static final _polylinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.green
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = 2.0;

  final List<Polyline> polylines;

  PolylinesOverlay({
    @required this.polylines
  }) {
    assert(this.polylines != null);
  }

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

    if (polyline.outerColor != null && polyline.outerWidth != null) {
      _polylinePaint.color = polyline.outerColor;
      _polylinePaint.strokeWidth = polyline.outerWidth;
      canvas.drawPoints(PointMode.polygon, points, _polylinePaint);
    }

    if (polyline.innerColor != null && polyline.innerWidth != null) {
      _polylinePaint.color = polyline.innerColor;
      _polylinePaint.strokeWidth = polyline.innerWidth;
      canvas.drawPoints(PointMode.polygon, points, _polylinePaint);
    }
  }
}