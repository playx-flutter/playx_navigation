import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_navigation/playx_navigation.dart';

final List<String> log = [];

class _B extends PlayxBinding {
  _B(this.name);
  final String name;

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async =>
      log.add('$name:enter');

  @override
  Future<void> onExit(BuildContext context) async => log.add('$name:exit');
}

Widget _page(String text) => Scaffold(
      appBar: AppBar(
        leading: PlayxNavigation.canGoBack ? const PlayxBackButton() : null,
        title: Text(text),
      ),
    );

PlayxRoute _route(
  String path,
  String text, {
  List<RouteBase> routes = const [],
  PlayxParentLocation? parentLocation,
}) =>
    PlayxRoute(
      path: path,
      binding: _B(text),
      parentLocation: parentLocation,
      builder: (_, __) => _page(text),
      routes: routes,
    );

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(PlayxNavigationBuilder(
    router: router,
    builder: (_) => MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  log.clear();
}

Future<void> _back(WidgetTester tester, {bool expected = true}) async {
  expect(PlayxNavigation.back(), expected);
  await tester.pumpAndSettle();
}

void main() {
  setUp(log.clear);

  testWidgets('nested details: back pops to jobs as before', (tester) async {
    final router = GoRouter(initialLocation: '/jobs', routes: [
      _route('/jobs', 'jobs', routes: [_route(':id', 'details')]),
    ]);
    await _pump(tester, router);
    unawaited(router.push('/jobs/5'));
    await tester.pumpAndSettle();
    log.clear();

    expect(PlayxNavigation.canPop(), isTrue);
    await _back(tester);
    expect(find.text('jobs'), findsOneWidget);
    expect(log, ['details:exit']);
  });

  testWidgets('sibling routes, opened directly: back goes up the path',
      (tester) async {
    // Web refresh / typed URL on /jobs/5/edit with flat (non-nested) routes:
    // nothing to pop.
    final router = GoRouter(initialLocation: '/jobs/5/edit', routes: [
      _route('/jobs', 'jobs'),
      _route('/jobs/:id', 'details'),
      _route('/jobs/:id/edit', 'edit'),
    ]);
    await _pump(tester, router);
    expect(PlayxNavigation.canPop(), isFalse);
    expect(PlayxNavigation.parentLocation, '/jobs/5');

    await _back(tester);
    expect(find.text('details'), findsOneWidget);
    expect(log, ['details:enter', 'edit:exit']);
    log.clear();

    await _back(tester);
    expect(find.text('jobs'), findsOneWidget);
    expect(log, ['jobs:enter', 'details:exit']);

    // The jobs list is a root: no parent, no back button.
    expect(PlayxNavigation.canGoBack, isFalse);
    expect(find.byType(BackButton), findsNothing);
    await _back(tester, expected: false);
  });

  testWidgets('explicit parentLocation when the path has no parent route',
      (tester) async {
    final router = GoRouter(initialLocation: '/job/5', routes: [
      _route('/jobs', 'jobs'),
      _route('/job/:id', 'details', parentLocation: (_) => '/jobs'),
    ]);
    await _pump(tester, router);
    expect(PlayxNavigation.parentLocation, '/jobs');

    await _back(tester);
    expect(find.text('jobs'), findsOneWidget);
    expect(log, ['jobs:enter', 'details:exit']);
  });

  testWidgets('parentLocation can use path parameters', (tester) async {
    final router = GoRouter(initialLocation: '/edit-job/5', routes: [
      _route('/jobs/:id', 'details'),
      _route('/edit-job/:id', 'edit',
          parentLocation: (state) => '/jobs/${state.pathParameters['id']}'),
    ]);
    await _pump(tester, router);
    expect(PlayxNavigation.parentLocation, '/jobs/5');
  });

  testWidgets('pop wins over parentLocation when there is a stack',
      (tester) async {
    final router = GoRouter(initialLocation: '/other', routes: [
      _route('/other', 'other'),
      _route('/jobs', 'jobs'),
      _route('/job/:id', 'details', parentLocation: (_) => '/jobs'),
    ]);
    await _pump(tester, router);
    unawaited(router.push('/job/5'));
    await tester.pumpAndSettle();

    await _back(tester);
    expect(find.text('other'), findsOneWidget);
  });

  testWidgets('no parent and nothing to pop: back does nothing',
      (tester) async {
    final router = GoRouter(initialLocation: '/job/5', routes: [
      _route('/', 'home'),
      _route('/job/:id', 'details'),
    ]);
    await _pump(tester, router);
    // The automatic parent never falls back to "/".
    expect(PlayxNavigation.parentLocation, isNull);
    expect(PlayxNavigation.canGoBack, isFalse);
    await _back(tester, expected: false);
    expect(find.text('details'), findsOneWidget);
  });

  testWidgets('shell tab root has no parent; its details goes up to it',
      (tester) async {
    final router = GoRouter(initialLocation: '/jobs/5', routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => shell,
        branches: [
          StatefulShellBranch(routes: [_route('/jobs', 'jobs')]),
          StatefulShellBranch(routes: [_route('/settings', 'settings')]),
        ],
      ),
      _route('/jobs/:id', 'details'),
    ]);
    await _pump(tester, router);
    expect(PlayxNavigation.canPop(), isFalse);

    await _back(tester);
    expect(find.text('jobs'), findsOneWidget);
    expect(PlayxNavigation.canGoBack, isFalse);
  });

  testWidgets('PlayxBackButton goes back and runs onPressed first',
      (tester) async {
    var pressed = 0;
    final router = GoRouter(initialLocation: '/jobs/5', routes: [
      _route('/jobs', 'jobs'),
      PlayxRoute(
        path: '/jobs/:id',
        builder: (_, __) => Scaffold(
          appBar: AppBar(
            leading: PlayxBackButton(onPressed: () => pressed++),
            title: const Text('details'),
          ),
        ),
      ),
    ]);
    await _pump(tester, router);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(pressed, 1);
    expect(find.text('jobs'), findsOneWidget);
  });
}
