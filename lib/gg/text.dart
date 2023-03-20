import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapsDemo extends StatefulWidget {
  MapsDemo() : super();

  final String title = "Maps Demo";

  @override
  MapsDemoState createState() => MapsDemoState();
}

class MapsDemoState extends State<MapsDemo> {
  //
  Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = const LatLng(10.964112, 106.856461);
  final Set<Marker> _markers = {};
  LatLng _lastMapPosition = _center;
  MapType _currentMapType = MapType.normal;

  static final CameraPosition _position1 = CameraPosition(
    bearing: 192.833,
    target: LatLng(10.9395, 106.8294),
    tilt: 59.440,
    zoom: 11.0,
  );

  ////////////////////////////
  Future<void> _searchLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      Location location = locations.first;
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: 14,
        ),
      ));
    } catch (e) {
      print(e);
    }
  }

//////
  ///

  ///
  ///////
  ///////////////
  Future<void> _goToPosition1() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_position1));
  }

  _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  _onAddMarkerButtonPressed() {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(_lastMapPosition.toString()),
          position: _lastMapPosition,
          infoWindow: InfoWindow(
            title: 'This is a Title',
            snippet: 'This is a snippet',
          ),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });
  }

  Widget button(Function function, IconData icon) {
    return FloatingActionButton(
      onPressed: () {
        function();
      },
      materialTapTargetSize: MaterialTapTargetSize.padded,
      backgroundColor: Colors.blue,
      child: Icon(
        icon,
        size: 36.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.blue,
        ),
        body: Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: _onMapCreated,
              myLocationEnabled: true,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              mapType: _currentMapType,
              markers: Set<Marker>.of([
                Marker(
                  markerId: MarkerId('myMarker'),
                  position: LatLng(10.958822566665145, 106.86828582075236),
                ),
              ]),
              circles: Set<Circle>.of([
                Circle(
                  circleId: CircleId('myCircle'),
                  center: LatLng(10.958822566665145, 106.86828582075236),
                  radius: 1000, // đơn vị tính là mét
                  fillColor: Colors.blue.withOpacity(0.3), // độ mờ của màu sắc
                  strokeColor:
                      Colors.blue.withOpacity(0.5), // độ mờ của màu viền
                  strokeWidth: 2,
                ),
              ]),
              onCameraMove: _onCameraMove,
            ),
            ///////////////////////////////////////////
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter a location',
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (String query) {
                _searchLocation(query);
              },
            ),
////////
//////
/////
            Padding(
              padding: EdgeInsets.only(right: 16.0, left: 16.0, top: 60.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  children: <Widget>[
                    button(_onMapTypeButtonPressed, Icons.map),
                    SizedBox(
                      height: 16.0,
                    ),
                    button(_onAddMarkerButtonPressed, Icons.add_location),
                    SizedBox(
                      height: 16.0,
                    ),
                    button(_goToPosition1, Icons.location_searching),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
