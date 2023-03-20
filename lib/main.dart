import 'package:flutter/material.dart';
import 'package:ggmap_flutter/gg/googlemap.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'gg/addr_gg.dart';
import 'gg/text.dart';
import 'gg/text2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GGmap(),
    );
  }
}
