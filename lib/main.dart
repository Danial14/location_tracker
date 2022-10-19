
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sc_location_tracker/firebase_options.dart';
import 'package:sc_location_tracker/provider/location_provider.dart';
import 'package:sc_location_tracker/screens/MapsScreen.dart';
import 'package:sc_location_tracker/screens/auth_screen.dart';
import 'package:sc_location_tracker/screens/coordinates_forM.dart';
import 'package:sc_location_tracker/screens/user_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseApp = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    print("inside Main");
    print(firebaseApp.options.appId);
    print(firebaseApp.options.iosClientId);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: [
      ChangeNotifierProvider(create: (ctx){
        return Locations();
      })
    ],child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: AuthScreen(),
      routes: {
        AuthScreen.routeName : (ctx){
          return AuthScreen();
        },
        UserProfile.ROUTENAME : (ctx){
          return UserProfile();
        },
        CoordinatesForm.routeName : (ctx){
          return CoordinatesForm();
        },
        MapsScreen.routeNaMe : (ctx){
          return MapsScreen(latitude: 24.8693829, longitude: 67.0845184);
        }
      },
    ),
    );


  }
}
