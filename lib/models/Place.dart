import 'package:google_maps_flutter/google_maps_flutter.dart';
// import CarparkAPI.dart 

class Place //jsonplacesearchresult.places[0]
{
  String id;
  String displayName; 
  String formattedAddress;
  LatLng location;
  Viewport? viewport = null;
  String? internationalPhoneNumber = null;
  double? rating = null;
  int? userRatingCount = null;
  String? websiteUri = null;
  String? priceLevel = null; 
  String? currentOpeningHours = null; 
  ParkingOptions? parkingOptions = null;

  Place
  ({
    required this.id,
    required this.displayName,
    required this.formattedAddress,
    required this.location,
    this.viewport,
    this.internationalPhoneNumber,
    this.rating,
    this.userRatingCount,
    this.websiteUri,
    this.priceLevel,
    this.currentOpeningHours,
    this.parkingOptions,
  });

  //here json is a Place document
  factory Place.fromJson(Map<String, dynamic> json) 
  {
    return Place
    (
      id: json['id'],
      displayName: json['displayName']['text'],
      formattedAddress: json['formattedAddress'],
      location: LatLng(json['location']['latitude'],json['location']['longitude']),
      viewport: Viewport.fromJson(json['viewport']),
      internationalPhoneNumber: json['internationalPhoneNumber'],
      rating: json['rating']?.toDouble(),
      userRatingCount: json['userRatingCount'],
      websiteUri: json['websiteUri'],
      priceLevel: mapPriceLevel(json['priceLevel']),
      currentOpeningHours: json['currentOpeningHours']?['weekdayDescriptions']?.join('\n'),
      parkingOptions: json['parkingOptions'] != null ? ParkingOptions.fromJson(json['parkingOptions']) : null,
    );
  }

  static String? mapPriceLevel(String? priceLevel) 
  {
    switch (priceLevel) 
    {
      case "PRICE_LEVEL_UNSPECIFIED":
        return "unspecified";
      case "PRICE_LEVEL_FREE":
        return "free";
      case "PRICE_LEVEL_INEXPENSIVE":
        return "inexpensive";
      case "PRICE_LEVEL_MODERATE":
        return "moderate";
      case "PRICE_LEVEL_EXPENSIVE":
        return "expensive";
      case "PRICE_LEVEL_VERY_EXPENSIVE":
        return "very_expensive";
      default:
        return null;
    }
  }

@override
String toString() 
{
  List<String> lines = [];

  lines.add('Name: $displayName');
  lines.add('Address: $formattedAddress');
  if (internationalPhoneNumber != null) {lines.add('Phone Number: $internationalPhoneNumber');}
  if (rating != null && userRatingCount != null) {lines.add('Rating: $rating ($userRatingCount)');}
  if (websiteUri != null) {lines.add('Website: $websiteUri');}
  if (priceLevel != null) {lines.add('Price Level: $priceLevel');}
  if (currentOpeningHours != null) {lines.add('Current Opening Hours:\n$currentOpeningHours');}
  if (parkingOptions != null) 
  {
    String parkingOptionsString = parkingOptions!.getTrueParkingOptions().join(', ');
    lines.add('Parking Options: $parkingOptionsString');
  }

  return lines.join('\n');
}


  @override
  bool operator ==(Object other) 
  {
    if (identical(this, other)) return true;

    return other is Place && this.id == other.id && this.displayName == other.displayName && this.formattedAddress == other.formattedAddress && this.location == other.location;
  }

  @override
  int get hashCode => id.hashCode ^ displayName.hashCode ^ formattedAddress.hashCode ^ location.hashCode;
}

class Viewport
{
  LatLng low;
  LatLng high;

  Viewport({required this.low, required this.high,});

  //here json is place['viewport']
  factory Viewport.fromJson(Map<String, dynamic> json) 
  {
    return Viewport
    (
      low: LatLng(json['low']['latitude'],json['low']['longitude']),
      high: LatLng(json['high']['latitude'],json['high']['longitude']),
    );
  }
}

class ParkingOptions {
  bool? freeParkingLot;
  bool? paidParkingLot;
  bool? freeStreetParking;
  bool? paidStreetParking;
  bool? valetParking;
  bool? freeGarageParking;
  bool? paidGarageParking;

  ParkingOptions
  ({
    this.freeParkingLot,
    this.paidParkingLot,
    this.freeStreetParking,
    this.paidStreetParking,
    this.valetParking,
    this.freeGarageParking,
    this.paidGarageParking,
  });

  //here json is place['parkingOptions']
  factory ParkingOptions.fromJson(Map<String, dynamic> json) 
  {
    return ParkingOptions
    (
      freeParkingLot: json['freeParkingLot'],
      paidParkingLot: json['paidParkingLot'],
      freeStreetParking: json['freeStreetParking'],
      paidStreetParking: json['paidStreetParking'],
      valetParking: json['valetParking'],
      freeGarageParking: json['freeGarageParking'],
      paidGarageParking: json['paidGarageParking'],
    );
  }

  List<String> getTrueParkingOptions() 
  {
    List<String> trueOptions = [];
    if (freeParkingLot ?? false) trueOptions.add('Free Parking Lot');
    if (paidParkingLot ?? false) trueOptions.add('Paid Parking Lot');
    if (freeStreetParking ?? false) trueOptions.add('Free Street Parking');
    if (paidStreetParking ?? false) trueOptions.add('Paid Street Parking');
    if (valetParking ?? false) trueOptions.add('Valet Parking');
    if (freeGarageParking ?? false) trueOptions.add('Free Garage Parking');
    if (paidGarageParking ?? false) trueOptions.add('Paid Garage Parking');
    return trueOptions;
  }
}