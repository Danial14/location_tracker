import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sc_location_tracker/helper/data_parser.dart';

class MapsScreen extends StatefulWidget{
  double latitude, longitude;
  static const String routeNaMe = "/Maps";
  MapsScreen({required this.latitude, required this.longitude});
  @override
  State<MapsScreen> createState() {
    return MapsState();
  }
}
class MapsState extends State<MapsScreen>{
  Completer<GoogleMapController> _controller = Completer();
  // Object for PolylinePoints
  late PolylinePoints? polylinePoints = null;

// List of coordinates to join
  List<LatLng> polylineCoordinates = [];

// Map storing polylines created by connecting two points
  Map<PolylineId, Polyline> polylines = {};

  Set<Marker> _Marker = {};
  // Create the polylines for showing the route between two places

  _createPolylines(
      double startLatitude,
      double startLongitude,
      double destinationLatitude,
      double destinationLongitude,
      ) async {
    // Initializing PolylinePoints
    polylinePoints = PolylinePoints();
    const GOOGLE_API_KEY = "AIzaSyD64A3G685GSaaH_XdE83LGIsSvIjSnuSc";
    // Generating the list of coordinates to be used for
    // drawing the polylines
    PolylineResult result = await polylinePoints!.getRouteBetweenCoordinates(
      GOOGLE_API_KEY, // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
    );
    // Adding the coordinates to the list
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        print("adding polyline");
        print(point.latitude);
        print(point.longitude);
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    // Defining an ID
    PolylineId id = PolylineId('poly');

    // Initializing Polyline
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );

    // Adding the polyline to the map
    polylines[id] = polyline;
    setState(() {

    });
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, (){
      if(ModalRoute.of(context)!.settings.arguments == null){
        _Marker = {Marker(position: LatLng(widget.latitude, widget.longitude), markerId: MarkerId(DateTime.now().toString()))};
      }
      else{
        Set<Map<String, dynamic>> data = ModalRoute.of(context)!.settings.arguments as Set<Map<String, dynamic>>;
        print("Maps screen init");
        print(data.length);
        if(data.length > 0){
          int counter = 1;
          data.forEach((iteM) {
            if(counter <= data.length - 1){
              _createPolylines(iteM["Lat"], iteM["Lon"], data.elementAt(counter)["Lat"], data.elementAt(counter)["Lon"]);
              //DataFetcherAndParser.calculateDistance(iteM["Lat"], iteM["Lon"], data.elementAt(counter)["Lat"], data.elementAt(counter)["Lon"]);
              counter++;
            }
            print("location from db");
            print(iteM["Lat"]);
            print(iteM["Lon"]);
            _Marker.add(Marker(
                position: LatLng(iteM["Lat"], iteM["Lon"]),
                markerId: MarkerId(DateTime.now().toString())
            ));
          });
        }
      }
      setState(() {
        print("Markers length");
        print(_Marker.length);

      });

    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your location"),
      ),
      body: GoogleMap(initialCameraPosition: CameraPosition(target: LatLng(widget.latitude, widget.longitude), zoom: 10,),
        myLocationEnabled: true,
        mapType: MapType.normal,
        onMapCreated: (controller){
        _controller.complete(controller);
        },
        /*markers: {Marker(position: LatLng(widget.latitude, widget.longitude), markerId: MarkerId(MapsScreen._id.toString())),
          Marker(position: LatLng(24.943624, 67.047285), markerId: MarkerId((MapsScreen._id + 1).toString()))
        }*/
        markers: _Marker,
        polylines: Set<Polyline>.of(polylines.values),
      ),
    );
  }
}