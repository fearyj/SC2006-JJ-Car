import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemaps/models/Place.dart';

class HDBCarpark extends Place
{

  String carparknumber; //put carpark number here
  List<dynamic> availability; //this is the original carpark_info field from carparkAPI response, just assign it as it is in the original document without modifying anything
  String? otherinfo = null; //put all other columns from csv (car_park_type onwards) in here in order from left to right, separate every column's value by a newline

  HDBCarpark
  ({
    required this.carparknumber, 
    required this.availability,
    required String formattedAddress, //put the address column of csv here
    required LatLng location, //put latlng from csv here
    this.otherinfo
  }) : super
  (
    id: carparknumber,
    displayName: "HDB Carpark",
    formattedAddress: formattedAddress,
    location: location,
    currentOpeningHours: "Open 24 hours",
    websiteUri: "http://www.hdb.gov.sg/"
  );

  String availabilityToString() 
  {
    String result = '';

    for (var entry in availability) 
    {
      String? lotType = entry['lot_type'];
      String? lotsAvailable = entry['lots_available'];
      String? totalLots = entry['total_lots'];

      if (lotType != null && lotsAvailable != null && totalLots != null) 
      {
        String lotTypeString;
        switch (lotType) 
        {
          case 'C':
            lotTypeString = 'car';
            break;
          case 'H':
            lotTypeString = 'heavy';
            break;
          case 'Y':
            lotTypeString = 'motorcycle';
            break;
          default:
            lotTypeString = lotType;
        }
        result += '\n$lotTypeString: $lotsAvailable/$totalLots';
      }
    }

    return result;
  }

  @override
  String toString()
  {
    List<String> lines = super.toString().split('\n');
    lines.add('Carpark No.: $carparknumber');
    lines.add('Availability:' + availabilityToString());
    if (otherinfo != null) {lines.add('Other Info:\n$otherinfo');}
    return lines.join('\n');
  }
}