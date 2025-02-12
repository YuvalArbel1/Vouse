import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/util/colors.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    setStatusBarColor(vPrimaryColor, statusBarIconBrightness: Brightness.light);
    await Future.delayed(Duration(seconds: 3));
  }

  @override
  void dispose() {
    setStatusBarColor(Colors.white, statusBarIconBrightness: Brightness.dark);
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: vPrimaryColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/vouse_app_logo.png',
              color: Colors.white,
              fit: BoxFit.cover,
              height: 100,
              width: 100,
            ).center(),
          ],
        ),
      ),
    );
  }
}
