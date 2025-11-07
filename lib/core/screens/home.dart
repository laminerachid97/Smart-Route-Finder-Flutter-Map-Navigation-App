import 'dart:async';
import 'dart:developer' as log;
import 'dart:math';

// import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as poly;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:navigation/core/data/citties.dart';
import 'package:navigation/core/services/location_permission.dart';
import 'package:navigation/core/widgets/custom_button.dart';
import 'package:navigation/core/widgets/custom_textfield.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _Home();
}

class _Home extends State<Home> with TickerProviderStateMixin {
  double width = 0.0;
  double height = 0.0;
  double startY = 0.0;
  double buttom = 0.0;
  double boxHeight = 0.0;
  double distance = 0.0;
  final GlobalKey myBoxKey = GlobalKey();
  final GlobalKey myInputKey = GlobalKey();
  bool boxOpened = false;
  final TextEditingController _controllerFrom = TextEditingController();
  final TextEditingController _controllerTo = TextEditingController();
  CameraPosition? _initialCameraPosition;
  late GoogleMapController mapController;
  Position? position;
  StreamSubscription<Position>? positionStream; 
  BitmapDescriptor? carIcon;

  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  String? darkMapStyle;
  double? _deviceDirection;
  LatLng? lastPosition;
  final List<Widget> _column = [];
  LatLng? direction;
  List<dynamic>? citties;

  @override
  void initState() {
    super.initState();
    _initCamera();
    downloadIconCar();
    citties = moroccoCities.entries.toList();
    // _loadMapStyle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final height = getSizeBoxHeight();
      distance = getDistanceToScreenBottom(myInputKey, context);
      if (height != null && mounted) {
        setState(() {
          boxHeight = height;
          buttom = - boxHeight;
        });
      } else if (height != null && mounted) {
        setState(() {
          boxHeight = 0;
        });
      }
    });

  }

  Future<void> downloadIconCar() async {
    carIcon = await BitmapDescriptor.asset(ImageConfiguration(size: Size(48, 48)), "assets/car.png");
    if (carIcon == null) {
      log.log("nothing");
    } else {
      log.log(carIcon.toString());
    }
  }

  Future<void> _getRoutePolyline(Position start, LatLng end) async {
    try {
      poly.PolylinePoints polylinePoints = poly.PolylinePoints(apiKey: dotenv.env['GOOGLE_MAPS_KEY']!);

      poly.RoutesApiResponse result = await polylinePoints.getRouteBetweenCoordinatesV2(
        request: poly.RoutesApiRequest(
          origin: poly.PointLatLng(start.latitude, start.longitude),
          destination: poly.PointLatLng(end.latitude, end.longitude),
          travelMode: poly.TravelMode.driving,
          routingPreference: poly.RoutingPreference.trafficAware
          // travelMode: poly.TravelMode.walking,
          // routingPreference: poly.RoutingPreference.unspecified
        )
      );

      if (result.routes.isNotEmpty) {
        polylineCoordinates.clear();
        poly.Route route = result.routes.first;
        List<poly.PointLatLng> points = route.polylinePoints ?? [];
        polylineCoordinates = points.map((point) => LatLng(point.latitude, point.longitude)).toList();
      }

      double bearing = _calculateBearing(polylineCoordinates[0], polylineCoordinates[1]);
      // LatLng? snappedPosition = await getSnappedToRoad(LatLng(start.latitude, start.longitude));
      LatLng? snappedPosition = getClosestPointOnRoute(LatLng(start.latitude, start.longitude), polylineCoordinates);
      // debugPrint(snappedPosition.toString());
          final latTween = Tween<double>(begin: lastPosition!.latitude, end: snappedPosition.latitude);
          final lngTween = Tween<double>(begin: lastPosition!.longitude, end: snappedPosition.longitude);

          final controller = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
          Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.linear);

      controller.addListener(() {
        final newPos = LatLng(latTween.evaluate(animation), lngTween.evaluate(animation));
        setState(() {
        markers.removeWhere((m) => m.markerId.value == "me");
          markers.add(
            Marker(
              markerId: MarkerId("me"),
              position: newPos,
              icon: carIcon!,
              infoWindow: const InfoWindow(title: "mycar"),
              anchor: Offset(0.5, 0.5),
              // rotation: _deviceDirection!
            ),
          );
          
        markers.add(Marker(markerId: MarkerId("dest"), position: LatLng(end.latitude, end.longitude)));
        mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(snappedPosition.latitude, snappedPosition.longitude), zoom: 18, tilt: 30, bearing: bearing)));
      });
      });

      await controller.forward();
      controller.dispose();

      lastPosition = snappedPosition;

        // this for the car in case we want to turn it when the phone is turned
        FlutterCompass.events!.listen((event) {
          double heading = event.heading ?? 0;
          double correctedRotation = (heading - 140) % 360;
          setState(() {
            _deviceDirection = correctedRotation;
          });
        });
    } catch (e) {
      log.log("error getting routes ==> $e");
    }
  }

  // Future<LatLng?> getSnappedToRoad(LatLng rawPosition) async {
  //   final url = 'https://roads.googleapis.com/v1/snapToRoads';
  //   final dio = Dio();
  //   final response = await dio.get(url, queryParameters: {
  //     'path': '${rawPosition.latitude},${rawPosition.longitude}',
  //     'interpolate': true,
  //     'key': dotenv.env['GOOGLE_MAPS_KEY']!,
  //   });

  //   if (response.statusCode == 200 &&
  //       response.data['snappedPoints'] != null &&
  //       response.data['snappedPoints'].isNotEmpty) {
  //     final snapped = response.data['snappedPoints'][0]['location'];
  //     return LatLng(snapped['latitude'], snapped['longitude']);
  //   }

  //   return null;
  // }

  LatLng getClosestPointOnRoute(LatLng currentPosition, List<LatLng> routePoints) {

  LatLng closest = routePoints.first;
  double minDistance = double.infinity;

  for (final point in routePoints) {
    final distance = _calculateDistance(currentPosition, point);
    if (distance < minDistance) {
      minDistance = distance;
      closest = point;
    }
  }

  return closest;
}

double _calculateDistance(LatLng p1, LatLng p2) {
  const R = 6371000; 
  double dLat = (p2.latitude - p1.latitude) * 3.14159 / 180;
  double dLon = (p2.longitude - p1.longitude) * 3.14159 / 180;
  double a = 
      sin(dLat / 2) * sin(dLat / 2) +
      cos(p1.latitude * 3.14159 / 180) *
          cos(p2.latitude * 3.14159 / 180) *
          sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

  double _calculateBearing (LatLng start, LatLng end) {
    double lat1 = start.latitude * (pi / 180);
    double lon1 = start.longitude * (pi / 180);
    double lat2 = end.latitude * (pi / 180);
    double lon2 = end.longitude * (pi / 180);

    double dLon = lon2 - lon1;

    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double bearing = atan2(y, x);

    bearing = bearing * (180 / pi); 
    return (bearing + 360) % 360; 
  }

  //   Future<void> _loadMapStyle () async {
  //   darkMapStyle = await rootBundle.loadString('assets/map_style.json');
  // }

    void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // controller.setMapStyle(darkMapStyle).then((value) {
    //   log.log("Map style applied successfully!");
    // })
    // .catchError((error) {
    //   log("Error applying map style: $error");
    // });
  }

  Future<void> _initCamera() async {
    final status = await getPermissionLocation();
    if (status) {
      position = await Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high));
      if (position == null) {
        return;
      }
      lastPosition = LatLng(position!.latitude, position!.longitude);
      _initialCameraPosition = CameraPosition(target: LatLng(position!.latitude, position!.longitude), zoom: 20, tilt: 10);
      if(mounted) {
        setState(() {});
      }
    } else {
      log.log('Location permission permanently denied.');
      return;
    }
  }

  @override
  void didChangeDependencies() {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _controllerFrom.dispose();
    _controllerTo.dispose();
    mapController.dispose();
    positionStream!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.white38,
            width: width,
            height: height,
            child: _initialCameraPosition == null
                ? const Center(child: CircularProgressIndicator()) 
                : GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _initialCameraPosition!,
                    // onMapCreated: (controller) {
                    //   mapController = controller;
                    // },
                    onMapCreated: _onMapCreated,
                    markers: markers,
                    polylines: {
                      Polyline(
                        polylineId: PolylineId("route"),
                        color: Colors.orange,
                        width: 5,
                        points: polylineCoordinates
                      )
                    },
                  ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 200),
            width: width,
            bottom: buttom,
            child: SizedBox(
              width: width,
              child: GestureDetector(
                onVerticalDragStart: (details) {
                  startY = details.globalPosition.dy;
                },
                onVerticalDragEnd: (details) {
                  double currentY = details.globalPosition.dy;
                  if (startY - currentY > 50) {
                    // debugPrint("Dragged to top!");
                    setState(() {
                      buttom = 0;
                      boxOpened = true;
                    });
                  } else {
                    // debugPrint("Dragged to down!");
                    setState(() {
                      buttom = - boxHeight;
                      boxOpened = false;
                    });
                  }
                },
                child: Column(
                children: [
                  SizedBox(width: width,child: CustomButton(text: "Start Direction", onPressed: () {
                    setState(() {
                      
                      if (boxOpened) {
                        boxOpened = false;
                        buttom = - boxHeight;
                      } else {
                        boxOpened = true;
                        buttom = 0;
                      }
                    });
                  }, cutTopsOnly: true,),),
                  Container(
                    key: myBoxKey,
                    color: Colors.white,
                    // height: 200,
                    child: Column(
                      children: [
                        const SizedBox(height: 15,),
                        // Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: CustomTextField(controller: _controllerFrom, hintText: "Current Position"),),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(width: 1),
                          borderRadius: BorderRadius.circular(10)
                        ),margin: EdgeInsets.symmetric(horizontal: 10), width: width,alignment: Alignment.centerLeft,height: 50,child:Text("-- Current Position --", style: TextStyle(fontSize: 16),),),
                        const SizedBox(height: 15,),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: CustomTextField(key: myInputKey,onChanged: (value) {
                          setState(() {
                            // log.log(value);
                              final filtered = citties!.where((entry) => entry.key.toLowerCase().startsWith(value.toLowerCase())).toList();
                            if (value.isEmpty) {
                              _column.clear();
                              return;
                            } else {
                              _column.clear();
                              for (var citie in filtered) {
                                final cityName = citie.key;
                                final lat = citie.value['lat'];
                                final lon = citie.value['lon'];
                                _column.add(
                                  SizedBox(
                                    width: width, 
                                    child: ElevatedButton(
                                      onPressed: () {
                                        LatLng newDirection = LatLng(
                                          lat is String ? double.parse(lat) : lat,
                                          lon is String ? double.parse(lon) : lon,
                                        );
                                        direction = newDirection;
                                        _controllerTo.text = cityName.toString();
                                        setState(() {
                                          _column.clear();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent, 
                                        shadowColor: Colors.transparent,      
                                        elevation: 0,                         
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(0), 
                                        ),
                                      ),
                                      child: Text(
                                        cityName,
                                        style: const TextStyle(
                                          color: Colors.black, 
                                        ),
                                      ),
                                    ),
                                  )
                                );
                              }
                            }
                            // log.log(filtered.toString());
                            
                          });
                        },controller: _controllerTo, hintText: "To"),),
                        const SizedBox(height: 15,),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 5) , child: SizedBox(width: width,height: 75,child: CustomButton(text: "Start travel", onPressed: _goToPlace, color: Colors.black,),),),
                        const SizedBox(height: 15,),
                      ],
                    ),
                  )
                ],
              ),
              ),
            ),
          ),
          boxOpened && _column.isNotEmpty ? Positioned(
            bottom: distance + 52,
            left: 10,
            right: 10,
            child: Container(
              // margin: EdgeInsets.symmetric(horizontal: 10),
              // padding: EdgeInsets.symmetric(horizontal: 10),
              height: 170,
              constraints: BoxConstraints(maxHeight: 170),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10), 
              ),
              width: width,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _column,
              ),
              ),
            ),
          ) : const SizedBox()
        ],
      ),
    );
  }

  Future<void> _goToPlace() async {
    if (direction == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You have to pick your destination first!")));
      return;
    }

    await _getRoutePolyline(position!, direction!);

    positionStream = Geolocator.getPositionStream(locationSettings: LocationSettings(accuracy: LocationAccuracy.high,distanceFilter: 5)).listen((Position position) async {
      log.log('الموقع الجديد: ${position.latitude}, ${position.longitude}');
      await _getRoutePolyline(position, direction!);
    });
    
    if (boxOpened && mounted) {
      boxOpened = false;
      buttom = - boxHeight;
      FocusScope.of(context).unfocus();
    }
  }

  double? getSizeBoxHeight () {
    final RenderBox? renderBox = myBoxKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      return renderBox.size.height;
    }

    return null;
  }

  double getDistanceToScreenBottom(GlobalKey myInputKey, BuildContext context) {

    final RenderBox? inputPos = myInputKey.currentContext?.findRenderObject() as RenderBox?;

    if (inputPos == null) {
      return 0.0;
    }
    final mediaQuery = MediaQuery.of(context);

    final screenHeight = mediaQuery.size.height;
    
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    final viewportBottomEdge = screenHeight - keyboardHeight;

    final position = inputPos.localToGlobal(Offset.zero);
    final widgetBottomY = position.dy + inputPos.size.height;

    final distance = viewportBottomEdge - widgetBottomY;

    return distance;
  }
}