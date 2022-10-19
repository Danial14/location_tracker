import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class CoordinatesForm extends StatefulWidget{
  static const String routeName = "/coordinatesForM";
  @override
  State<CoordinatesForm> createState() {
    return CoordinatesFormState();
  }
}
class CoordinatesFormState extends State<CoordinatesForm>{
  var _forM = GlobalKey<FormState>();
  String _lat = "";
  String _lng = "";
  final FocusNode longitudeFocus = FocusNode();
  LatLng _location = LatLng(0.0, 0.0);
  String? address;
  Future<void> _save() async{
    bool isValid = _forM.currentState!.validate();
    if(!isValid){
      return;
    }
    _forM.currentState!.save();
    try{
      const GOOGLE_API_KEY = "AIzaSyD64A3G685GSaaH_XdE83LGIsSvIjSnuSc";
      final response = await http.get(Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?latlng=${_location.latitude},${_location.longitude}&location_type=ROOFTOP&result_type=street_address&key=$GOOGLE_API_KEY"));
      setState(() {
        address = json.decode(response.body)["results"][0]["formatted_address"] as String;
        print("address: ${address}");
      });
    }
    catch(ex){
      print("Map error");
      print(ex.toString());
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Coordinates"),
      ),
      body: Form(
        key: _forM,
        child: ListView(
          children: <Widget>[
            TextFormField(
              initialValue: _lat,
              keyboardType: TextInputType.number,
              onFieldSubmitted: (value){
                FocusScope.of(context).requestFocus(longitudeFocus);
              },
              validator: (value){
                if(value!.isEmpty){
                  return "Please enter latitude";
                }
              },
              onSaved: (value){
                _location = LatLng(double.parse(value!), _location.longitude);
              },
                decoration: InputDecoration(label: Text("Latitude"))
            ),
            TextFormField(
              initialValue: _lng,
              decoration: InputDecoration(label: Text("Longitude")),
              keyboardType: TextInputType.number,
              validator: (value){
                if(value!.isEmpty){
                  return "Please enter longitude";
                }
              },
              onSaved: (value){
                _location = LatLng(_location.latitude, double.parse(value!));
              },
            ),
            ElevatedButton(onPressed: _save, child: Text("Submit")),
            if(address != null)
              Text(address!)
          ],
        ),
      ),
    );
  }
}