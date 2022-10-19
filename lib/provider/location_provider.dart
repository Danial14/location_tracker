import 'package:flutter/material.dart';

class Location{
  double latitude;
  double longitude;
  Location({required this.latitude, required this.longitude});
}
class Locations with ChangeNotifier{
  late List<Location> locations;
  Locations(){
    locations = [];
  }
  void addLocation(Location location){
    locations.add(location);
    notifyListeners();
  }
  List<Location> get getLocations{
    return locations;
  }
}