library maps_flutter;

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:http/http.dart' as http;

const TILE_SIZE = 256.0;

double _tile2lng(x) {
  return (x * 360 - 180);
}

double _tile2lat(y) {
  final n = pi - 2 * pi * y;
  return (180 / pi * atan(0.5 * (exp(n) - exp(-n))));
}

double _lng2tile(lng) {
  return (lng + 180) / 360;
}

double _lat2tile(lat) {
  final r = lat / 180 * pi;
  return (1 - (log(tan(r) + (1 / cos(r))) / pi)) / 2;
}

Offset _geo2screen(GeoPoint point, double offsetX, double offsetY, double zoom, Size size) {
  final y = _lat2tile(point.latitude);
  final x = _lng2tile(point.longitude);

  final cx = size.width / 2.0 - ((offsetX - x) * zoom * TILE_SIZE);
  final cy = size.height / 2.0 - ((offsetY - y) * zoom * TILE_SIZE);

  return Offset(cx, cy);
}

class GeoPoint {
  final double latitude;
  final double longitude;

  GeoPoint(this.latitude, this.longitude);
}

class MapMarker {
  final GeoPoint location;
  final Color color;

  MapMarker({this.location, this.color});
}

class MapPolyline {
  final List<GeoPoint> points;

  MapPolyline({this.points});
}

class MapOverlay {
  final List<MapMarker> markers;
  final List<MapPolyline> polylines;

  MapOverlay({
    List<MapMarker> markers,
    List<MapPolyline> polylines,
  })
    : markers = markers ?? [],
      polylines = polylines ?? [];
}

abstract class TileProvider {
  Future<Image> fetch(int level, int x, int y);
}

class OpenStreetMap implements TileProvider {
  @override
  Future<Image> fetch(int level, int x, int y) async {
    final url = "https://a.tile.openstreetmap.org/$level/$x/$y.png";
    final response = await http.get(url);
    final bytes = response.bodyBytes;
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

class MapsWidget extends StatefulWidget {
  final List<MapOverlay> overlays;
  final TileProvider tileProvider;

  MapsWidget({
    List<MapOverlay> overlays,
    TileProvider tileProvider,
  })
    : overlays = overlays ?? [],
      tileProvider = tileProvider ?? OpenStreetMap();

  @override
  _MapsWidgetState createState() => _MapsWidgetState();
}

class _MapsWidgetState extends State<MapsWidget> {
  // todo cache eviction
  final Map<TileId, Image> _cache = {};
  final Set<TileId> _loading = Set();

  var _zoom = 1.0;
  var _offsetX = 0.5;
  var _offsetY = 0.5;

  double _tempZoom;
  double _tempFocalX;
  double _tempFocalY;

  @override
  Widget build(BuildContext context) {
    final layers = <Widget>[];
    layers.add(_buildMap());
    for (final overlay in widget.overlays)
      layers.add(_buildOverlay(overlay));

    return GestureDetector(
      onScaleStart: _scaleStart,
      onScaleEnd: _scaleEnd,
      onScaleUpdate: _scaleUpdate,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: layers,
        ),
      ),
    );
  }

  Widget _buildMap() {
    return CustomPaint(
      painter: MapPainter(
        offsetX: _offsetX,
        offsetY: _offsetY,
        zoom: _zoom,
        tiles: _cache,
        requestTile: _fetchImage,
      ),
    );
  }

  Widget _buildOverlay(MapOverlay overlay) {
    return CustomPaint(
      painter: OverlayPainter(
        offsetX: _offsetX,
        offsetY: _offsetY,
        zoom: _zoom,
        overlay: overlay
      ),
    );
  }

  void _fetchImage(TileId id) async {
    if (_loading.contains(id)) return;

    try {
      _loading.add(id);

      final image = await widget.tileProvider.fetch(id.level, id.x, id.y);

      setState(() {
        _cache[id] = image;
      });
    } finally {
      _loading.remove(id);
    }
  }

  void _scaleStart(ScaleStartDetails event) {
    _tempZoom = _zoom;
    _tempFocalX = event.focalPoint.dx;
    _tempFocalY = event.focalPoint.dy;
  }

  void _scaleEnd(ScaleEndDetails event) {
    _tempZoom = null;
    _tempFocalX = null;
    _tempFocalY = null;
  }

  void _scaleUpdate(ScaleUpdateDetails event) {
    setState(() {
      _zoom = _tempZoom * event.scale;
      _offsetX += (_tempFocalX - event.focalPoint.dx) * 0.003 / _zoom;
      _offsetY += (_tempFocalY - event.focalPoint.dy) * 0.003 / _zoom;
      _tempFocalX = event.focalPoint.dx;
      _tempFocalY = event.focalPoint.dy;
    });
  }
}

class TileId {
  final int level;
  final int x;
  final int y;

  TileId(this.level, this.x, this.y);

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
      other is TileId &&
        runtimeType == other.runtimeType &&
        level == other.level &&
        x == other.x &&
        y == other.y;

  @override
  int get hashCode =>
    level.hashCode ^
    x.hashCode ^
    y.hashCode;
}

class MapPainter extends CustomPainter {
  static final Paint _paint = Paint()
    ..color = Colors.black
    ..strokeWidth = 1.0
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..style = PaintingStyle.stroke;

  final double offsetX;
  final double offsetY;
  final double zoom;
  final Map<TileId, Image> tiles;
  final ValueChanged<TileId> requestTile;

  final Map<int, int> metrics = {};

  MapPainter({this.offsetX, this.offsetY, this.zoom, this.tiles, this.requestTile});

  @override
  void paint(Canvas canvas, Size size) {
    metrics.clear();
    _paintTile(canvas, size, 0, 0, 0);
    //print(metrics);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    final old = oldDelegate as MapPainter;
    return old.offsetX != offsetX || old.offsetY != offsetY || old.zoom != zoom || old.tiles != tiles;
  }

  void _paintTile(Canvas canvas, Size size, int level, int x, int y) {
    final levelZoom = (1 << level);
    final tileSize = TILE_SIZE / levelZoom * zoom;

    final tx = (x + 0.5) / levelZoom;
    final ty = (y + 0.5) / levelZoom;

    final cx = size.width / 2.0 - ((offsetX - tx) * zoom * TILE_SIZE);
    final cy = size.height / 2.0 - ((offsetY - ty) * zoom * TILE_SIZE);

    final bx = cx - tileSize / 2;
    final by = cy - tileSize / 2;
    final ex = cx + tileSize / 2;
    final ey = cy + tileSize / 2;

    if (bx > size.width) return;
    if (by > size.height) return;
    if (ex < 0) return;
    if (ey < 0) return;

    metrics[level] = (metrics[level] ?? 0) + 1;

    final tileId = TileId(level, x, y);
    final image = tiles[tileId];
    final destRect = Rect.fromLTRB(bx, by, ex, ey);
    final finalTile = tileSize <= TILE_SIZE * 1.4;

    if (image != null) {
      final srcRect = Rect.fromLTRB(0.0, 0.0, image.width.toDouble(), image.height.toDouble());
      _paint.filterQuality = finalTile ? FilterQuality.low : FilterQuality.none;
      canvas.drawImageRect(image, srcRect, destRect, _paint);
    } else {
      requestTile(tileId);
    }

    if (!finalTile) {
      for (var i = 0; i < 2; ++i) {
        for (var j = 0; j < 2; ++j) {
          _paintTile(canvas, size, level + 1, x * 2 + i, y * 2 + j);
        }
      }
    }
  }
}

class OverlayPainter extends CustomPainter {
  static final _markerPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red;

  static final _polylinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.green
    ..strokeWidth = 2.0;

  final double offsetX;
  final double offsetY;
  final double zoom;
  final MapOverlay overlay;

  OverlayPainter({this.offsetX, this.offsetY, this.zoom, this.overlay});

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final marker in overlay.markers) {
      _paintMarker(canvas, size, marker);
    }
    for (final polyline in overlay.polylines) {
      _paintPolyline(canvas, size, polyline);
    }
  }

  void _paintMarker(Canvas canvas, Size size, MapMarker marker) {
    final p = _geo2screen(marker.location, offsetX, offsetY, zoom, size);
    _markerPaint.color = marker.color ?? Colors.red;
    canvas.drawOval(Rect.fromCircle(
      center: p,
      radius: 4.0
    ), _markerPaint);
  }

  void _paintPolyline(Canvas canvas, Size size, MapPolyline polyline) {
    final points = polyline
      .points
      .map((p) => _geo2screen(p, offsetX, offsetY, zoom, size))
      .toList();
    canvas.drawPoints(PointMode.polygon, points, _polylinePaint);
  }
}