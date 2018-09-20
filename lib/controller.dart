import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:maps_flutter/util.dart';

class MapsController extends ChangeNotifier {
  var _zoom;
  var _offsetX;
  var _offsetY;

  bool static;

  double get zoom => _zoom;
  set zoom(double value) {
    if (static) return;
    _zoom = value;
    notifyListeners();
  }

  double get offsetX => _offsetX;
  set offsetX(double value) {
    if (static) return;
    _offsetX = value;
    notifyListeners();
  }

  double get offsetY => _offsetY;
  set offsetY(double value) {
    if (static) return;
    _offsetY = value;
    notifyListeners();
  }

  MapPosition get position => MapPosition(_offsetX, _offsetY, _zoom);

  MapsController({
    double offsetX = 0.5,
    double offsetY = 0.5,
    double zoom = 1.0,
    bool static = false,
  }) {
    this._offsetX = offsetX;
    this._offsetY = offsetY;
    this._zoom = zoom;
    this.static = static;
  }
}