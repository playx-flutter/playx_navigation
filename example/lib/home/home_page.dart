import 'package:flutter/material.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation_example/navigation/routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          children: [
            const Text('Home'),
            ElevatedButton(
              onPressed: () {
                PlayxNavigation.toNamed(Routes.products);
              },
              child: const Text('Products'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // print('PlayxNavigation: Home onInit');
  }

  @override
  void dispose() {
    super.dispose();
    // print('PlayxNavigation: Home onDispose');
  }
}
