

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      theme:ThemeData(
        primaryColor: const Color.fromARGB(255, 9, 90, 157),
      ),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text("Optiscore"),
        
      ),
      body: SafeArea(child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children:[ Text("optiscore",style: TextStyle(
            color: const Color.fromARGB(255, 3, 51, 91),
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),),
          IconButton(onPressed: (){}, icon: Icon(
            Icons.camera_alt
          ))
          ]
        
        ),
      )),
    );
  }
}