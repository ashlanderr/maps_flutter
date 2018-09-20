library maps_flutter;

import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:maps_flutter/overlay.dart';
import 'package:maps_flutter/tiles.dart';
import 'package:maps_flutter/controller.dart';
import 'package:maps_flutter/util.dart';

export 'package:maps_flutter/overlay.dart';
export 'package:maps_flutter/tiles.dart';
export 'package:maps_flutter/controller.dart';
export 'package:maps_flutter/util.dart';

class MapsWidget extends StatefulWidget {
  final List<MapOverlay> overlays;
  final TileProvider tileProvider;
  final MapsController controller;

  MapsWidget({
    List<MapOverlay> overlays,
    TileProvider tileProvider,
    MapsController controller,
  })
    : overlays = overlays ?? [],
      tileProvider = tileProvider ?? OpenStreetMap(),
      controller = controller;

  @override
  MapsWidgetState createState() => MapsWidgetState();
}

class MapsWidgetState extends State<MapsWidget> {
  // todo cache eviction
  final Map<TileId, Image> _cache = {};
  final Set<TileId> _loading = Set();
  MapsController _controller;

  double _tempScale;
  Offset _tempFocal;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? MapsController();
    _controller.addListener(_stateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_stateChanged);
    super.dispose();
  }

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

  void _stateChanged() {
    setState(() {});
  }

  Widget _buildMap() {
    return CustomPaint(
      painter: MapPainter(
        position: _controller.position,
        tiles: _cache,
        requestTile: _fetchImage,
      ),
    );
  }

  Widget _buildOverlay(MapOverlay overlay) {
    return CustomPaint(
      painter: OverlayPainter(
        position: _controller.position,
        overlay: overlay
      ),
    );
  }

  void _fetchImage(TileId id) async {
    if (_loading.contains(id)) return;

    try {
      _loading.add(id);

      final image = await widget.tileProvider.fetch(id.level, id.x, id.y);

      if (mounted) {
        setState(() {
          _cache[id] = image;
        });
      }
    } finally {
      _loading.remove(id);
    }
  }

  void _scaleStart(ScaleStartDetails event) {
    _tempScale = 1.0;
    _tempFocal = event.focalPoint;
  }

  void _scaleEnd(ScaleEndDetails event) {
    _tempScale = null;
    _tempFocal = null;
  }

  void _scaleUpdate(ScaleUpdateDetails event) {
    // some crazy math here

    final deltaScale = event.scale / _tempScale;
    final deltaFocal = event.focalPoint - _tempFocal;
    _tempScale = event.scale;
    _tempFocal = event.focalPoint;

    final loc = screen2tile(event.focalPoint, _controller.position, context.size);

    final oldZoom = _controller.zoom;
    final newZoom = oldZoom * deltaScale;

    final cx = _controller.offsetX;
    final cy = _controller.offsetY;

    // compute new center tile position, so the focal point stays in the same tile coordinates
    final x = (loc.dx * (newZoom - oldZoom) + cx * oldZoom) / newZoom;
    final y = (loc.dy * (newZoom - oldZoom) + cy * oldZoom) / newZoom;

    // compute center tile position shift due to the focal point dragging
    final dx = deltaFocal.dx / (TILE_SIZE * oldZoom);
    final dy = deltaFocal.dy / (TILE_SIZE * newZoom);

    _controller.zoom = newZoom;
    _controller.offsetX = x - dx;
    _controller.offsetY = y - dy;
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

  final MapPosition position;
  final Map<TileId, Image> tiles;
  final ValueChanged<TileId> requestTile;

  final Map<int, int> metrics = {};

  MapPainter({this.position, this.tiles, this.requestTile});

  @override
  void paint(Canvas canvas, Size size) {
    metrics.clear();
    _paintTile(canvas, size, 0, 0, 0);
    //print(metrics);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    final old = oldDelegate as MapPainter;
    return old.position != position || old.tiles != tiles;
  }

  void _paintTile(Canvas canvas, Size size, int level, int x, int y) {
    final levelZoom = (1 << level);
    final tileSize = TILE_SIZE / levelZoom * position.zoom;

    final tx = (x + 0.5) / levelZoom;
    final ty = (y + 0.5) / levelZoom;

    final cx = size.width / 2.0 - ((position.offsetX - tx) * position.zoom * TILE_SIZE);
    final cy = size.height / 2.0 - ((position.offsetY - ty) * position.zoom * TILE_SIZE);

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
  final MapPosition position;
  final MapOverlay overlay;

  OverlayPainter({this.position, this.overlay});

  @override
  void paint(Canvas canvas, Size size) {
    overlay.paint(canvas, size, this.position);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}