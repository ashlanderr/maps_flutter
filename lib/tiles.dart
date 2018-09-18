import 'dart:async';
import 'dart:ui';

import 'package:http/http.dart' as http;

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