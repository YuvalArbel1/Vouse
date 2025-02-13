import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// A simple placeholder for your main dashboard or home screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void initState() {
    init();
  }

  Future<void> init() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: const Center(
        child: Text(
          'Welcome! You are logged in.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
