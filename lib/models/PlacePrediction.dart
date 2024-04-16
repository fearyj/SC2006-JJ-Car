class PlacePrediction
{
  String placeId; //get from json.suggestions[i].placePrediction.placeId
  String text; //get from json.suggestions[i].placePrediction.text.text

  PlacePrediction
  ({
    required this.placeId,
    required this.text
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) 
  {
    return PlacePrediction
    (
      placeId: json['placePrediction']['placeId'],
      text: json['placePrediction']['text']['text'],
    );
  }

  @override
  String toString()
  {
    return
    '''
PlaceID: $placeId
Text: $text
    ''';
  }

  @override
  bool operator ==(Object other) 
  {
    if (identical(this, other)) return true;

    return other is PlacePrediction && other.placeId == placeId && other.text == text;
  }

  @override
  int get hashCode => placeId.hashCode ^ text.hashCode;
}

PlacePrediction currentLocationPlacePrediction = PlacePrediction(placeId: 'current location',text: 'current location');