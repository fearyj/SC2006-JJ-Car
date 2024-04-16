import 'dart:convert' as convert;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:googlemaps/models/PlacePrediction.dart';

class PlaceAutocompleteAPI
{
  final String key = dotenv.env['API_KEY']!;

  Future<List<PlacePrediction>?> getPlacePrediction(String userinput) async
  {
    if (userinput == ""){return Future.value(null);}
    final String url = 'https://places.googleapis.com/v1/places:autocomplete';
    var response = await http.post
    (
      Uri.parse(url),
      body: convert.jsonEncode
      ({
        "input": userinput,
        "locationBias":
        {
          "rectangle":
          {
            "low": {"latitude": 1.0818, "longitude": 103.4492},
            "high": {"latitude": 1.6524, "longitude": 104.2430}
          }
        },
      }),
      headers: 
      {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": key,
      }
    );
    var json = convert.jsonDecode(response.body);
    print(json.toString());
    if ((json == null) || json['suggestions'] == null || json['suggestions'].isEmpty){return Future.value(null);}
    List<dynamic> suggestionsJson = json['suggestions'];
    List<PlacePrediction> placepredictions = suggestionsJson.map((suggestionJson) => PlacePrediction.fromJson(suggestionJson)).toList();
    for (int i = 0; i < placepredictions.length; i++)
    {
      print(placepredictions[i]);
    }
    return placepredictions;
  }
}