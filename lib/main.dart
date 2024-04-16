import 'package:flutter/material.dart' hide Route;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemaps/models/HDBCarpark.dart';
import 'package:googlemaps/models/Place.dart';
import 'package:googlemaps/models/PlacePrediction.dart';
import 'package:googlemaps/services/GeolocatorAPI.dart';
import 'package:googlemaps/services/HDBCarparkAPI.dart';
import 'package:googlemaps/services/PlaceAutocompleteAPI.dart';
import 'package:googlemaps/services/PlacesAPI.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:googlemaps/services/RoutesAPI.dart';
import 'package:googlemaps/models/Route.dart';
import 'package:geolocator/geolocator.dart';
import 'package:googlemaps/models/WalkingRoute.dart';
import 'package:googlemaps/services/WalkingRoutesAPI.dart';

void main() async {
  await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JJ Car',
      home: Scaffold(body: MapSample()),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  TextEditingController _originsearchcontroller = TextEditingController();
  TextEditingController _destinationsearchcontroller = TextEditingController();
  CustomInfoWindowController _customoriginInfoWindowController =
      CustomInfoWindowController();
  CustomInfoWindowController _customdestinationInfoWindowController =
      CustomInfoWindowController();
  List<CustomInfoWindowController>
      _customnearestcarparksInfoWindowControllerlist =
      List.generate(4, (index) => CustomInfoWindowController());

  static const CameraPosition singapore =
      CameraPosition(target: LatLng(1.3521, 103.8198), zoom: 14.4746);

  @override
  void dispose() {
    _customoriginInfoWindowController.dispose();
    _customdestinationInfoWindowController.dispose();
    for (int i = 0;
        i < _customnearestcarparksInfoWindowControllerlist.length;
        i++) {
      _customnearestcarparksInfoWindowControllerlist[i].dispose();
    }
    super.dispose();
  }

  Place? origin = null;
  Place? destination = null;
  Place? carpark = null;
  List<Place>? nearestcarparks = null;
  List<HDBCarpark>? nearestcarparkshdb = null;
  List<Route?>? routeresults = null;
  List<WalkingRoute?>? walkingrouteresults = null;
  Set<Polyline> allroutespolylines = Set<Polyline>();
  Set<Polyline> allwalkingroutespolylines = Set<Polyline>();
  Set<Polyline> polylineset = Set<Polyline>();
  Set<Polyline> walkingpolylineset = Set<Polyline>();
  Set<Marker> originmarkerset = Set<Marker>();
  Set<Marker> destinationmarkerset = Set<Marker>();
  Set<Marker> nearestcarparksmarkerset = Set<Marker>();
  Set<Marker> markerset = Set<Marker>();
  int? tappedIndex = null;
  List<PlacePrediction>? originplacepredictions = null;
  List<PlacePrediction>? destinationplacepredictions = null;
  HDBCarparkAPI hdbcarparkapi = HDBCarparkAPI();
  Set<Polyline> combinedPolylines = Set<Polyline>();
  Set<Polyline> allcombinedroutespolylines = Set<Polyline>();

  Timer? locationTimer = null;
  Position? currentlocation = null;
  Place? currentplace = null;
  GeolocatorAPI geolocatorAPI = GeolocatorAPI();
  bool permission_request_answered = false;
  
  void getCurrentLocation() async {
    Position? location = await geolocatorAPI.getcurrentlocation();
    print("Location: $location");
    setState(() {
      currentlocation = location;
      print("Current Location: $currentlocation");
      currentplace = currentlocation == null
          ? null
          : Place(
              id: "current location",
              displayName: "current location",
              formattedAddress: "current location",
              location: LatLng(
                  currentlocation!.latitude, currentlocation!.longitude));
    });
  }

  @override
  void initState() {
    super.initState();
    geolocatorAPI.request_location_access_permission().then((_) 
    {
      setState(() 
      {
        permission_request_answered = true;
      });
    });
    locationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      getCurrentLocation();
    });
  }

  void setPolyline() {
    setState(() {
      if (tappedIndex == null) {
        polylineset = allroutespolylines;
        walkingpolylineset = allwalkingroutespolylines;
      } else {
        if (routeresults == null) {
          polylineset = Set<Polyline>();
        } else {
          polylineset = routeresults![tappedIndex!]?.allpolylines ?? Set<Polyline>();
        }

        if (walkingrouteresults == null) {
          walkingpolylineset = Set<Polyline>();
        } else {
          walkingpolylineset = walkingrouteresults![tappedIndex!]?.allpolylines ?? Set<Polyline>();
        }
      }
      combinedPolylines = Set.from(polylineset);
      combinedPolylines.addAll(walkingpolylineset);
    });
  }

  void setallroutespolylines() 
  {
    allroutespolylines.clear();
    allwalkingroutespolylines.clear();
    allcombinedroutespolylines.clear();

    if (routeresults != null) {
      for (int i = 0; i < routeresults!.length; i++) {
        allroutespolylines =
            allroutespolylines.union(routeresults![i]?.allpolylines ?? Set<Polyline>());
      }
    }
    if (walkingrouteresults != null) {
      for (int i = 0; i < walkingrouteresults!.length; i++) {
        allwalkingroutespolylines = allwalkingroutespolylines
            .union(walkingrouteresults![i]?.allpolylines ?? Set<Polyline>());
      }
    }
    allcombinedroutespolylines = Set.from(allroutespolylines);
    allcombinedroutespolylines.addAll(allwalkingroutespolylines);
  }

  void setMarker(Place? place, String type) {
    setState(() {
      if (place == null) {
        if (type == 'destination') {
          destinationmarkerset.clear();
          nearestcarparksmarkerset.clear();
        } else {
          originmarkerset.clear();
        }
      } else {
        if (type == 'destination') {
          destinationmarkerset.clear();
          nearestcarparksmarkerset.clear();
          destinationmarkerset.add(Marker(
              markerId: MarkerId(type),
              position: place.location,
              icon: BitmapDescriptor.defaultMarker,
              onTap: () {
                _customdestinationInfoWindowController.addInfoWindow!(
                    SingleChildScrollView(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            place.toString(),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    place.location);
              }));
          for (int i = 0; i < (nearestcarparks ?? []).length; i++) {
            nearestcarparksmarkerset.add(Marker(
                markerId: MarkerId("$i"),
                position: nearestcarparks![i].location,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueYellow),
                onTap: () {
                  _customnearestcarparksInfoWindowControllerlist[i]
                          .addInfoWindow!(
                      SingleChildScrollView(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              nearestcarparks![i].toString(),
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      nearestcarparks![i].location);
                }));
          }
        } else {
          originmarkerset.clear();
          originmarkerset.add(Marker(
              markerId: MarkerId(type),
              position: place.location,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
              onTap: () {
                _customoriginInfoWindowController.addInfoWindow!(
                    SingleChildScrollView(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            place.toString(),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    place.location);
              }));
        }
      }
      markerset = originmarkerset
          .union(destinationmarkerset)
          .union(nearestcarparksmarkerset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(10),
        child: Container(
          width: MediaQuery.of(context).size.width,
          color: Colors.blue,
          padding: EdgeInsets.only(
              left: 16), // Add left padding to shift the text to the left
          alignment: Alignment.centerLeft, // Align text to the left
          child: Text(
            'JJ Car',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
      body: !permission_request_answered ? Center(child: CircularProgressIndicator()) : Stack(children: [
        GoogleMap(
          mapType: MapType.normal,
          zoomGesturesEnabled: true,
          zoomControlsEnabled: false,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          buildingsEnabled: true,
          trafficEnabled: true,
          indoorViewEnabled: true,
          initialCameraPosition: singapore,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            _customoriginInfoWindowController.googleMapController = controller;
            _customdestinationInfoWindowController.googleMapController =
                controller;
            for (int i = 0;
                i < _customnearestcarparksInfoWindowControllerlist.length;
                i++) {
              _customnearestcarparksInfoWindowControllerlist[i]
                  .googleMapController = controller;
            }
          },
          markers: markerset,
          polylines: combinedPolylines,
          onTap: (position) {
            _customoriginInfoWindowController.hideInfoWindow!();
            _customdestinationInfoWindowController.hideInfoWindow!();
            for (int i = 0;
                i < _customnearestcarparksInfoWindowControllerlist.length;
                i++) {
              _customnearestcarparksInfoWindowControllerlist[i]
                  .hideInfoWindow!();
            }
            setState(() {
              tappedIndex = null; // Deselect all routes
              setPolyline();
              originplacepredictions = null;
              destinationplacepredictions = null;
            });
          },
          onCameraMove: (position) {
            _customoriginInfoWindowController.onCameraMove!();
            _customdestinationInfoWindowController.onCameraMove!();
            for (int i = 0;
                i < _customnearestcarparksInfoWindowControllerlist.length;
                i++) {
              _customnearestcarparksInfoWindowControllerlist[i].onCameraMove!();
            }
          },
        ),
        CustomInfoWindow(
          controller: _customoriginInfoWindowController,
          height: 100,
          width: 200,
          offset: 50,
        ),
        CustomInfoWindow(
          controller: _customdestinationInfoWindowController,
          height: 100,
          width: 200,
          offset: 50,
        ),
        ..._customnearestcarparksInfoWindowControllerlist.map((controller) {
          return CustomInfoWindow(
            controller: controller,
            height: 100,
            width: 200,
            offset: 50,
          );
        }).toList(),
        Column(
          children: [
            Row(children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Padding(
                                padding: const EdgeInsets.all(
                                    8.0), // Add padding to TextFormField
                                child: TextFormField(
                                    decoration: InputDecoration(
                                      contentPadding:
                                          EdgeInsets.fromLTRB(12, 10, 12, 10),
                                      hintText: 'Enter Origin',
                                      border:
                                          OutlineInputBorder(), // Add border to TextFormField
                                      filled: true, // fill background colour
                                      fillColor: Colors.white.withOpacity(0.8),
                                    ),
                                    controller: _originsearchcontroller,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    onTap: () {
                                      setState(() {
                                        destinationplacepredictions = null;
                                      });
                                    },
                                    onChanged: (value) async {
                                      print(value);
                                      List<PlacePrediction>? placepredictions =
                                          await PlaceAutocompleteAPI()
                                              .getPlacePrediction(
                                                  _originsearchcontroller.text);
                                      if (currentlocation != null) {
                                        (placepredictions ?? []).insert(
                                            0, currentLocationPlacePrediction);
                                      }
                                      setState(() {
                                        originplacepredictions =
                                            placepredictions;
                                      });
                                    }))),
                        IconButton(
                          onPressed: () async {
                            if (_originsearchcontroller.text ==
                                "current location") {
                              origin = currentplace;
                            } else if (_originsearchcontroller.text !=
                                origin?.displayName) {
                              origin = await PlacesAPI()
                                  .getPlace(_originsearchcontroller.text);
                            }

                            setState(() {
                              goToPlace(origin, "origin");
                              routeresults = null;
                              walkingrouteresults = null;
                              tappedIndex = null;
                              originplacepredictions = null;
                              destinationplacepredictions = null;
                              setallroutespolylines();
                              setPolyline();
                            });
                          },
                          icon: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white
                                  .withOpacity(0.8), // Adjust opacity here
                            ),
                            child: Icon(Icons.check),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Padding(
                                padding: const EdgeInsets.all(
                                    8.0), // Add padding to TextFormField
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(12, 10, 12, 10),
                                    hintText:
                                        'Enter Destination (and find nearby carparks)',
                                    border:
                                        OutlineInputBorder(), // Add border to TextFormField
                                    filled: true, // fill background colour
                                    fillColor: Colors.white.withOpacity(0.8),
                                  ),
                                  controller: _destinationsearchcontroller,
                                  textCapitalization: TextCapitalization.words,
                                  onTap: () {
                                    setState(() {
                                      originplacepredictions = null;
                                    });
                                  },
                                  onChanged: (value) async {
                                    print(value);
                                    List<PlacePrediction>? placepredictions =
                                        await PlaceAutocompleteAPI()
                                            .getPlacePrediction(
                                                _destinationsearchcontroller
                                                    .text);
                                    if (currentlocation != null) {
                                      (placepredictions ?? []).insert(
                                          0, currentLocationPlacePrediction);
                                    }
                                    setState(() {
                                      destinationplacepredictions =
                                          placepredictions;
                                    });
                                  },
                                ))),
                        IconButton(
                          onPressed: () async {
                            if (_destinationsearchcontroller.text ==
                                "current location") {
                              destination = currentplace;
                            } else if (_destinationsearchcontroller.text !=
                                destination?.displayName) {
                              destination = await PlacesAPI()
                                  .getPlace(_destinationsearchcontroller.text);
                              nearestcarparks = await PlacesAPI()
                                .get_nearest_carparks_google(destination);
                              nearestcarparkshdb = await hdbcarparkapi
                                  .findNearestAvailableCarparks(destination);
                              nearestcarparks = await PlacesAPI()
                                  .reconcile(nearestcarparks, nearestcarparkshdb);
                            }
                            
                            setState(() {
                              goToPlace(destination, "destination");
                              routeresults = null;
                              walkingrouteresults = null;
                              tappedIndex = null;
                              originplacepredictions = null;
                              destinationplacepredictions = null;
                              setallroutespolylines();
                              setPolyline();
                            });
                          },
                          icon: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white
                                  .withOpacity(0.8), // Adjust opacity here
                            ),
                            child: Icon(Icons.check),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: IconButton(
                  onPressed: () async {
                    if (_originsearchcontroller.text == "current location") {
                      origin = currentplace;
                    } else if (_originsearchcontroller.text !=
                        origin?.displayName) {
                      origin = await PlacesAPI()
                          .getPlace(_originsearchcontroller.text);
                    }

                    if (_destinationsearchcontroller.text ==
                        "current location") {
                      destination = currentplace;
                    } else if (_destinationsearchcontroller.text !=
                        destination?.displayName) {
                      destination = await PlacesAPI()
                          .getPlace(_destinationsearchcontroller.text);
                    }
                    nearestcarparks = await PlacesAPI()
                        .get_nearest_carparks_google(destination);
                    nearestcarparkshdb = await hdbcarparkapi
                        .findNearestAvailableCarparks(destination);
                    nearestcarparks = await PlacesAPI()
                        .reconcile(nearestcarparks, nearestcarparkshdb);
                    routeresults = await RoutesAPI().getRoute(origin?.location,
                        destination?.location, nearestcarparks);
                    walkingrouteresults = await WalkingRoutesAPI()
                        .getWalkingRoute(origin?.location,
                            destination?.location, nearestcarparks);

                    setState(() {
                      goToPlace(origin, "origin");
                      goToPlace(destination, "destination");
                      tappedIndex = null;
                      originplacepredictions = null;
                      destinationplacepredictions = null;
                      setallroutespolylines();
                      setPolyline();
                    });
                  },
                  icon: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          Colors.white.withOpacity(0.8), // Adjust opacity here
                    ),
                    child: Icon(
                      Icons.search,
                      size: 50,
                    ),
                  ),
                ),
              )
            ]),
          ],
        ),
        DraggableScrollableSheet(
          initialChildSize: (routeresults ?? []).length == 0 ? 0 : 0.05,
          minChildSize: (routeresults ?? []).length == 0 ? 0 : 0.05,
          maxChildSize: 0.4,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              color: Colors.white,
              child: ListView.builder(
                itemCount: (routeresults ?? []).length,
                controller: scrollController,
                itemBuilder: (BuildContext context, int index) 
                {
                  if ((routeresults?[index] == null) && (walkingrouteresults?[index] == null))
                  {
                    return SizedBox.shrink();
                  }
                  return _buildRouteContainer(index);
                },
              ),
            );
          },
        ),
        if (destinationplacepredictions != null &&
            destinationplacepredictions!.isNotEmpty)
          Positioned(
            top: 120,
            left: 10,
            child: Container(
              color: Colors.transparent,
              width: 315,
              height: 200,
              child: ListView.builder(
                controller: ScrollController(),
                itemCount: destinationplacepredictions?.length ?? 0,
                itemBuilder: (BuildContext context, int index) {
                  return _buildPlacePredictionContainer(index, 'destination');
                },
              ),
            ),
          ),
        if (originplacepredictions != null &&
            originplacepredictions!.isNotEmpty)
          Positioned(
            top: 55,
            left: 10,
            child: Container(
              color: Colors.transparent,
              width: 315,
              height: 200,
              child: ListView.builder(
                controller: ScrollController(),
                itemCount: originplacepredictions?.length ?? 0,
                itemBuilder: (BuildContext context, int index) {
                  return _buildPlacePredictionContainer(index, 'origin');
                },
              ),
            ),
          )
      ]),
    );
  }

  Widget _buildPlacePredictionContainer(int index, String type) {
    PlacePrediction? prediction;
    if (type == 'origin') {
      prediction = originplacepredictions?[index];
    } else {
      prediction = destinationplacepredictions?[index];
    }

    return GestureDetector(
      onTap: () async {
        if (type == 'origin') {
          if (prediction == currentLocationPlacePrediction) {
            origin = currentplace;
          } else {
            origin = await PlacesAPI().getplace(prediction);
          }
          _originsearchcontroller.text = origin?.displayName ?? '';
          setState(() {
            goToPlace(origin, "origin");
            originplacepredictions = null;
            tappedIndex = null;
            routeresults = null;
            walkingrouteresults = null;
            setallroutespolylines();
            setPolyline();
          });
        } else {
          if (prediction == currentLocationPlacePrediction) {
            destination = currentplace;
          } else {
            destination = await PlacesAPI().getplace(prediction);
          }
          _destinationsearchcontroller.text = destination?.displayName ?? '';
          nearestcarparks =
              await PlacesAPI().get_nearest_carparks_google(destination);
          nearestcarparkshdb =
              await hdbcarparkapi.findNearestAvailableCarparks(destination);
          nearestcarparks =
              await PlacesAPI().reconcile(nearestcarparks, nearestcarparkshdb);
          setState(() {
            goToPlace(destination, "destination");
            destinationplacepredictions = null;
            tappedIndex = null;
            routeresults = null;
            walkingrouteresults = null;
            setallroutespolylines();
            setPolyline();
          });
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.0),
            color: Colors.white),
        child: Text(
          prediction?.text ?? 'No prediction available',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildRouteContainer(int index) 
  {
    // Build your route container here
    return GestureDetector(
      onTap: () {
        setState(() {
          if (tappedIndex == index) {
            // Deselect the route if it's already selected
            tappedIndex = null;
          } else {
            // Select the tapped route
            tappedIndex = index;
          }
          setPolyline();
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: tappedIndex == index ? Colors.red : Colors.black,
            width: tappedIndex == index ? 4.0 : 1.0,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Route ${index + 1}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
              ((routeresults?[index] != null) ? routeresults![index].toString() : '') + ((walkingrouteresults?[index] != null) ? ("\n \nWalking from car park \n" + walkingrouteresults![index].toString()) : ''),                
              style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> goToPlace(Place? place, String type) async {
    if (place == null) {
      setMarker(place, type);
      return;
    }
    final double lat = place.location.latitude;
    final double lng = place.location.longitude;
    final LatLng point = LatLng(lat, lng);

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: 12)));
    setMarker(place, type);
    _customdestinationInfoWindowController.hideInfoWindow!();
    _customoriginInfoWindowController.hideInfoWindow!();
    for (int i = 0;
        i < _customnearestcarparksInfoWindowControllerlist.length;
        i++) {
      _customnearestcarparksInfoWindowControllerlist[i].hideInfoWindow!();
    }
  }
}
