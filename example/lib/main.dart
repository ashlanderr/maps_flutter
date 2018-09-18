import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapsWidget(
        overlays: [
          PolylinesOverlay(
            polylines: [
              Polyline(
                points: [
                  GeoPoint(55.766947, 37.538006),
                  GeoPoint(55.791650, 37.574058),
                ],
              ),
            ],
          ),
          MarkersOverlay(
            markers: [
              Marker(
                location: GeoPoint(55.766947, 37.538006),
              ),
              Marker(
                location: GeoPoint(55.791650, 37.574058),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
