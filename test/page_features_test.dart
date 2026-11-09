import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_navigation/playx_navigation.dart';

final List<String> log = [];

/// A binding whose `onEnter` finishes when [gate] completes.
class GatedBinding extends PlayxBinding {
  GatedBinding([this.name = 'g']);
  final String name;
  final Completer<void> gate = Completer<void>();
  bool failHidden = false;
  PlayxScope? scope;

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    scope = PlayxScope.of(context);
    log.add('$name:enter');
    await gate.future;
  }

  @override
  Future<void> onHidden(BuildContext context) async {
    log.add('$name:hidden');
    if (failHidden) throw StateError('hidden failed');
  }

  @override
  Future<void> onReEnter(
    BuildContext context,
    GoRouterState? state,
    bool wasPoppedAndReentered,
  ) async =>
      log.add('$name:reEnter');

  @override
  Future<void> onExit(BuildContext context) async => log.add('$name:exit');
}

Future<void> _pump(
  WidgetTester tester,
  GoRouter router, {
  PlayxPageConfig? config,
}) async {
  await tester.pumpWidget(PlayxNavigationBuilder(
    router: router,
    config: config,
    builder: (_) => MaterialApp.router(routerConfig: router),
  ));
  await tester.pump();
  await tester.pump();
}

GoRouter _single(PlayxRoute route) =>
    GoRouter(routes: [route], initialLocation: route.path);

void main() {
  setUp(log.clear);

  group('loading, shell and init builders', () {
    testWidgets('blocking default: SizedBox, then route/global loading widgets',
        (tester) async {
      final binding = GatedBinding();
      await _pump(
        tester,
        _single(PlayxRoute(
          path: '/',
          binding: binding,
          builder: (_, __) => const Text('content'),
        )),
      );
      expect(find.text('content'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);

      binding.gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('route loadingWidget beats the global one', (tester) async {
      final binding = GatedBinding();
      await _pump(
        tester,
        _single(PlayxRoute(
          path: '/',
          binding: binding,
          loadingWidget: const Text('route-loading'),
          builder: (_, __) => const Text('content'),
        )),
        config: const PlayxPageConfig(loadingWidget: Text('global-loading')),
      );
      expect(find.text('route-loading'), findsOneWidget);
      expect(find.text('global-loading'), findsNothing);
    });

    testWidgets('global loadingWidget is used when the route has none',
        (tester) async {
      final binding = GatedBinding();
      await _pump(
        tester,
        _single(PlayxRoute(
          path: '/',
          binding: binding,
          builder: (_, __) => const Text('content'),
        )),
        config: const PlayxPageConfig(loadingWidget: Text('global-loading')),
      );
      expect(find.text('global-loading'), findsOneWidget);
    });

    testWidgets('route shellBuilder renders at once; child follows init',
        (tester) async {
      final binding = GatedBinding();
      await _pump(
        tester,
        _single(PlayxRoute(
          path: '/',
          binding: binding,
          loadingWidget: const Text('loading'),
          shellBuilder: (_, __, isInitialized, child) => Scaffold(
            appBar: AppBar(title: Text('shell:$isInitialized')),
            body: child,
          ),
          builder: (_, __) => const Text('content'),
        )),
      );
      expect(find.text('shell:false'), findsOneWidget);
      expect(find.text('loading'), findsOneWidget);
      expect(find.text('content'), findsNothing);

      binding.gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('shell:true'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('global shellBuilder applies; the route one overrides it',
        (tester) async {
      Widget shell(String name, bool init, Widget child) =>
          Scaffold(appBar: AppBar(title: Text('$name:$init')), body: child);
      final config = PlayxPageConfig(
        shellBuilder: (_, __, init, child) => shell('global', init, child),
      );

      final first = GatedBinding('first');
      await _pump(
        tester,
        _single(PlayxRoute(
          path: '/',
          binding: first,
          builder: (_, __) => const Text('content'),
        )),
        config: config,
      );
      expect(find.text('global:false'), findsOneWidget);

      final second = GatedBinding('second');
      await _pump(
        tester,
        _single(PlayxRoute(
          path: '/',
          binding: second,
          shellBuilder: (_, __, init, child) => shell('route', init, child),
          builder: (_, __) => const Text('content'),
        )),
        config: config,
      );
      expect(find.text('route:false'), findsOneWidget);
    });

    testWidgets('initBuilder gets isInitialized', (tester) async {
      final binding = GatedBinding();
      await _pump(
        tester,
        _single(PlayxRoute(
          path: '/',
          binding: binding,
          initBuilder: (_, __, isInitialized) => Text('init:$isInitialized'),
        )),
      );
      expect(find.text('init:false'), findsOneWidget);
      binding.gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('init:true'), findsOneWidget);
    });

    testWidgets('initBuilder without a binding is always initialized',
        (tester) async {
      await _pump(
        tester,
        _single(PlayxRoute(
          path: '/',
          initBuilder: (_, __, isInitialized) => Text('init:$isInitialized'),
        )),
      );
      expect(find.text('init:true'), findsOneWidget);
    });

    testWidgets('waitForBinding: false renders content before onEnter ends',
        (tester) async {
      final binding = GatedBinding();
      await _pump(
        tester,
        _single(PlayxRoute(
          path: '/',
          binding: binding,
          waitForBinding: false,
          builder: (_, __) => const Text('content'),
        )),
      );
      expect(find.text('content'), findsOneWidget);
      binding.gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('global waitForBinding: false applies to routes',
        (tester) async {
      final binding = GatedBinding();
      await _pump(
        tester,
        _single(PlayxRoute(
          path: '/',
          binding: binding,
          builder: (_, __) => const Text('content'),
        )),
        config: const PlayxPageConfig(waitForBinding: false),
      );
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('initTransitionDuration cross-fades loading to content',
        (tester) async {
      final binding = GatedBinding();
      await _pump(
        tester,
        _single(PlayxRoute(
          path: '/',
          binding: binding,
          initTransitionDuration: const Duration(milliseconds: 200),
          loadingWidget: const Text('loading'),
          builder: (_, __) => const Text('content'),
        )),
      );
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      expect(find.text('loading'), findsOneWidget);

      binding.gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Mid-animation both are in the tree.
      expect(find.text('loading'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('loading'), findsNothing);
    });

    testWidgets('Duration.zero and null skip the animation', (tester) async {
      for (final duration in [Duration.zero, null]) {
        final binding = GatedBinding();
        await _pump(
          tester,
          _single(PlayxRoute(
            path: '/',
            binding: binding,
            initTransitionDuration: duration,
            builder: (_, __) => const Text('content'),
          )),
        );
        expect(find.byType(AnimatedSwitcher), findsNothing);
      }
    });

    testWidgets('global initTransitionDuration with a shell', (tester) async {
      final binding = GatedBinding();
      await _pump(
        tester,
        _single(PlayxRoute(
          path: '/',
          binding: binding,
          shellBuilder: (_, __, ___, child) => Scaffold(body: child),
          builder: (_, __) => const Text('content'),
        )),
        config: const PlayxPageConfig(
          initTransitionDuration: Duration(milliseconds: 100),
        ),
      );
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    testWidgets('a new global config is applied to pages', (tester) async {
      final binding = GatedBinding();
      final router = _single(PlayxRoute(
        path: '/',
        binding: binding,
        builder: (_, __) => const Text('content'),
      ));
      Widget app(String loading) => PlayxNavigationBuilder(
            router: router,
            config: PlayxPageConfig(loadingWidget: Text(loading)),
            builder: (_) => MaterialApp.router(routerConfig: router),
          );
      await tester.pumpWidget(app('first'));
      await tester.pump();
      expect(find.text('first'), findsOneWidget);

      await tester.pumpWidget(app('second'));
      await tester.pump();
      expect(find.text('second'), findsOneWidget);
    });
  });

  group('error paths', () {
    testWidgets('a throwing onHidden is reported and the chain continues',
        (tester) async {
      final home = GatedBinding('home')..failHidden = true;
      home.gate.complete();
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: home,
          builder: (_, __) => const Text('home'),
          routes: [
            PlayxRoute(path: 'child', builder: (_, __) => const Text('child')),
          ],
        ),
      ]);
      await _pump(tester, router);
      await tester.pumpAndSettle();

      unawaited(router.push('/child'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isA<StateError>());

      router.pop();
      await tester.pumpAndSettle();
      expect(log, containsAllInOrder(['home:hidden', 'home:reEnter']));
    });

    testWidgets('onEnter failing after the page is gone is reported',
        (tester) async {
      final late = _LateFailBinding();
      final router = GoRouter(routes: [
        PlayxRoute(path: '/', builder: (_, __) => const Text('home')),
        PlayxRoute(
          path: '/next',
          binding: late,
          builder: (_, __) => const Text('next'),
        ),
      ]);
      await _pump(tester, router);
      unawaited(router.push('/next'));
      await tester.pump();
      await tester.pump();
      router.pop();
      await tester.pumpAndSettle();

      late.gate.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isA<StateError>());
    });

    testWidgets(
        'a controller factory error before first build uses '
        'errorBuilder', (tester) async {
      final router = GoRouter(routes: [
        PlayxRoute<Object>(
          path: '/',
          controller: (_, __) => throw StateError('factory failed'),
          errorBuilder: (_, __, error, ___, ____) => Text('error: $error'),
          builder: (_, __) => const Text('content'),
        ),
      ]);
      // Booted before the first frame, so the controller is created
      // synchronously and its error is rethrown from onEnter.
      await PlayxNavigation.boot(router: router);
      await tester.pumpWidget(PlayxNavigationBuilder(
        builder: (_) => MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('factory failed'), findsOneWidget);
    });

    testWidgets(
        'errors while unregistering/disposing a controller are '
        'reported and the rest still runs', (tester) async {
      var unregistered = 0;
      var disposed = 0;
      final router = GoRouter(routes: [
        PlayxRoute<Object>(
          path: '/',
          controller: (_, __) => Object(),
          disposeController: (_) {
            disposed++;
            throw StateError('dispose failed');
          },
          builder: (_, __) => const Text('page'),
        ),
        PlayxRoute(path: '/other', builder: (_, __) => const Text('other')),
      ]);
      await _pump(
        tester,
        router,
        config: PlayxPageConfig(
          registerController: <T extends Object>(c, s) {},
          unregisterController: <T extends Object>(c, s) {
            unregistered++;
            throw StateError('unregister failed');
          },
        ),
      );
      await tester.pumpAndSettle();
      router.go('/other');
      await tester.pumpAndSettle();
      expect(unregistered, 1);
      expect(disposed, 1);
      expect(tester.takeException(), isNotNull);
    });

    testWidgets('a failing onInitApp is reported by the builder',
        (tester) async {
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: _FailingInit(),
          builder: (_, __) => const Text('page'),
        ),
      ]);
      await _pump(tester, router);
      await tester.pumpAndSettle();
      // Reported once by the builder (boot failed) and once by the page that
      // could not enter because of it.
      expect(tester.takeException(), isNotNull);
    });
  });

  group('PlayxScope', () {
    testWidgets('state, values and disposal', (tester) async {
      final binding = GatedBinding()..gate.complete();
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: binding,
          builder: (_, __) => const Text('home'),
        ),
        PlayxRoute(path: '/other', builder: (_, __) => const Text('other')),
      ]);
      await _pump(tester, router);
      await tester.pumpAndSettle();
      final scope = binding.scope!;

      expect(scope.isActive, isTrue);
      expect(scope.isDisposed, isFalse);
      expect(scope.has<String>(), isFalse);
      expect(scope.maybeGet<String>(), isNull);
      expect(
        () => scope.get<String>(),
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            contains('No String found in the PlayxScope of GatedBinding'))),
      );

      final disposed = <String>[];
      scope.put<String>('a', dispose: (v) => disposed.add('first:$v'));
      scope.put<String>('b', dispose: (v) => disposed.add('second:$v'));
      scope.onDispose(() => disposed.add('callback'));
      expect(scope.get<String>(), 'b');
      expect(scope.has<String>(), isTrue);

      router.go('/other');
      await tester.pumpAndSettle();
      expect(scope.isDisposed, isTrue);
      expect(scope.isActive, isFalse);
      // Reverse registration order.
      expect(disposed, ['callback', 'second:b', 'first:a']);
      expect(scope.has<String>(), isFalse);
      expect(() => scope.put<int>(1), throwsStateError);
      expect(() => scope.onDispose(() {}), throwsStateError);
    });

    testWidgets('a throwing disposer is reported; others still run',
        (tester) async {
      final binding = GatedBinding()..gate.complete();
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: binding,
          builder: (_, __) => const Text('home'),
        ),
        PlayxRoute(path: '/other', builder: (_, __) => const Text('other')),
      ]);
      await _pump(tester, router);
      await tester.pumpAndSettle();
      var ran = false;
      binding.scope!
        ..onDispose(() => ran = true)
        ..onDispose(() => throw StateError('disposer failed'));

      router.go('/other');
      await tester.pumpAndSettle();
      expect(ran, isTrue);
      expect(tester.takeException(), isA<StateError>());
    });

    testWidgets('PlayxScopeProvider provides a scope to its child',
        (tester) async {
      final binding = GatedBinding()..gate.complete();
      final router = _single(PlayxRoute(
        path: '/',
        binding: binding,
        builder: (_, __) => const Text('home'),
      ));
      await _pump(tester, router);
      await tester.pumpAndSettle();

      late PlayxScope? found;
      await tester.pumpWidget(PlayxScopeProvider(
        scope: binding.scope!,
        child: Builder(builder: (context) {
          found = PlayxScope.maybeOf(context);
          return const SizedBox();
        }),
      ));
      expect(found, same(binding.scope));
    });
  });

  group('breadcrumb details', () {
    testWidgets('setBreadcrumbLabel outside a page throws', (tester) async {
      late BuildContext context;
      final router = GoRouter(routes: [
        PlayxRoute(path: '/', builder: (_, __) => const SizedBox()),
      ]);
      await _pump(tester, router);
      await tester.pumpWidget(Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }));
      expect(
        () => PlayxNavigation.setBreadcrumbLabel(context, 'x'),
        throwsStateError,
      );
    });

    testWidgets('PlayxBreadcrumbLabel works in a plain GoRoute',
        (tester) async {
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const PlayxBreadcrumbLabel(
            label: 'From label',
            child: Text('page'),
          ),
        ),
      ]);
      late BuildContext context;
      await tester.pumpWidget(PlayxNavigationBuilder(
        router: router,
        builder: (_) => MaterialApp.router(
          routerConfig: router,
          builder: (c, child) {
            context = c;
            return child!;
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('page'), findsOneWidget);
      // A plain GoRoute has no breadcrumb of its own, but a page inside it can
      // still label itself at runtime.
      final items = PlayxNavigation.breadcrumbs(context);
      expect(items.map((i) => i.label), ['From label']);
    });

    testWidgets('items describe themselves', (tester) async {
      late BuildContext context;
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          breadcrumb: (_, __) => 'Home',
          builder: (_, __) => const SizedBox(),
        ),
      ]);
      await tester.pumpWidget(PlayxNavigationBuilder(
        router: router,
        builder: (_) => MaterialApp.router(
          routerConfig: router,
          builder: (c, child) {
            context = c;
            return child!;
          },
        ),
      ));
      await tester.pumpAndSettle();
      final item = PlayxNavigation.breadcrumbs(context).single;
      expect(item.toString(), 'PlayxBreadcrumbItem(Home, /, current)');
    });

    testWidgets('history mode inside a shell route', (tester) async {
      late BuildContext context;
      final router = GoRouter(initialLocation: '/one', routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => shell,
          branches: [
            PlayxShellBranch(
              path: '/one',
              breadcrumb: (_, __) => 'One',
              builder: (_, __) => const Text('one'),
              routes: [
                PlayxRoute(
                  path: 'deep',
                  breadcrumb: (_, __) => 'Deep',
                  builder: (_, __) => const Text('deep'),
                ),
              ],
            ),
          ],
        ),
      ]);
      await tester.pumpWidget(PlayxNavigationBuilder(
        router: router,
        builder: (_) => MaterialApp.router(
          routerConfig: router,
          builder: (c, child) {
            context = c;
            return child!;
          },
        ),
      ));
      await tester.pumpAndSettle();
      unawaited(router.push('/one/deep'));
      await tester.pumpAndSettle();
      final items = PlayxNavigation.breadcrumbs(
        context,
        mode: PlayxBreadcrumbMode.history,
      );
      expect(items.map((i) => i.label), ['One', 'Deep']);
    });
  });

  group('maintainState', () {
    testWidgets('false: a covered page exits and enters again when revealed',
        (tester) async {
      final home = GatedBinding('home')..gate.complete();
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: home,
          pageConfiguration: const PlayxPageConfiguration(maintainState: false),
          builder: (_, __) => const Text('home'),
        ),
        PlayxRoute(path: '/next', builder: (_, __) => const Text('next')),
      ]);
      await _pump(tester, router);
      await tester.pumpAndSettle();
      log.clear();

      unawaited(router.push('/next'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      expect(log, ['home:hidden', 'home:exit', 'home:enter']);
    });
  });

  group('small APIs', () {
    test('PlayxPageLifecycle defaults do nothing', () async {
      final controller = _PlainController();
      await controller.onPageEnter(_stateFor(GoRouter(routes: [])));
      await controller.onPageHidden();
      await controller.onPageReEnter(null, true);
      await controller.onPageExit();
    });

    testWidgets('PlayxRouter state helpers', (tester) async {
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          name: 'root',
          builder: (_, __) => const Text('root'),
        ),
        PlayxRoute(path: '/next', builder: (_, __) => const Text('next')),
      ]);
      await _pump(tester, router);
      final playx = PlayxNavigation.playxRouter;
      expect(playx.state.matchedLocation, '/');
      expect(playx.currentRouteName, 'root');

      unawaited(router.push('/next'));
      await tester.pumpAndSettle();
      PlayxNavigation.popOrGo('/'); // can pop: pops instead of going
      await tester.pumpAndSettle();
      expect(find.text('root'), findsOneWidget);
    });
  });
}

GoRouterState _stateFor(GoRouter router) => GoRouterState(
      router.configuration,
      uri: Uri.parse('/'),
      matchedLocation: '/',
      fullPath: '/',
      pathParameters: const {},
      pageKey: const ValueKey('k'),
    );

class _PlainController with PlayxPageLifecycle {}

class _LateFailBinding extends PlayxBinding {
  final Completer<void> gate = Completer<void>();

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    await gate.future;
    throw StateError('late failure');
  }
}

class _FailingInit extends PlayxBinding {
  @override
  Future<void> onInitApp() async => throw StateError('init failed');

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {}
}
