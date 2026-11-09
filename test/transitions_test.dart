import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_navigation/playx_navigation.dart';

GoRouterState _state(GoRouter router, {String? name}) => GoRouterState(
      router.configuration,
      uri: Uri.parse('/x'),
      matchedLocation: '/x',
      name: name,
      fullPath: '/x',
      pathParameters: const {},
      pageKey: const ValueKey('state-key'),
    );

Page<void> _build(
  PlayxPageTransition transition, {
  PlayxPageConfiguration config = const PlayxPageConfiguration(),
  String? stateName,
}) {
  final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
  return transition.buildPage<void>(
    config: config,
    child: const Text('child'),
    state: _state(router, name: stateName),
  );
}

void main() {
  group('PlayxPageTransition.buildPage', () {
    test('material and cupertino pages', () {
      expect(_build(PlayxPageTransition.material), isA<MaterialPage<void>>());
      expect(_build(PlayxPageTransition.cupertino), isA<CupertinoPage<void>>());
    });

    test('none builds a NoTransitionPage', () {
      final page = _build(PlayxPageTransition.none);
      expect(page, isA<NoTransitionPage<void>>());
    });

    test('fade and custom build CustomTransitionPages', () {
      final fade =
          _build(PlayxPageTransition.fade) as CustomTransitionPage<void>;
      expect(fade.transitionDuration, const Duration(milliseconds: 300));

      final custom = _build(
        PlayxPageTransition.custom,
        config: PlayxPageConfiguration.customTransition(
          transitionsBuilder: (_, __, ___, child) => child,
          transitionDuration: const Duration(milliseconds: 120),
          reverseTransitionDuration: const Duration(milliseconds: 80),
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          barrierLabel: 'close',
        ),
      ) as CustomTransitionPage<void>;
      expect(custom.transitionDuration, const Duration(milliseconds: 120));
      expect(
          custom.reverseTransitionDuration, const Duration(milliseconds: 80));
      expect(custom.opaque, isFalse);
      expect(custom.barrierDismissible, isTrue);
      expect(custom.barrierColor, Colors.black54);
      expect(custom.barrierLabel, 'close');
    });

    test('key and name come from the config, then from the state', () {
      final fromState =
          _build(PlayxPageTransition.material, stateName: 'route');
      expect(fromState.key, const ValueKey('state-key'));
      expect(fromState.name, 'route');

      final fromConfig = _build(
        PlayxPageTransition.material,
        stateName: 'route',
        config: const PlayxPageConfiguration(
          key: ValueKey('config-key'),
          name: 'config-name',
          arguments: {'a': 1},
          restorationId: 'restore',
          fullscreenDialog: true,
          maintainState: false,
        ),
      ) as MaterialPage<void>;
      expect(fromConfig.key, const ValueKey('config-key'));
      expect(fromConfig.name, 'config-name');
      expect(fromConfig.arguments, {'a': 1});
      expect(fromConfig.restorationId, 'restore');
      expect(fromConfig.fullscreenDialog, isTrue);
      expect(fromConfig.maintainState, isFalse);
    });

    test('native follows the platform', () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(_build(PlayxPageTransition.native), isA<CupertinoPage<void>>());
      }
      for (final platform in [
        TargetPlatform.android,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(_build(PlayxPageTransition.native), isA<MaterialPage<void>>());
      }
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('PlayxPageConfiguration', () {
    test('defaults', () {
      const config = PlayxPageConfiguration();
      expect(config.transitionDuration, const Duration(milliseconds: 300));
      expect(
          config.reverseTransitionDuration, const Duration(milliseconds: 300));
      expect(config.opaque, isTrue);
      expect(config.maintainState, isTrue);
      expect(config.canPop, isTrue);
      expect(config.fullscreenDialog, isFalse);
      expect(config.barrierDismissible, isFalse);
      expect(config.barrierColor, isNull);
      // The default transition returns the child and the default pop
      // handler does nothing.
      config.onPopInvoked(true, null);
    });

    testWidgets('the default transition just shows the child', (tester) async {
      const config = PlayxPageConfiguration();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => config.transitionsBuilder(
            context,
            const AlwaysStoppedAnimation(1),
            const AlwaysStoppedAnimation(0),
            const Text('child'),
          ),
        ),
      ));
      expect(find.text('child'), findsOneWidget);
    });
  });

  group('transitions in a router', () {
    Future<GoRouter> pump(
      WidgetTester tester,
      PlayxPageTransition transition, {
      PlayxPageConfiguration config = const PlayxPageConfiguration(),
    }) async {
      final router = GoRouter(routes: [
        PlayxRoute(path: '/', builder: (_, __) => const Text('home')),
        PlayxRoute(
          path: '/next',
          transition: transition,
          pageConfiguration: config,
          builder: (_, __) => const Text('next'),
        ),
      ]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('none shows the page instantly', (tester) async {
      final router = await pump(tester, PlayxPageTransition.none);
      unawaited(router.push('/next'));
      await tester.pump();
      await tester.pump();
      expect(find.text('next'), findsOneWidget);
    });

    testWidgets('fade fades the page in over the configured duration',
        (tester) async {
      final router = await pump(tester, PlayxPageTransition.fade);
      unawaited(router.push('/next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.descendant(
          of: find.ancestor(
              of: find.text('next'), matching: find.byType(FadeTransition)),
          matching: find.text('next'),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(find.text('next'), findsOneWidget);
    });

    testWidgets('custom uses the transitions builder', (tester) async {
      var built = 0;
      final router = await pump(
        tester,
        PlayxPageTransition.custom,
        config: PlayxPageConfiguration.customTransition(
          transitionsBuilder: (_, animation, __, child) {
            built++;
            return ScaleTransition(scale: animation, child: child);
          },
        ),
      );
      unawaited(router.push('/next'));
      await tester.pumpAndSettle();
      expect(built, greaterThan(0));
      expect(find.text('next'), findsOneWidget);
    });

    testWidgets('material, cupertino and native pages navigate and pop',
        (tester) async {
      for (final transition in [
        PlayxPageTransition.material,
        PlayxPageTransition.cupertino,
        PlayxPageTransition.native,
      ]) {
        final router = await pump(tester, transition);
        unawaited(router.push('/next'));
        await tester.pumpAndSettle();
        expect(find.text('next'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.text('next'), findsNothing);
      }
    });
  });

  group('PlayxShellBranch', () {
    testWidgets('.routes builds a branch with several routes', (tester) async {
      late StatefulNavigationShell shell;
      final router = GoRouter(initialLocation: '/a', routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, s) {
            shell = s;
            return s;
          },
          branches: [
            PlayxShellBranch.routes(routes: [
              PlayxRoute(path: '/a', builder: (_, __) => const Text('a')),
              PlayxRoute(path: '/b', builder: (_, __) => const Text('b')),
            ]),
            PlayxShellBranch(
              path: '/c',
              builder: (_, __) => const Text('c'),
            ),
          ],
        ),
      ]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('a'), findsOneWidget);
      shell.goBranch(1);
      await tester.pumpAndSettle();
      expect(find.text('c'), findsOneWidget);
    });
  });
}
