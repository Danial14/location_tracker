import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:sc_location_tracker/screens/user_profile_screen.dart';
class DataFetcherAndParser{
  static Future<Set<Map<String, dynamic>>> fetchAndParseData(String eMail) async{
    Set<Map<String, dynamic>> parsedData = {};
    try {
      final response = await http.get(Uri.http("157.90.5.174:1251", "/ords/pocgps/gps/gptrnmve", {
        "mveobjid" : eMail
      }), headers: <String, String>{
        HttpHeaders.contentTypeHeader: "application/json"
      });
      var convertedResponse = json.decode(response.body) as Map<String,
          dynamic>;
      List iteMs = convertedResponse["items"];
      iteMs.forEach((iteM) {
        print("fetching eMail : ${iteM["mveobjid"]}");
        parsedData.add({"Lat": iteM["gpslat"], "Lon": iteM["gpslon"]});
      });
      print("parsedDataSize : ${parsedData.length}");
    }
    catch(ex){
      print(ex.toString());
    }
    return parsedData;
  }
  static Future<double> calculateDistance(double originLatitude, double originLongitude, double destinationLatitude, double destinationLongitude) async{
    print("distance response");
    final response = await http.get(Uri.parse("https://maps.googleapis.com/maps/api/distancematrix/json?destinations=$destinationLatitude%2C$destinationLongitude&origins=$originLatitude%2C$originLongitude&key=AIzaSyD64A3G685GSaaH_XdE83LGIsSvIjSnuSc"));
   var convertedResponse = json.decode(response.body) as Map<String, dynamic>;
   print(convertedResponse.toString());
   String unit = convertedResponse["rows"][0]["elements"][0]["distance"]["text"].split(" ")[1];
   double distanceInMeters = double.parse(convertedResponse["rows"][0]["elements"][0]["distance"]["text"].split(" ")[0]);
   print("unit: $unit");
   if(unit != "m"){
     distanceInMeters = distanceInMeters * 1000;
   }
   print("distance in Meters : $distanceInMeters");
   return distanceInMeters;
  }
  static Future<Map<String, double>?> fetchAndParseLastUpdatedRecord(String eMail) async{
    try {
      final response = await http.get(Uri.parse(
          "http://157.90.5.174:1251/ords/pocgps/gps/gptrnmve?mveobjid=${eMail
              .toUpperCase()}"));
      var convertedResponse = json.decode(response.body) as Map<String,
          dynamic>;
      List iteMs = convertedResponse["items"];
      for (int i = 0; i < iteMs.length; i++) {
        DateTime dateOne = DateTime.parse(iteMs[i]["instime"]);
        for (int j = i + 1; j < iteMs.length; j++) {
          DateTime dateTwo = DateTime.parse(iteMs[j]["instime"]);
          if (dateOne.isAfter(dateTwo) && j == iteMs.length - 1) {
            print("Datetime one : ${dateOne.toString()}");
            print("Datetime two : ${dateTwo.toString()}");
            return {"Lat": iteMs[i]["gpslat"], "Lon": iteMs[i]["gpslon"]};
          }
        }
        if (i == iteMs.length - 1) {
          return {"Lat": iteMs[i]["gpslat"], "Lon": iteMs[i]["gpslon"]};
        }
      }
    }
    catch(err){
      print("error getting last record");
      print(err);
    }
    return null;
    }
  }