import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_navigation/playx_navigation.dart';

final List<String> log = [];

class TestBinding extends PlayxBinding {
  TestBinding(this.name);
  final String name;
  int initCalls = 0;

  @override
  Future<void> onInitApp() async => initCalls++;

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async =>
      log.add('$name:enter');

  @override
  Future<void> onHidden(BuildContext context) async => log.add('$name:hidden');

  @override
  Future<void> onReEnter(
          BuildContext context, GoRouterState? state, bool popped) async =>
      log.add('$name:reEnter${popped ? '(popped)' : ''}');

  @override
  Future<void> onExit(BuildContext context) async => log.add('$name:exit');
}

late TestBinding home, a, b, c;

GoRouter _router({String initial = '/home'}) {
  home = TestBinding('home');
  a = TestBinding('a');
  b = TestBinding('b');
  c = TestBinding('c');
  Widget page(String t) => Scaffold(body: Text(t));
  return GoRouter(initialLocation: initial, routes: [
    PlayxRoute(
      path: '/home',
      name: 'home',
      binding: home,
      builder: (_, __) => page('home'),
    ),
    PlayxRoute(
      path: '/a/:id',
      name: 'a',
      binding: a,
      builder: (_, s) => page('a:${s.pathParameters['id']}'
          ':${s.uri.queryParameters['q']}:${s.extra}'),
    ),
    PlayxRoute(
      path: '/b',
      name: 'b',
      binding: b,
      builder: (_, s) => page('b:${s.extra}'),
    ),
    PlayxRoute(
      path: '/c',
      name: 'c',
      binding: c,
      builder: (_, __) => page('c'),
    ),
  ]);
}

Future<GoRouter> _pump(WidgetTester tester, {String initial = '/home'}) async {
  final router = _router(initial: initial);
  await tester.pumpWidget(PlayxNavigationBuilder(
    router: router,
    builder: (_) => MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  log.clear();
  return router;
}

String? get _location => PlayxNavigation.currentState?.matchedLocation;

void main() {
  setUp(log.clear);

  group('push: to / toNamed', () {
    testWidgets('to pushes a location with extra and returns the result',
        (tester) async {
      await _pump(tester);
      final result = PlayxNavigation.to<String>('/b', extra: 'payload');
      await tester.pumpAndSettle();
      expect(find.text('b:payload'), findsOneWidget);
      expect(log, ['home:hidden', 'b:enter']);

      PlayxNavigation.pop('done');
      await tester.pumpAndSettle();
      expect(await result, 'done');
      expect(log.last, 'b:exit');
      expect(log, contains('home:reEnter(popped)'));
    });

    testWidgets('toNamed with path, query parameters and extra',
        (tester) async {
      await _pump(tester);
      unawaited(PlayxNavigation.toNamed('a',
          pathParameters: {'id': '7'},
          queryParameters: {'q': 'x'},
          extra: 'e'));
      await tester.pumpAndSettle();
      expect(find.text('a:7:x:e'), findsOneWidget);
      expect(PlayxNavigation.canPop(), isTrue);
    });

    testWidgets('namedLocation builds the location', (tester) async {
      await _pump(tester);
      expect(
        PlayxNavigation.namedLocation('a',
            pathParameters: {'id': '7'}, queryParameters: {'q': 'x'}),
        '/a/7?q=x',
      );
    });
  });

  group('go: offAll / offAllNamed', () {
    testWidgets('offAll replaces the whole stack', (tester) async {
      await _pump(tester);
      unawaited(PlayxNavigation.to('/b'));
      await tester.pumpAndSettle();
      log.clear();

      await PlayxNavigation.offAll('/c');
      await tester.pumpAndSettle();
      expect(_location, '/c');
      expect(PlayxNavigation.canPop(), isFalse);
      expect(log.where((e) => e.endsWith(':exit')),
          unorderedEquals(['home:exit', 'b:exit']));
      expect(log, contains('c:enter'));
    });

    testWidgets('offAllNamed goes to a named route with parameters',
        (tester) async {
      await _pump(tester);
      await PlayxNavigation.offAllNamed('a',
          pathParameters: {'id': '3'}, extra: 'z');
      await tester.pumpAndSettle();
      expect(find.text('a:3:null:z'), findsOneWidget);
      expect(PlayxNavigation.canPop(), isFalse);
    });
  });

  group('replace: offAndTo / offAndToNamed', () {
    testWidgets('offAndTo replaces the top page only', (tester) async {
      await _pump(tester);
      unawaited(PlayxNavigation.to('/b'));
      await tester.pumpAndSettle();
      log.clear();

      unawaited(PlayxNavigation.offAndTo('/c', extra: 'x'));
      await tester.pumpAndSettle();
      expect(find.text('c'), findsOneWidget);
      // b leaves, c enters; home (below) is untouched and not re-entered.
      expect(log, containsAll(['b:exit', 'c:enter']));
      expect(log.any((e) => e.startsWith('home:')), isFalse);

      // Popping c reveals home: b is gone for good.
      PlayxNavigation.pop();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(log, contains('home:reEnter(popped)'));
    });

    testWidgets('offAndToNamed replaces the top page with parameters',
        (tester) async {
      await _pump(tester);
      unawaited(PlayxNavigation.to('/b'));
      await tester.pumpAndSettle();
      log.clear();

      unawaited(PlayxNavigation.offAndToNamed('a',
          pathParameters: {'id': '9'},
          queryParameters: {'q': 'k'},
          extra: 'e'));
      await tester.pumpAndSettle();
      expect(find.text('a:9:k:e'), findsOneWidget);
      expect(log, containsAll(['b:exit', 'a:enter']));
      expect(log.any((e) => e.startsWith('home:')), isFalse);
    });

    testWidgets(
        'awaiting offAndTo does not hang: it returns the result of '
        'the replacing page when popped', (tester) async {
      await _pump(tester);
      unawaited(PlayxNavigation.to('/b'));
      await tester.pumpAndSettle();

      var completed = false;
      String? result;
      final future = PlayxNavigation.offAndTo<String>('/c').then((value) {
        completed = true;
        result = value;
      });
      await tester.pumpAndSettle();
      // Like go_router's replace, the future completes when the new page pops.
      expect(completed, isFalse);

      PlayxNavigation.pop('from-c');
      await tester.pumpAndSettle();
      await future;
      expect(completed, isTrue);
      expect(result, 'from-c');
    });
  });

  group('pop', () {
    testWidgets('pop, maybePop and canPop', (tester) async {
      await _pump(tester);
      expect(PlayxNavigation.canPop(), isFalse);
      expect(PlayxNavigation.maybePop(), isFalse);

      unawaited(PlayxNavigation.to('/b'));
      await tester.pumpAndSettle();
      expect(PlayxNavigation.canPop(), isTrue);
      expect(PlayxNavigation.maybePop(), isTrue);
      await tester.pumpAndSettle();
      expect(_location, '/home');
    });

    testWidgets('popOrGo and popOrGoNamed', (tester) async {
      await _pump(tester, initial: '/b');
      expect(PlayxNavigation.canPop(), isFalse);
      PlayxNavigation.popOrGo('/c');
      await tester.pumpAndSettle();
      expect(_location, '/c');

      unawaited(PlayxNavigation.to('/b'));
      await tester.pumpAndSettle();
      PlayxNavigation.popOrGoNamed('home'); // pops, ignores the fallback
      await tester.pumpAndSettle();
      expect(_location, '/c');

      PlayxNavigation.popOrGoNamed('a', pathParameters: {'id': '1'});
      await tester.pumpAndSettle();
      expect(_location, '/a/1');
    });
  });

  group('state and listeners', () {
    testWidgets('currentRoute, currentRouteName and currentState',
        (tester) async {
      await _pump(tester);
      expect(PlayxNavigation.currentRouteName, 'home');
      expect(PlayxNavigation.currentRoute?.path, '/home');
      unawaited(PlayxNavigation.toNamed('a', pathParameters: {'id': '4'}));
      await tester.pumpAndSettle();
      expect(PlayxNavigation.currentRouteName, 'a');
      expect(PlayxNavigation.currentState?.pathParameters, {'id': '4'});
    });

    testWidgets('route change listeners', (tester) async {
      await _pump(tester);
      var calls = 0;
      void listener() => calls++;
      PlayxNavigation.addRouteChangeListener(listener);
      unawaited(PlayxNavigation.to('/b'));
      await tester.pumpAndSettle();
      expect(calls, greaterThan(0));

      PlayxNavigation.removeRouteChangeListener(listener);
      final before = calls;
      PlayxNavigation.pop();
      await tester.pumpAndSettle();
      expect(calls, before);
    });

    testWidgets('navigationContext and rootNavigatorKey', (tester) async {
      await _pump(tester);
      expect(PlayxNavigation.navigationContext, isNotNull);
      expect(PlayxNavigation.rootNavigatorKey.currentState, isNotNull);
      expect(PlayxNavigation.goRouter, isA<GoRouter>());
      expect(PlayxNavigation.hasRouter, isTrue);
    });

    testWidgets('refresh keeps pages and lifecycle', (tester) async {
      await _pump(tester);
      PlayxNavigation.refresh();
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('restore re-applies a saved match list', (tester) async {
      await _pump(tester);
      final saved =
          PlayxNavigation.goRouter.routerDelegate.currentConfiguration;
      PlayxNavigation.offAll('/c');
      await tester.pumpAndSettle();
      expect(_location, '/c');

      PlayxNavigation.restore(saved);
      await tester.pumpAndSettle();
      expect(_location, '/home');
    });
  });

  group('shell branches', () {
    testWidgets('goToBranch switches branches', (tester) async {
      late StatefulNavigationShell shell;
      final router = GoRouter(initialLocation: '/one', routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, s) {
            shell = s;
            return s;
          },
          branches: [
            PlayxShellBranch(
              path: '/one',
              binding: TestBinding('one'),
              builder: (_, __) => const Text('one'),
            ),
            PlayxShellBranch(
              path: '/two',
              binding: TestBinding('two'),
              builder: (_, __) => const Text('two'),
            ),
          ],
        ),
      ]);
      await tester.pumpWidget(PlayxNavigationBuilder(
        router: router,
        builder: (_) => MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      log.clear();

      PlayxNavigation.goToBranch(index: 1, navigationShell: shell);
      await tester.pumpAndSettle();
      expect(_location, '/two');
      expect(log, ['one:hidden', 'two:enter']);

      // Same branch again resets it to its initial location.
      PlayxNavigation.goToBranch(index: 1, navigationShell: shell);
      await tester.pumpAndSettle();
      expect(_location, '/two');
    });
  });

  group('boot and bindings', () {
    testWidgets('bindings are discovered, findBinding works', (tester) async {
      await _pump(tester);
      expect(PlayxNavigation.bindings, containsAll([home, a, b, c]));
      expect(PlayxNavigation.findBinding<TestBinding>(), isA<TestBinding>());
      expect(PlayxNavigation.findBindingOrNull<TestBinding>(), isNotNull);
      expect(PlayxNavigation.findBindingOrNull<_Missing>(), isNull);
      expect(() => PlayxNavigation.findBinding<_Missing>(), throwsStateError);
      expect(() => PlayxNavigation.bindings.add(home), throwsUnsupportedError);
    });

    testWidgets('onInitApp runs once per binding and isInitialized flips',
        (tester) async {
      await _pump(tester);
      expect(PlayxNavigation.isInitialized, isTrue);
      await PlayxNavigation.ensureInitialized;
      expect([home, a, b, c].map((x) => x.initCalls), [1, 1, 1, 1]);
    });

    testWidgets('boot can run again with a new router', (tester) async {
      await _pump(tester);
      final second = _router();
      await PlayxNavigation.boot(router: second);
      expect(PlayxNavigation.goRouter, same(second));
      expect(home.initCalls, 1);
    });

    testWidgets('a failing onInitApp rejects ensureInitialized',
        (tester) async {
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: _FailingInit(),
          builder: (_, __) => const SizedBox(),
        ),
      ]);
      await expectLater(
        PlayxNavigation.boot(router: router),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        PlayxNavigation.ensureInitialized,
        throwsA(isA<StateError>()),
      );
      expect(PlayxNavigation.isInitialized, isFalse);
    });

    test('setupWeb is a no-op outside the web', () {
      PlayxNavigation.setupWeb();
      expect(GoRouter.optionURLReflectsImperativeAPIs, isFalse);
    });
  });
}

class _Missing extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {}
}

class _FailingInit extends PlayxBinding {
  @override
  Future<void> onInitApp() async => throw StateError('init failed');

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {}
}
