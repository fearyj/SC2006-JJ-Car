import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemaps/models/Place.dart';
import 'package:googlemaps/models/Route.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert' as convert;

class RoutesAPI
{
  final String key = dotenv.env['API_KEY']!;

  Future<Route?> getRoutebasic(LatLng? origin, LatLng? destination) async 
  {
    if ((origin == null) || (destination == null) || (origin == destination)){return Future.value(null);}
    final String url = 'https://routes.googleapis.com/directions/v2:computeRoutes';
    var response = await http.post
    (
      Uri.parse(url),
      body: convert.jsonEncode
      (
        {
          "origin": 
          {
            "location": 
            {
              "latLng": 
              {
                "latitude": origin.latitude,
                "longitude": origin.longitude
              }
            },
          },
          "destination": 
          {
            "location": 
            {
              "latLng": 
              {
                "latitude": destination.latitude,
                "longitude": destination.longitude
              }
            },
          },
          "travelMode": "DRIVE",
          "routingPreference": "TRAFFIC_AWARE", 
          "polylineQuality": "HIGH_QUALITY",
          //"departureTime": "",
          "computeAlternativeRoutes": false,
          "routeModifiers": 
          {
            "avoidTolls": false,
            "avoidHighways": false,
            "avoidFerries": false,
          },
          "units": "METRIC",
          //"requestedReferenceRoutes": ["FUEL_EFFICIENT"],
          "extraComputations": ["TOLLS", "FUEL_CONSUMPTION", "TRAFFIC_ON_POLYLINE"]
        }
      ),
      headers: 
      {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": key,
        "X-Goog-FieldMask": "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.travelAdvisory.speedReadingIntervals,routes.legs.steps.navigationInstruction.instructions,routes.travelAdvisory.fuelConsumptionMicroliters,routes.travelAdvisory.tollInfo.estimatedPrice.units,routes.travelAdvisory.tollInfo.estimatedPrice.currencyCode"
      }
    );
    var json = convert.jsonDecode(response.body);
    print(json.toString());
    if ((json == null) || (json['routes'] == null) || (json['routes'].isEmpty) || (json['routes'][0] == null) || (json['routes'][0]['distanceMeters'] == null))
    {
      return Future.value(null);
    }
    List<dynamic> routesJson = json['routes'];
    Route route = Route.fromJson(routesJson[0]);
    print(route);
    return route;
  }

  Future<List<Route?>?> getRoute(LatLng? origin, LatLng? destination, List<Place>? nearestcarparks) async
  {
    if ((origin == null) || (destination == null)){return Future.value(null);}
    List<Route?> routeresults = [];

    Route? originalroute = await getRoutebasic(origin, destination);
    routeresults.add(originalroute);
    for (int i = 0; i < (nearestcarparks ?? []).length; i++)
    {
      Route? route = await getRoutebasic(origin, nearestcarparks![i].location);
      routeresults.add(route);
    }
    return routeresults;
  }
}


