import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:googlemaps/models/HDBCarpark.dart";
import 'package:googlemaps/models/Place.dart';
import 'package:googlemaps/services/GeolocatorAPI.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert; 

//HDB API website: https://beta.data.gov.sg/datasets/d_ca933a644e55d34fe21f28b8052fac63/view
//HDB CSV website: https://beta.data.gov.sg/datasets/d_23f946fa557947f93a8043bbef41dd09/view
//lot types: C, Y or H, may appear in any order

class HDBCarparkAPI
{
  List<List<dynamic>> HDBcarparksCSV = []; 
  HDBCarparkAPI(){loadCSV();}
  Future<void> loadCSV() async 
  {
    String csvString = await rootBundle.loadString('assets/HDBCarparkInformation.csv');
    CsvToListConverter converter = CsvToListConverter();
    HDBcarparksCSV = converter.convert(csvString);
    print("successfully loaded csv");
    print(HDBcarparksCSV[0]);
    print(HDBcarparksCSV[1]);
  }
  
  Future<List<dynamic>?> fetchCarparkAvailability() async
  {
    final String url = 'https://api.data.gov.sg/v1/transport/carpark-availability';
    var response = await http.get
    (
      Uri.parse(url),
      headers: 
      {
        "accept": "application/json"
      }
    );

    var json = convert.jsonDecode(response.body);
    print(json.toString()); 
    if ((json == null) || (json['items'] == null) || (json['items'].isEmpty) || (json['items'][0] == null) || (json['items'][0]['carpark_data'] == null))
    {
      return Future.value(null);
    }
    
    List<dynamic> carparksJson = json['items'][0]['carpark_data']; 
    return carparksJson;
  }

  Future<Map<String, double>?> get_sorted_distance_map(Place? destination) async 
  {
    if(destination == null) {return Future.value(null);}
    Map<String, double> distanceMap = {};
    for (int i = 1; i < HDBcarparksCSV.length; i++) 
    {
      List<dynamic> row = HDBcarparksCSV[i];
      String carparkNo = row[0];
      double lat = row[2];
      double lng = row[3];
      LatLng carparkLocation = LatLng(lat, lng);
      double? distance = await GeolocatorAPI().calculateDistance(destination.location, carparkLocation);
      if (distance == null) {continue;}
      distanceMap[carparkNo] = distance;
    }

    var entrieslist = distanceMap.entries.toList();
    entrieslist.sort((a, b) => a.value.compareTo(b.value));
    distanceMap = Map.fromEntries(entrieslist);
    print(distanceMap);
    return distanceMap;
  }

  Future<List<HDBCarpark>?> findNearestAvailableCarparks(Place? destination) async 
  {
    if ((destination == null) || (destination.location.latitude < 1.1) || (destination.location.longitude < 103.6) || (destination.location.latitude > 1.5) || (destination.location.longitude > 104.5)) 
    {
      return Future.value(null);
    }
    List<dynamic>? availabilityData = await fetchCarparkAvailability();
    if ((availabilityData == null) || (availabilityData.isEmpty)) {return Future.value(null);}
    Map<String, double>? sorted_distance_map = await get_sorted_distance_map(destination);

    Map<String,List<dynamic>> nearestAvailableCarparkNotoAvailability= {};
    for (String carparkNo in sorted_distance_map!.keys) 
    {
      for (int i = 0; i < availabilityData.length; i++)
      {
        if (carparkNo == availabilityData[i]['carpark_number'])
        {
          var carparkavailabilitydata = availabilityData[i]['carpark_info'];
          if (carparkavailabilitydata != null)
          {
            for (int j = 0; j < carparkavailabilitydata.length; i++)
            {
              if (carparkavailabilitydata[j]['lot_type'] == 'C')
              {
                if (int.parse(carparkavailabilitydata[j]['lots_available']) > 0)
                {
                  nearestAvailableCarparkNotoAvailability[carparkNo] = carparkavailabilitydata;
                }
                break;
              }
            }
          }
          break;
        }
      }
      if (nearestAvailableCarparkNotoAvailability.length >= 2) {break;}
    }
    if (nearestAvailableCarparkNotoAvailability.length == 0) {return Future.value(null);}

    List<HDBCarpark> nearestAvailableCarparks = [];
    for (String carparkNo in nearestAvailableCarparkNotoAvailability.keys)
    {
      var carparkInfo = HDBcarparksCSV.firstWhere((row) => row[0] == carparkNo,orElse: () => ['Unknown Address',0,0]);

      if (carparkInfo != ['Unknown Address',0,0]) 
      {
        String formattedAddress = carparkInfo[1];
        double lat = carparkInfo[2];
        double lng = carparkInfo[3];
        LatLng location = LatLng(lat, lng);
        var otherinfoColumns = carparkInfo.sublist(4); 
        String otherinfo = '';
        for (int i = 0; i < otherinfoColumns.length; i++) 
        {
          String columnName = HDBcarparksCSV[0][i + 4]; 
          dynamic value = otherinfoColumns[i];
          otherinfo += '$columnName: $value\n';
        }
        HDBCarpark hdbcarpark = HDBCarpark
        (
          carparknumber: carparkNo,
          availability: nearestAvailableCarparkNotoAvailability[carparkNo]!,
          formattedAddress: formattedAddress,
          location: location,
          otherinfo: otherinfo
        );
        nearestAvailableCarparks.add(hdbcarpark);
      }
    }
    for(HDBCarpark hdbcarpark in nearestAvailableCarparks)
    {
      print(hdbcarpark);
    }
    return nearestAvailableCarparks;
  }
}

//below is the structure of json response from HDB API
/*
{
  "items": 
  [
    {
      "timestamp": "2024-04-02T07:54:55.316Z",
      "carpark_data": 
      [
        {
          "carpark_info": 
          [
            {
              "total_lots": "string",
              "lot_type": "string",
              "lots_available": "string"
            }
          ],
          "carpark_number": "string"
        }
      ]
    }
  ]
}
*/

