import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart' show rootBundle;
import 'package:maps_flutter/maps_flutter.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Image _markerImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapsWidget(
        overlays: [
          PolylinesOverlay(
            polylines: [
              Polyline(
                innerColor: Colors.blue,
                innerWidth: 6.0,
                outerColor: Colors.white,
                outerWidth: 10.0,
                points: [
                  GeoPoint(55.766947, 37.538006),
                  GeoPoint(55.791650, 37.574058),
                ],
              ),
            ],
          ),
          MarkersOverlay(
            markers: [
              CircleMarker(
                innerRadius: 8.0,
                innerColor: Colors.red,
                outerRadius: 10.0,
                outerColor: Colors.white,
                location: GeoPoint(55.766947, 37.538006),
              ),
              CircleMarker(
                innerRadius: 12.0,
                innerColor: Colors.green,
                location: GeoPoint(55.791650, 37.574058),
              ),
              ImageMarker(
                location: GeoPoint(55.766947, 37.558006),
                image: _markerImage,
                size: Size(32.0, 32.0),
              )
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() async {
    try {
      final data = await rootBundle.load("assets/map-marker-icon.png");
      final codec = await instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      setState(() {
        _markerImage = frame.image;
      });
    } catch (ex) {
      print(ex);
    }
  }
}
