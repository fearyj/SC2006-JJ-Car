import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Determine the current position of the device.
///
/// When the location services are not enabled or permissions
/// are denied the `Future` will return an error.

class GeolocatorAPI
{
  bool serviceEnabled = false;
  LocationPermission permission = LocationPermission.denied;

  Future<bool> request_location_access_permission() async
  {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) 
    {
      permission = await Geolocator.requestPermission();
    }

    return true;
  }

  Future<Position?> getcurrentlocation() async 
  {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print("Is locations service enabled?: $serviceEnabled");
    if (!serviceEnabled) 
    {
      return Future.value(null);
    }

    permission = await Geolocator.checkPermission();
    print("Permission: $permission");
    if ((permission == LocationPermission.denied) || (permission == LocationPermission.deniedForever)) 
    {
      return Future.value(null);
    } 

    Position currentlocation = await Geolocator.getCurrentPosition();
    return currentlocation; 
  }

  Future<double?> calculateDistance(LatLng? location1, LatLng? location2) async 
  {
    if ((location1 == null) || (location2 == null)){return null;}
    double distance = await Geolocator.distanceBetween
    (
      location1.latitude, 
      location1.longitude,
      location2.latitude, 
      location2.longitude,
    );
    return distance;
  }
}
