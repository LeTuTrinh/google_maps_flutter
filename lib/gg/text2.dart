import 'dart:async';
import 'dart:ffi';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/directions.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart' as http;
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

class DemoPage extends StatefulWidget {
  @override
  _DemoPageState createState() => _DemoPageState();
}

const kGoogleApiKey = 'AIzaSyANR8KOn69KWPBv801CX85_X1JgA_3drLc';
final places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class _DemoPageState extends State<DemoPage> {
  GoogleMapController? mapController;

  final CameraPosition initialPosition = CameraPosition(
    target: LatLng(10.957265036735107, 106.83843332566492),
    zoom: 11.0,
  );
  CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  var typemap = MapType.normal;
  // var cordinate1 = 'cordinate';
  var lat = 10.957265036735107;
  var long = 106.83843332566492;
  var address = '';
  String location = "Search Location";
  Future<void> getAddress(latt, longg) async {
    List<Placemark> placemark = await placemarkFromCoordinates(latt, longg);
    print(
        '-----------------------------------------------------------------------------------------');
    //here you can see your all the relevent information based on latitude and logitude no.
    print(placemark);
    print(
        '-----------------------------------------------------------------------------------------');
    Placemark place = placemark[0];
    setState(() {
      address =
          '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
    });
  }

  Future<Position> getUserCurrentLocation() async {
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) async {
      await Geolocator.requestPermission();
      print("ERROR" + error.toString());
    });
    return await Geolocator.getCurrentPosition();
  }

//////
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Uint8List? marketimages;

  final List<Marker> _markers = <Marker>[];

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

  MapType _currentMapType = MapType.normal;
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
      backgroundColor: Colors.red[900],
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
          targetHeight: 150,
          targetWidth: 150,
        );

        final ui.FrameInfo frameInfo = await markerImageCodec.getNextFrame();
        final ByteData? byteData =
            await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List resizedImageMarker = byteData!.buffer.asUint8List();
        // BitmapDescriptor markIcons =
        //     BitmapDescriptor.fromBytes(byte, size: const Size(.1, .1));

        _markers.add(
          Marker(
            markerId: MarkerId(doc["id"]),
            icon: BitmapDescriptor.fromBytes(resizedImageMarker),
            position: LatLng(geo.latitude, geo.longitude),
            onTap: () {
              setState(() {
                lat = geo.latitude;
                long = geo.longitude;
                getAddress(lat, long);
                mapController!.animateCamera(CameraUpdate.newCameraPosition(
                    CameraPosition(
                        target: LatLng(geo.latitude, geo.longitude),
                        zoom: 20)));
                LatLng(geo.latitude, geo.longitude);
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
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
              });
            },
            // infoWindow: InfoWindow(title: 'Shop: ' + doc["name"].toString()),
          ),
        );
        // setState(() {
        //   getAddress(lat, long);
        // });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      child: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              markers: Set<Marker>.of(_markers),
              myLocationEnabled: true,
              compassEnabled: true,
              initialCameraPosition: initialPosition,
              mapType: _currentMapType,
              onMapCreated: (GoogleMapController controller) {
                _customInfoWindowController.googleMapController = controller;

                setState(() {
                  mapController = controller;
                });
              },
              onCameraMove: (position) {
                _customInfoWindowController.onCameraMove!();
                setState(() {});
              },
              onTap: (postition) {
                _customInfoWindowController.hideInfoWindow!();
                setState(() {
                  // lat = postition.latitude;
                  // long = postition.longitude;
                  // getAddress(lat, long);

                  // cordinate1 = cordinate.toString();
                });
              },
            ),
            Positioned(
                //search input bar
                top: 10,
                child: InkWell(
                    onTap: () async {
                      var place = await PlacesAutocomplete.show(
                          context: context,
                          apiKey: kGoogleApiKey,
                          mode: Mode.overlay,
                          types: [],
                          strictbounds: false,
                          components: [Component(Component.country, 'vi')],
                          //google_map_webservice package
                          onError: (err) {
                            print(err);
                          });

                      if (place != null) {
                        setState(() {
                          location = place.description.toString();
                          print("====================" + location);
                        });

                        //form google_maps_webservice package
                        final plist = GoogleMapsPlaces(
                          apiKey: kGoogleApiKey,
                          apiHeaders: await GoogleApiHeaders().getHeaders(),
                          //from google_api_headers package
                        );
                        String placeid = place.placeId ?? "0";
                        final detail = await plist.getDetailsByPlaceId(placeid);
                        final geometry = detail.result.geometry!;
                        final lat = geometry.location.lat;
                        final lang = geometry.location.lng;
                        var newlatlang = LatLng(lat, lang);

                        //move map camera to selected place with animation
                        mapController?.animateCamera(
                            CameraUpdate.newCameraPosition(
                                CameraPosition(target: newlatlang, zoom: 17)));
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: Card(
                        child: Container(
                            padding: EdgeInsets.all(0),
                            width: MediaQuery.of(context).size.width - 40,
                            child: ListTile(
                              title: Text(
                                location,
                                style: TextStyle(fontSize: 18),
                              ),
                              trailing: Icon(Icons.search),
                              dense: true,
                            )),
                      ),
                    ))),
            Positioned(
              left: 70,
              bottom: 50,
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(2)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    address,
                    softWrap: true,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 16.0, left: 16.0, top: 90.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  children: <Widget>[
                    button(_onMapTypeButtonPressed, Icons.map),
                    SizedBox(
                      height: 16.0,
                    ),
                    FloatingActionButton(
                      backgroundColor: Colors.red[900],
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
                                CameraUpdate.newCameraPosition(cameraPosition));
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
              offset: 40,
            ),
          ],
        ),
      ),
    ));
  }
}
