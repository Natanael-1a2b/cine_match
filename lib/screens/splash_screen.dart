import 'package:flutter/material.dart';
import 'package:cinematch/screens/login_screen.dart';
import 'package:cinematch/screens/home_screen.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simple splash
    Timer(Duration(seconds: 2), () {
      // Aquí puedes mostrar login o home
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Hero(
          tag: 'logo',
          child: Text('CineMatch', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        ),
      ),
    );
  }
}