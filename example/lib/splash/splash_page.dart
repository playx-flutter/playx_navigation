import 'package:flutter/material.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation_example/navigation/routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // print('PlayxNavigation: Splash onInit');
    Future.delayed(const Duration(seconds: 5), () {
      PlayxNavigation.offAllNamed(Routes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Splash'),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    // print('PlayxNavigation: Splash onDispose');
  }
}
