import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:location/location.dart' as Loc;
import 'package:sc_location_tracker/helper/data_parser.dart';
import 'package:sc_location_tracker/provider/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:sc_location_tracker/screens/MapsScreen.dart';
import 'package:sc_location_tracker/screens/auth_screen.dart';
import 'package:sc_location_tracker/screens/coordinates_forM.dart';

class UserProfile extends StatefulWidget{
  static final String ROUTENAME = "/user_profile";
  static Map<String, dynamic>? lastRecord;
  @override
  State<StatefulWidget> createState() {
    return UserProfileState();
  }
}
class UserProfileState extends State<UserProfile>{
 static String? _eMail;
  Timer? _tiMer, _tiMerTwo;
  static bool _locationAccess = false;
  static void setLocationAccess(bool locationAccess){
    UserProfileState._locationAccess = locationAccess;
  }
  Future<void> checkForLocationPerMission() async{
    if(!UserProfileState._locationAccess){
      Loc.Location location = new Loc.Location();
      bool _serviceEnabled;
      Loc.PermissionStatus _permissionGranted;

      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          return;
        }
      }

      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == Loc.PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != Loc.PermissionStatus.granted) {
          return;
        }
      }
      await location.enableBackgroundMode(enable: true);
      setLocationAccess(true);
    }
  }
  Future<void> getCurrentLocation() async{
    checkForLocationPerMission();
    Loc.LocationData _locationData;
    Loc.Location location = new Loc.Location();
    _locationData = await location.getLocation();
    print(_locationData.latitude);
    print(_locationData.longitude);
    await postToDatabase(_locationData);
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tiMer = Timer.periodic(Duration(seconds: 40), (timer) {
      getCurrentLocation();
    });
    if(_eMail == null) {
      Future.delayed(Duration.zero, () {
        _eMail = ModalRoute
            .of(context)!
            .settings
            .arguments as String;
        print("eMail : $_eMail");
      });
    }
    _tiMerTwo = Timer.periodic(Duration(minutes: 2), (timer) async {
      print("auto signout");
      DateTime dateTiMe = DateTime.now();
      print(dateTiMe.hour);
      if(dateTiMe.hour == 17){
        await Authentication.signOut();
        await http.post(Uri.parse("http://157.90.5.174:1251/ords/pocgps/gps/gptrnmve"), headers: <String, String>{
          "Content-Type" : "application/json"
        }, body: json.encode({
          "gpslat" : UserProfile.lastRecord!["Lat"],
          "gpslon" : UserProfile.lastRecord!["Lon"],
          "mveobjid" : _eMail,
          "gpsadr" : UserProfile.lastRecord!["address"]
        }));
        UserProfile.lastRecord = null;
        Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
        _tiMer!.cancel();
        timer.cancel();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    /*void logout(){
      Authentication.signOut();
      Navigator.of(context).pushReplacementNamed("/");
    }*/
    List<Location> locations = Provider.of<Locations>(context, listen: false).locations;
    return Scaffold(appBar : AppBar(title: Text("Hello"),actions: <Widget>[PopupMenuButton(itemBuilder: (ctx){
      return <PopupMenuEntry>[
        PopupMenuItem(child: Text("Logout"),
          onTap: () async{
          await Authentication.signOut();
          print("signout");
          await http.post(Uri.parse("http://157.90.5.174:1251/ords/pocgps/gps/gptrnmve"), headers: <String, String>{
            "Content-Type" : "application/json"
          }, body: json.encode({
            "gpslat" : UserProfile.lastRecord!["Lat"],
            "gpslon" : UserProfile.lastRecord!["Lon"],
            "mveobjid" : _eMail,
            "gpsadr" : UserProfile.lastRecord!["address"]
          }));
          UserProfile.lastRecord = null;
          _tiMer!.cancel();
          _tiMerTwo!.cancel();
          Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
        },),
        PopupMenuItem(child: Text("Current location"), onTap: (){
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            Navigator.of(context).push(MaterialPageRoute(builder: (ctx){
              var locations = Provider.of<Locations>(context, listen: false).getLocations;
              return MapsScreen(latitude: locations[locations.length - 1].latitude, longitude: locations[locations.length - 1].longitude);
            }));
          });
        },),
        PopupMenuItem(child: Text("Custom location"),
        onTap: (){
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            Navigator.of(context).pushNamed(CoordinatesForm.routeName);
          });
        },
        ),
        PopupMenuItem(child: Text("Show all location"),
        onTap: () async{
          Set<Map<String, dynamic>> data = await DataFetcherAndParser.fetchAndParseData(_eMail!) as Set<Map<String, dynamic>>;
          /*WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            Navigator.of(context).pushNamed(MapsScreen.routeNaMe, arguments: data);
          });*/
          Navigator.of(context).pushNamed(MapsScreen.routeNaMe, arguments: data);
        },
        )
      ];
    }),
    ],),
        body: Consumer<Locations>(
      builder: (ctx, location, ch){
        return ListView.builder(itemBuilder: (ctx, ind){
          return Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)
              ),
              child: Column(
            children: <Widget>[
              Text("Latitude ${location.getLocations[ind].latitude}"),
              SizedBox(
                height: 10,
              ),
              Text("Longitude ${location.getLocations[ind].longitude}"),
            ],
          ));
        },
        itemCount: locations.length,
        );
      },
    ));
  }
  Future<void> postToDatabase(Loc.LocationData locationData) async{
    try{
      if(UserProfile.lastRecord == null){
        final response = await http.get(Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?latlng=${locationData.latitude},${locationData.longitude}&location_type=ROOFTOP&result_type=street_address&key=AIzaSyD64A3G685GSaaH_XdE83LGIsSvIjSnuSc"));
        final address = json.decode(response.body)["results"][0]["formatted_address"] as String;
        await http.post(
            Uri.parse("http://157.90.5.174:1251/ords/pocgps/gps/gptrnmve"),
            body: json.encode({
              "gpslat" : locationData.latitude,
              "gpslon" : locationData.longitude,
              "mveobjid" : _eMail,
              "gpsadr" : address
            }),
            headers: <String, String>{
              'Content-Type': 'application/json'
            });
        UserProfile.lastRecord = {
          "Lat": locationData.latitude!,
          "Lon": locationData.longitude!,
          "address": address
        };
        Provider.of<Locations>(context, listen: false).addLocation(Location(
            latitude: locationData.latitude!,
            longitude: locationData.longitude!));
      }
      else{
      double distanceInMeters = await DataFetcherAndParser.calculateDistance(UserProfile.lastRecord!["Lat"]!, UserProfile.lastRecord!["Lon"]!, locationData.latitude!, locationData.longitude!);
      if(distanceInMeters > 100) {
        final response = await http.get(Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?latlng=${locationData.latitude},${locationData.longitude}&location_type=ROOFTOP&result_type=street_address&key=AIzaSyD64A3G685GSaaH_XdE83LGIsSvIjSnuSc"));
        final address = json.decode(response.body)["results"][0]["formatted_address"] as String;
        String data = json.encode({
          "gpslat" : locationData.latitude,
          "gpslon" : locationData.longitude,
          "mveobjid" : _eMail,
          "gpsadr" : address
        });
        final responseOne = await http.post(
            Uri.parse("http://157.90.5.174:1251/ords/pocgps/gps/gptrnmve"),
            body: data,
            headers: <String, String>{
              'Content-Type': 'application/json'
            });
        print("database post : successfully posted data");
        UserProfile.lastRecord = {
          "Lat": locationData.latitude!,
          "Lon": locationData.longitude!,
          "address": address
        };
        Provider.of<Locations>(context, listen: false).addLocation(Location(
            latitude: locationData.latitude!,
            longitude: locationData.longitude!));
      }

    }
    } on FormatException catch(err){
      print("Format exception db connection!");
      print(err.message);
    }
    catch(err){
      print("post error");
      print(err.toString());
    }
  }
  @override
  void dispose(){
    // TODO: implement dispose
    super.dispose();
    if(_tiMer != null && _tiMerTwo != null){
      _tiMer!.cancel();
      _tiMerTwo!.cancel();
    }
  }

}