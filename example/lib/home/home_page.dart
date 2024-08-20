import 'package:flutter/material.dart';
import 'package:playx_navigation/playx_navigation.dart';

import '../main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
}
