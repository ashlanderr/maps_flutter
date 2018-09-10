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
          MapOverlay(
            polylines: [
              MapPolyline(
                points: [
                  GeoPoint(55.766947, 37.538006),
                  GeoPoint(55.791650, 37.574058),
                ],
              ),
            ],
          ),
          MapOverlay(
            markers: [
              MapMarker(
                location: GeoPoint(55.766947, 37.538006),
              ),
              MapMarker(
                location: GeoPoint(55.791650, 37.574058),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
