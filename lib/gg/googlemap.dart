import 'dart:async';
import 'package:search_map_location/search_map_location.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:search_map_location/utils/google_search/place.dart';

class GGmap extends StatefulWidget {
  const GGmap({Key? key}) : super(key: key);

  @override
  _GGmapState createState() => _GGmapState();
}

////////////////////////////
const kGoogleApiKey = 'AIzaSyANR8KOn69KWPBv801CX85_X1JgA_3drLc';
final homeScaffoldKey = GlobalKey<ScaffoldState>;

///////////////////
///
///
class _GGmapState extends State<GGmap> {
  /////////////////////////////////////
  String googleApikey = kGoogleApiKey;
  GoogleMapController? mapController; //contrller for Google map
  // CameraPosition? cameraPosition;
  LatLng _lastMapPosition = _center;
  static const LatLng _center =
      const LatLng(10.957265036735107, 106.83843332566492);
  MapType _currentMapType = MapType.normal;

  static final CameraPosition _position1 = CameraPosition(
    bearing: 192.833,
    target: LatLng(10.9395, 106.8294),
    tilt: 59.440,
    zoom: 11.0,
  );

  CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _kGoogle = const CameraPosition(
    target: _center,
    zoom: 14,
  );

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Uint8List? marketimages;

  final List<Marker> _markers = <Marker>[];

  final List<Marker> _circle = <Circle>[].cast<Marker>();

  Future<Uint8List> getImages(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetHeight: width);

    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  @override
  void initState() {
    super.initState();

    loadData();
  }

  _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
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

  Future<void> setLatLong() {
    CollectionReference shops = FirebaseFirestore.instance.collection('shops');
    return shops
        .doc('zUJ3XCVcuA')
        .update({'latlong': GeoPoint(10.957311964849579, 106.84192432421141)})
        .then((value) => print("Shop set"))
        .catchError((error) => print("Failed to add user: $error"));
  }

  /////////////////////////
  Widget buildMarkerImage() {
    return Container(
      width: 48.0,
      height: 48.0,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black,
          width: 1.0,
        ),
      ),
    );
  }

/////
///////
///////
//////
  loadData() async {
    CollectionReference shops = FirebaseFirestore.instance.collection('shops');
    shops.get().then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) async {
        GeoPoint geo = doc["latlong"];
        Uint8List byte = (await NetworkAssetBundle(Uri.parse(doc["url"][0]))
                .load(doc["url"][0]))
            .buffer
            .asUint8List();
        final ui.Codec markerImageCodec = await ui.instantiateImageCodec(
          byte.buffer.asUint8List(),
          targetHeight: 100,
          targetWidth: 100,
        );

        final ui.FrameInfo frameInfo = await markerImageCodec.getNextFrame();
        final ByteData? byteData =
            await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List resizedImageMarker = byteData!.buffer.asUint8List();

        _markers.add(
          Marker(
            markerId: MarkerId(doc["id"]),
            icon: BitmapDescriptor.fromBytes(resizedImageMarker),
            draggable: true,
            position: LatLng(geo.latitude, geo.longitude),

            // infoWindow: InfoWindow(
            //   title: 'Shop: ' + doc["name"].toString(),
            // ),
            onTap: () {
              _customInfoWindowController.addInfoWindow!(
                  Container(
                    height: 250,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 250,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Colors.red,
                                image: DecorationImage(
                                    image: NetworkImage(doc["url"][0]),
                                    fit: BoxFit.fitWidth,
                                    filterQuality: FilterQuality.high),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      doc["name"],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text('Min'),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(doc["desc"]),
                                )
                              ],
                            ),
                          )
                        ]),
                  ),
                  LatLng(geo.latitude, geo.longitude));
            },
          ),
        );
        setState(() {});
      });
    });
  }

  ////địa chỉ
  ///
  ////
  ///
  //////
// created method for getting user current location
  Future<Position> getUserCurrentLocation() async {
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) async {
      await Geolocator.requestPermission();
      print("ERROR" + error.toString());
    });
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SafeArea(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 11.0,
                ),
                markers: Set<Marker>.of(_markers),
                mapType: _currentMapType,
                myLocationEnabled: true,
                compassEnabled: true,
                onTap: (postition) {
                  _customInfoWindowController.hideInfoWindow!();
                  setState(() {});
                },
                onCameraMove: (position) {
                  _customInfoWindowController.onCameraMove!();
                  setState(() {});
                },
                onMapCreated: (GoogleMapController controller) {
                  _customInfoWindowController.googleMapController = controller;

                  setState(() {
                    mapController = controller;
                  });
                },
              ),

              //////////////////////////////
              Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SearchLocation(
                    apiKey: kGoogleApiKey,
                    onSelected: (Place place) {
                      print(place.description);
                    },
                  )),
              // ////
              // /
              // /
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
                      FloatingActionButton(
                        // backgroundColor: Colors.white,
                        onPressed: () async {
                          getUserCurrentLocation().then((value) async {
                            print(value.latitude.toString() +
                                "," +
                                value.longitude.toString());
                            CameraPosition cameraPosition = CameraPosition(
                              target: LatLng(value.latitude, value.longitude),
                              zoom: 14,
                            );

                            setState(() {
                              mapController!.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                      cameraPosition));
                            });
                          });
                        },
                        child: Icon(
                          Icons.location_searching_outlined,
                        ),
                      ),
                      SizedBox(
                        height: 16.0,
                      ),
                    ],
                  ),
                ),
              ),
              CustomInfoWindow(
                controller: _customInfoWindowController,
                height: 150,
                width: 250,
                offset: 60,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
