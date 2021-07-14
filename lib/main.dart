import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latihan_google_map/direction_model.dart';
import 'package:latihan_google_map/direction_service.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _initialCamera =
      CameraPosition(target: LatLng(0.0, 0.0), zoom: 11.5);
  GoogleMapController _googleMapController;
  Position _currentPosition;
  String _currentAddress;
  String _startAddress = '';
  String _destinationAddress = '';
  Marker _start;
  Marker _destination;
  Directions _direction;
  TextEditingController startAddressController = TextEditingController();
  TextEditingController destinationAddressController = TextEditingController();

  // Set<Marker> _markers;

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            initialCameraPosition: _initialCamera,
            onMapCreated: (controller) => _googleMapController = controller,
            markers: {
              if (_start != null) _start,
              if (_destination != null) _destination
            },
            polylines: {
              if (_direction != null)
                Polyline(
                    polylineId: PolylineId('overview_polyline'),
                    color: Colors.red,
                    width: 5,
                    points: _direction.polylinePoints
                        .map((e) => LatLng(e.latitude, e.longitude))
                        .toList())
            },
            onLongPress: _addMarker,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      height: 60,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          // border: Border.all(width: 1, color: Colors.amber),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            // color: Colors.blue,
                            width: MediaQuery.of(context).size.width / 2 + 60,
                            child: TextField(
                              controller: startAddressController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Input Your start location",
                              ),
                            ),
                          ),
                          Container(
                            // color: Colors.amber,
                            child: IconButton(
                                icon: Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  getCurrentLocation();
                                }),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 60,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          // border: Border.all(width: 1, color: Colors.amber),
                          borderRadius: BorderRadius.circular(10)),
                      margin: EdgeInsets.only(top: 13),
                      width: double.infinity,
                      child: TextField(
                        controller: destinationAddressController,
                        onChanged: (string) async {
                          setState(() {
                            _destinationAddress = string;
                          });
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Input Your destination location",
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 6,
                    ),
                    if (_direction != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6.0,
                          horizontal: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellowAccent,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 6.0,
                            )
                          ],
                        ),
                        child: Text(
                          'Distance : ${_direction.totalDistance}, ${_direction.totalDuration}',
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ElevatedButton(
                        child: Text("Get Route"),
                        onPressed: () async {
                          try {
                            if (_startAddress != null &&
                                _destinationAddress != null) {
                              List<Location> startPlacemark =
                                  await locationFromAddress(_startAddress);
                              List<Location> destPlacemark =
                                  await locationFromAddress(
                                      _destinationAddress);

                              final direction = await DirectionsRepository()
                                  .getDirections(
                                      origin: LatLng(startPlacemark[0].latitude,
                                          startPlacemark[0].longitude),
                                      destination: LatLng(
                                          destPlacemark[0].latitude,
                                          destPlacemark[0].longitude));

                              // print(destPlacemark[0]);
                              _addMarker(LatLng(destPlacemark[0].latitude,
                                  destPlacemark[0].longitude));
                              setState(() {
                                _direction = direction;
                              });
                            }
                          } catch (e) {
                            print(e);
                          }
                        }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addMarker(LatLng pos) async {
    if (_start == null || (_start != null && _destination != null)) {
      setState(() {
        _start = Marker(
            markerId: MarkerId('start'),
            infoWindow: InfoWindow(title: 'start'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            position: pos);
        //info destination
        _destination = null;

        //resset direction
        _direction = null;
      });
    } else {
      setState(() {
        _destination = Marker(
          markerId: MarkerId('destimation'),
          infoWindow: InfoWindow(title: 'destimation'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          position: pos,
        );
      });

      //get direction
      final direction = await DirectionsRepository().getDirections(
          origin: _start.position, destination: _destination.position);

      setState(() {
        _direction = direction;
      });
    }
  }

  getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;

        print('CURRENT POS: $_currentPosition');
        _googleMapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 12.0)));
      });
    }).catchError((e) {
      print(e);
    });
    _addMarker(LatLng(_currentPosition.latitude, _currentPosition.longitude));
    await getAddress();
  }

  Future<void> getAddress() async {
    try {
      // Places are retrieved using the coordinates
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      // Taking the most probable result
      Placemark place = p[0];

      setState(() {
        // Structuring the address
        _currentAddress = "${place.street}";

        // Update the text of the TextField
        startAddressController.text = _currentAddress;

        // Setting the user's present location as the starting address
        _startAddress = _currentAddress;
      });
    } catch (e) {
      print(e);
    }
  }
}
