import 'package:googlemaps/models/HDBCarpark.dart';
import 'package:googlemaps/models/Place.dart';
import 'package:googlemaps/models/PlacePrediction.dart';
import 'package:googlemaps/services/GeolocatorAPI.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert' as convert;

class PlacesAPI 
{
  final String key = dotenv.env['API_KEY']!;
  
  Future<Place?> getPlace(String userinput) async 
  {
    if (userinput == ""){return Future.value(null);}
    final String url = 'https://places.googleapis.com/v1/places:searchText';
    var response = await http.post
    (
      Uri.parse(url),
      body: convert.jsonEncode
      ({
        "textQuery": userinput,
        "locationBias":
        {
          "rectangle":
          {
            "low": {"latitude": 1.0818, "longitude": 103.4492},
            "high": {"latitude": 1.6524, "longitude": 104.2430}
          }
        },
        "rankPreference": "RELEVANCE",
        "maxResultCount" : 2
      }),
      headers: 
      {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": key,
        "X-Goog-FieldMask": "places.id,places.displayName.text,places.formattedAddress,places.location,places.viewport,places.internationalPhoneNumber,places.rating,places.userRatingCount,places.websiteUri,places.priceLevel,places.currentOpeningHours.weekdayDescriptions,places.parkingOptions"
      }
    );
    var json = convert.jsonDecode(response.body);
    print(json.toString());
    if ((json == null) || json['places'] == null || json['places'].isEmpty){return Future.value(null);}
    Place place = Place.fromJson(json['places'][0]);
    print(place);
    return place;
  }

  Future<List<Place>?> get_nearest_carparks_google(Place? place) async 
  {
    if (place == null){return Future.value(null);}
    final String url = 'https://places.googleapis.com/v1/places:searchText';
    var response = await http.post
    (
      Uri.parse(url),
      body: convert.jsonEncode
      ({
        "textQuery": "carpark near " + place.displayName,
        "locationBias":
        {
          "circle": 
          {
            "center": 
            {
              "latitude": place.location.latitude,
              "longitude": place.location.longitude
            },
            "radius": 5000
          }
        },
        "includedType": "parking",
        "rankPreference": "DISTANCE",
        "maxResultCount": 2
      }),
      headers: 
      {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": key,
        "X-Goog-FieldMask": "places.id,places.displayName.text,places.formattedAddress,places.location,places.viewport,places.internationalPhoneNumber,places.rating,places.userRatingCount,places.websiteUri,places.priceLevel,places.currentOpeningHours.weekdayDescriptions,places.parkingOptions"
      }
    );
    var json = convert.jsonDecode(response.body);
    print(json.toString());
    if ((json == null) || json['places'] == null || json['places'].isEmpty){return Future.value(null);}
    List<dynamic> placesJson = json['places'];
    List<Place> nearest_carparks_google = placesJson.map((placeJson) => Place.fromJson(placeJson)).toList();
    for (int i = 0; i < nearest_carparks_google.length; i++)
    {
      print(nearest_carparks_google[i]);
    }
    return nearest_carparks_google;
  }

  Future<List<Place>?> reconcile(List<Place>? google_nearest_carparks, List<HDBCarpark>? hdb_nearest_carparks) async
  {
    if ((google_nearest_carparks == null) && (hdb_nearest_carparks == null))
    {
      return null;
    }
    else if ((google_nearest_carparks == null) && (hdb_nearest_carparks != null))
    {
      return hdb_nearest_carparks;
    }
    else if ((google_nearest_carparks != null) && (hdb_nearest_carparks == null))
    {
      return google_nearest_carparks;
    }

    List<int> removed = [];
    for (int i = 0; i < google_nearest_carparks!.length; i++)
    {
      for (int j = 0; j < hdb_nearest_carparks!.length; j++)
      {
        if ((google_nearest_carparks[i].displayName == hdb_nearest_carparks[j].carparknumber) || (((await GeolocatorAPI().calculateDistance(google_nearest_carparks[i].location, hdb_nearest_carparks[j].location))! < 30) && (google_nearest_carparks[i].displayName.toLowerCase().contains('hdb') || google_nearest_carparks[i].displayName.toLowerCase().contains('block') || google_nearest_carparks[i].displayName.toLowerCase().contains('blk'))))
        {
          hdb_nearest_carparks[j].id = google_nearest_carparks[i].id;
          hdb_nearest_carparks[j].viewport = google_nearest_carparks[i].viewport;
          hdb_nearest_carparks[j].internationalPhoneNumber = google_nearest_carparks[i].internationalPhoneNumber;
          hdb_nearest_carparks[j].rating = google_nearest_carparks[i].rating;
          hdb_nearest_carparks[j].userRatingCount = google_nearest_carparks[i].userRatingCount;
          hdb_nearest_carparks[j].priceLevel = google_nearest_carparks[i].priceLevel;
          hdb_nearest_carparks[j].parkingOptions = google_nearest_carparks[i].parkingOptions;
          removed.add(i);
        }
      }
    }

    removed.sort(); 
    removed = removed.reversed.toList(); 
    for (int index in removed)
    {
      google_nearest_carparks.removeAt(index);
    }
    google_nearest_carparks.addAll(hdb_nearest_carparks!);
    return google_nearest_carparks;
  }

  Future<Place?> getplace(PlacePrediction? placePrediction) async 
  {
    if (placePrediction == null)
    {
      return Future.value(null);
    }
    String id = placePrediction.placeId;
    final String url = 'https://places.googleapis.com/v1/places/$id';
    var response = await http.get
    (
      Uri.parse(url),
      headers: 
      {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": key,
        "X-Goog-FieldMask": "id,displayName.text,formattedAddress,location,viewport,internationalPhoneNumber,rating,userRatingCount,websiteUri,priceLevel,currentOpeningHours.weekdayDescriptions,parkingOptions"
      }
    );
    var json = convert.jsonDecode(response.body);
    print(json.toString());
    if (json == null){return Future.value(null);}
    Place place = Place.fromJson(json);
    print(place);
    return place;
  }
}