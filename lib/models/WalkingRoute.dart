import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class WalkingRoute {
  Set<Polyline> allpolylines;
  String encodedEntirePolyline;
  List<LatLng> allPoints;
  int distanceMeters;
  double duration;
  String navigationsteps;

  WalkingRoute({
    required this.encodedEntirePolyline,
    required this.distanceMeters,
    required this.duration,
    required this.navigationsteps,
  })  : allpolylines = {},
        allPoints = [] {
    setAllPoints();

    // Create a single polyline with allpoints
    Polyline polyline = Polyline(
      polylineId: PolylineId(this.encodedEntirePolyline),
      color: Colors.pink,
      points: this.allPoints,
      width: 8,
    );
    this.allpolylines.add(polyline);
  }
  
  
  factory WalkingRoute.fromJson(Map<String, dynamic> json) {
    List<String?> navigationSteps = WalkingRoute.navigationStepsFromJson(json);
    List<String?> nonNullNavigationSteps =
        navigationSteps.where((step) => step != null).toList();
    String steps = nonNullNavigationSteps.join('\n') == ""
        ? 'Unavailable'
        : nonNullNavigationSteps.join('\n');
    String cleanedDuration =
        json['duration'].substring(0, json['duration'].length - 1);
    double durationValue = double.parse(cleanedDuration);

    WalkingRoute walkingroute = WalkingRoute(
        encodedEntirePolyline: json['polyline']['encodedPolyline'],
        distanceMeters: json['distanceMeters'],
        duration: durationValue,
        navigationsteps: steps);

    //walkingroute.setAllPolylines(trafficData);

    return walkingroute;
  }

  void setAllPoints() {
    this.allPoints = PolylinePoints()
        .decodePolyline(this.encodedEntirePolyline)
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  static List<String?> navigationStepsFromJson(Map<String, dynamic> json) {
    List<String?> navigationSteps = [];
    List<dynamic> steps = json['legs'][0]['steps'];
    for (var step in steps) {
      String? instruction = step['navigationInstruction']?['instructions'];
      navigationSteps.add(instruction);
    }

    return navigationSteps;
  }

  @override
  String toString() {
    List<String> lines = [];
    lines.add('Distance: ${distanceMeters}m');
    lines.add('Duration: ${duration ~/ 60}min');
    lines.add('Navigation steps:\n$navigationsteps');
    return lines.join('\n');
  }
}
