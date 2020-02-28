import 'package:flutter/material.dart';
import 'package:flutter_learning/screens/home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "PriorityKeeper",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue
        
        // orange: #F79420
        // blue: #00223D
      ),
      home: Home(),
    );
  }
}