import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/material.dart';

class Route
{
  Set<Polyline> allpolylines;
  String encodedentirepolyline; 
  List<LatLng> allpoints;
  int distanceMeters;
  double duration;
  double fuelConsumptionMicroliters;
  double fuelConsumptionCost; 
  String? tollfee = null;
  String navigationsteps; 
  
  Route
  ({
  required this.encodedentirepolyline,
  required this.distanceMeters,
  required this.duration,
  required this.navigationsteps,
  this.tollfee,
  }) : 
  allpolylines = {}, 
  allpoints = [], 
  fuelConsumptionMicroliters = (10000/149)*distanceMeters,
  fuelConsumptionCost = (10000 / 149) * distanceMeters / 1000000 * 2.68 
  {
    setallpoints();

    // Create a single polyline with allpoints
    Polyline polyline = Polyline
    (
      polylineId: PolylineId(this.encodedentirepolyline),
      color: Colors.green, 
      points: this.allpoints,
      width: 5,
    );
    this.allpolylines.add(polyline);
  }

  //here json is jsonroutesearchresult['routes'][i] for some i (basically a Route document)
  //before running this function, check that jsonroutesearchresult.routes[i].polyline.encodedPolyline != null
  factory Route.fromJson(Map<String, dynamic> json)
  {
    List<dynamic>? trafficData = json['travelAdvisory']?['speedReadingIntervals'];
    List<String?> navigationsteps = Route.navigationStepsFromJson(json);
    List<String?> nonNullNavigationSteps = navigationsteps.where((step) => step != null).toList();
    String steps = nonNullNavigationSteps.join('\n') == "" ? 'Unavailable' : nonNullNavigationSteps.join('\n');
    String cleanedDuration = json['duration'].substring(0, json['duration'].length - 1);
    double durationValue = double.parse(cleanedDuration);

    Route route = Route
    (
      encodedentirepolyline: json['polyline']['encodedPolyline'],
      distanceMeters: json['distanceMeters'],
      duration: durationValue,
      tollfee: (json['travelAdvisory']?['tollInfo']?['estimatedPrice']?[0]['units'] != null && json['travelAdvisory']?['tollInfo']?['estimatedPrice']?[0]['currencyCode'] != null) ? (json['travelAdvisory']['tollInfo']['estimatedPrice'][0]['units'] + json['travelAdvisory']['tollInfo']['estimatedPrice'][0]['currencyCode']) : null,
      navigationsteps: steps
    );

    route.setallpolylines(trafficData);
    route.fuelConsumptionMicroliters = json['travelAdvisory']?['fuelConsumptionMicroliters'] != null ? double.parse(json['travelAdvisory']['fuelConsumptionMicroliters']) : route.fuelConsumptionMicroliters;

    return route;
  }

  void setallpoints() 
  {
    this.allpoints = PolylinePoints().decodePolyline(this.encodedentirepolyline).map((point) => LatLng(point.latitude, point.longitude)).toList();
  }

  void setallpolylines(List<dynamic>? trafficData) 
  {
    if (trafficData == null) {return;}
    Set<Polyline> polylines = {};

    for (var data in trafficData) 
    {
      Color color = Colors.green; // Default color
      switch (data['speed']) 
      {
        case "NORMAL":
          color = Color.fromARGB(255, 0, 255, 255);
          break;
        case "SLOW":
          color = Color.fromARGB(255, 0, 123, 255);
          break;
        case "TRAFFIC_JAM":
          color = Color.fromARGB(255, 4, 0, 255);
          break;
        default: color = Colors.cyan;
      }

      Polyline polyline = Polyline
      (
        polylineId: PolylineId(data.toString()),
        color: color,
        points: this.allpoints.sublist(data['startPolylinePointIndex'] ?? 0, data['endPolylinePointIndex'] + 1),
        width: 8,
      );
      polylines.add(polyline);
    }

    this.allpolylines = polylines;
  }

  //here json is jsonroutesearchresult['routes'][i] for some i (basically a Route document)
  static List<String?> navigationStepsFromJson(Map<String, dynamic> json) 
  {
    List<String?> navigationSteps = [];
    List<dynamic> steps = json['legs'][0]['steps'];
    for (var step in steps) 
    {
      String? instruction = step['navigationInstruction']?['instructions'];
      navigationSteps.add(instruction);
    }
    
    return navigationSteps;
  }

  @override
  String toString() 
  {
    List<String> lines = [];
    lines.add('Distance: ${distanceMeters ~/ 1000}km');
    lines.add('Duration: ${duration ~/ 60}min');
    lines.add('Fuel Consumption: ${fuelConsumptionMicroliters ~/ 1000}ml');
    lines.add('Fuel Cost: \$${fuelConsumptionCost.toStringAsFixed(2)}');
    if (tollfee != null) {lines.add('Toll fee: $tollfee');}
    lines.add('Navigation steps:\n$navigationsteps');
    return lines.join('\n');
  }
}


