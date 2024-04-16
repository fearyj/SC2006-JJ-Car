import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemaps/models/Place.dart';
import 'package:googlemaps/models/WalkingRoute.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert' as convert;

class WalkingRoutesAPI
{
  final String key = dotenv.env['API_KEY']!;

  Future<WalkingRoute?> getWalkingRoutebasic(LatLng? origin, LatLng? destination) async 
  {
    if ((origin == null) || (destination == null) || (origin == destination)){return Future.value(null);}
    final String url = 'https://routes.googleapis.com/directions/v2:computeRoutes';
    var response = await http.post
    (
      Uri.parse(url),
      body: convert.jsonEncode(
      {
      "origin": {
        "location": {
          "latLng": {
            "latitude": origin.latitude,
            "longitude": origin.longitude
          }
        },
      },
      "destination": {
        "location": {
          "latLng": {
            "latitude": destination.latitude,
            "longitude": destination.longitude
          }
        },
      },
      "travelMode": "WALK",  // Changed from "DRIVE" to "WALK"
      "polylineQuality": "HIGH_QUALITY",
      //"departureTime": "",  // Relevant if considering time-specific data like rush hour
      "computeAlternativeRoutes": false,
      
      "units": "METRIC",
      //"requestedReferenceRoutes": ["FUEL_EFFICIENT"],  // Not applicable for walking
      "extraComputations": ["TRAFFIC_ON_POLYLINE"]
    }
  ),
  headers: {
    "Content-Type": "application/json",
    "X-Goog-Api-Key": key,
    "X-Goog-FieldMask": "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.steps.navigationInstruction.instructions"
    // Removed fields related to tolls and fuel consumption as they are irrelevant to walking
  }
);
    var json = convert.jsonDecode(response.body);
    print(json.toString());
    if ((json == null) || (json['routes'] == null) || (json['routes'].isEmpty) || (json['routes'][0] == null) || (json['routes'][0]['distanceMeters'] == null))
    {
      return Future.value(null);
    }
    List<dynamic> routesJson = json['routes'];
    WalkingRoute route = WalkingRoute.fromJson(routesJson[0]);
    print(route);
    return route;
  }

  Future<List<WalkingRoute?>?> getWalkingRoute(LatLng? origin, LatLng? destination, List<Place>? nearestcarparks) async
 {
    if ((origin == null) || (destination == null)){return Future.value(null);}
    List<WalkingRoute?> routeresults = [];

    routeresults.add(null);
    for (int i = 0; i < (nearestcarparks ?? []).length; i++)
    {
      WalkingRoute? route = await getWalkingRoutebasic(nearestcarparks![i].location, destination);
      routeresults.add(route);
    }
    return routeresults;
  }
}

