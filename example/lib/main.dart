import 'package:flutter/material.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation_example/navigation/pages.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final router = AppPages.router;

  @override
  Widget build(BuildContext context) {
    return PlayxNavigationBuilder(
        router: router,
        builder: (context) {
          return MaterialApp.router(
            title: 'Playx',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            routerDelegate: router.routerDelegate,
            routeInformationParser: router.routeInformationParser,
            routeInformationProvider: router.routeInformationProvider,
            backButtonDispatcher: router.backButtonDispatcher,
          );
        });
  }
}
