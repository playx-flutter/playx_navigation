import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_navigation/playx_navigation.dart';

/// Shared, ordered log of every lifecycle event across all bindings.
final List<String> log = [];

class _B extends PlayxBinding {
  final String name;
  Duration enterDelay;
  Duration initDelay;
  Object? failOnce;
  _B(this.name,
      {this.enterDelay = Duration.zero, this.initDelay = Duration.zero});

  @override
  Future<void> onInitApp() async {
    if (initDelay > Duration.zero) await Future<void>.delayed(initDelay);
    log.add('$name:init');
  }

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    log.add('$name:enter');
    if (enterDelay > Duration.zero) await Future<void>.delayed(enterDelay);
    final error = failOnce;
    if (error != null) {
      failOnce = null;
      throw error;
    }
    log.add('$name:entered');
  }

  @override
  Future<void> onExit(BuildContext context) async => log.add('$name:exit');

  @override
  Future<void> onHidden(BuildContext context) async => log.add('$name:hidden');

  @override
  Future<void> onReEnter(
    BuildContext context,
    GoRouterState? state,
    bool wasPopped,
  ) async =>
      log.add('$name:reEnter${wasPopped ? '(popped)' : ''}');
}

Widget _page(String t) => Scaffold(body: Text(t));

PlayxRoute _route(String path, _B b,
        {List<RouteBase> routes = const [], String? text}) =>
    PlayxRoute(
      path: path,
      binding: b,
      builder: (_, s) => _page(text ?? b.name),
      routes: routes,
    );

late StatefulNavigationShell _shell;

/// Shell with products / favorites branches, each with a details child.
GoRouter _shellRouter({
  required _B p,
  required _B pd,
  required _B f,
  required _B fd,
  String initial = '/products',
}) {
  return GoRouter(
    initialLocation: initial,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) {
          _shell = shell;
          return shell;
        },
        branches: [
          StatefulShellBranch(routes: [
            _route('/products', p, routes: [_route('details/:id', pd)]),
          ]),
          StatefulShellBranch(routes: [
            _route('/favorites', f, routes: [_route('details/:id', fd)]),
          ]),
        ],
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  log.clear();
  await tester.pumpWidget(PlayxNavigationBuilder(
    router: router,
    builder: (_) => MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

Future<void> _push(WidgetTester tester, GoRouter router, String l) async {
  unawaited(router.push(l));
  await tester.pumpAndSettle();
}

Future<void> _pop(WidgetTester tester, GoRouter router) async {
  router.pop();
  await tester.pumpAndSettle();
}

Future<void> _branch(WidgetTester tester, int i) async {
  _shell.goBranch(i);
  await tester.pumpAndSettle();
}

/// Returns and clears the events logged since the last call.
/// Events for `:init` and `:entered` are hidden unless [all] is set.
List<String> _take({bool all = false}) {
  final r = List<String>.of(log);
  log.clear();
  return all
      ? r
      : r
          .where((e) => !e.endsWith(':init') && !e.endsWith(':entered'))
          .toList();
}

void main() {
  late _B p, pd, f, fd;
  setUp(() {
    p = _B('P');
    pd = _B('PD');
    f = _B('F');
    fd = _B('FD');
  });

  group('shell: products -> details, favorites -> details', () {
    testWidgets('products -> details -> back', (tester) async {
      final router = _shellRouter(p: p, pd: pd, f: f, fd: fd);
      await _pump(tester, router);
      expect(_take(), ['P:enter']);

      await _push(tester, router, '/products/details/1');
      expect(_take(), ['P:hidden', 'PD:enter']);

      await _pop(tester, router);
      expect(_take(), ['PD:hidden', 'P:reEnter(popped)', 'PD:exit']);
    });

    testWidgets('details -> switch branch -> switch back -> pop',
        (tester) async {
      final router = _shellRouter(p: p, pd: pd, f: f, fd: fd);
      await _pump(tester, router);
      await _push(tester, router, '/products/details/1');
      _take();

      await _branch(tester, 1);
      expect(_take(), ['PD:hidden', 'F:enter']);

      await _branch(tester, 0);
      expect(_take(), ['F:hidden', 'PD:reEnter']);

      await _pop(tester, router);
      expect(_take(), ['PD:hidden', 'P:reEnter(popped)', 'PD:exit']);
    });

    testWidgets('favorites details -> switch to products (the reported case)',
        (tester) async {
      final router = _shellRouter(p: p, pd: pd, f: f, fd: fd);
      await _pump(tester, router);
      await _branch(tester, 1);
      await _push(tester, router, '/favorites/details/1');
      _take();

      // favorites details -> products tab: details hidden, products re-entered.
      await _branch(tester, 0);
      expect(_take(), ['FD:hidden', 'P:reEnter']);

      // back to favorites tab: its details page is visible again.
      await _branch(tester, 1);
      expect(_take(), ['P:hidden', 'FD:reEnter']);

      // pop favorites details: favorites list becomes visible.
      await _pop(tester, router);
      expect(_take(), ['FD:hidden', 'F:reEnter(popped)', 'FD:exit']);

      // and to products again.
      await _branch(tester, 0);
      expect(_take(), ['F:hidden', 'P:reEnter']);
    });

    testWidgets('both tabs have details open, switching repeatedly',
        (tester) async {
      final router = _shellRouter(p: p, pd: pd, f: f, fd: fd);
      await _pump(tester, router);
      await _push(tester, router, '/products/details/1');
      await _branch(tester, 1);
      await _push(tester, router, '/favorites/details/2');
      _take();

      await _branch(tester, 0);
      expect(_take(), ['FD:hidden', 'PD:reEnter']);
      await _branch(tester, 1);
      expect(_take(), ['PD:hidden', 'FD:reEnter']);
      await _pop(tester, router);
      expect(_take(), ['FD:hidden', 'F:reEnter(popped)', 'FD:exit']);
      await _branch(tester, 0);
      expect(_take(), ['F:hidden', 'PD:reEnter']);
      await _pop(tester, router);
      expect(_take(), ['PD:hidden', 'P:reEnter(popped)', 'PD:exit']);
    });

    testWidgets('deep link straight to details defers parent onEnter',
        (tester) async {
      final router = _shellRouter(
          p: p, pd: pd, f: f, fd: fd, initial: '/products/details/1');
      await _pump(tester, router);
      expect(_take(), ['PD:enter']);
      expect(p.currentState, PlayxPageState.pending);

      await _pop(tester, router);
      // The parent was never entered, so this is an enter, not a re-enter.
      expect(_take(), ['PD:hidden', 'P:enter', 'PD:exit']);
    });

    testWidgets('deep link to favorites details, then to products tab',
        (tester) async {
      final router = _shellRouter(
          p: p, pd: pd, f: f, fd: fd, initial: '/favorites/details/1');
      await _pump(tester, router);
      expect(_take(), ['FD:enter']);

      await _branch(tester, 0);
      expect(_take(), ['FD:hidden', 'P:enter']);

      await _branch(tester, 1);
      expect(_take(), ['P:hidden', 'FD:reEnter']);
    });

    testWidgets('same route pushed twice with different params',
        (tester) async {
      final router = _shellRouter(p: p, pd: pd, f: f, fd: fd);
      await _pump(tester, router);
      await _push(tester, router, '/products/details/1');
      _take();

      await _push(tester, router, '/products/details/2');
      // The first details instance is covered by the second.
      expect(_take(), ['PD:hidden', 'PD:enter']);

      await _pop(tester, router);
      expect(_take(), ['PD:hidden', 'PD:reEnter(popped)', 'PD:exit']);

      await _pop(tester, router);
      expect(_take(), ['PD:hidden', 'P:reEnter(popped)', 'PD:exit']);
    });

    testWidgets('one binding shared by both details routes', (tester) async {
      final shared = _B('S');
      final router = _shellRouter(p: p, pd: shared, f: f, fd: shared);
      await _pump(tester, router);
      await _push(tester, router, '/products/details/1');
      _take();

      await _branch(tester, 1);
      expect(_take(), ['S:hidden', 'F:enter']);
      await _push(tester, router, '/favorites/details/2');
      expect(_take(), ['F:hidden', 'S:enter']);

      await _branch(tester, 0);
      expect(_take(), ['S:hidden', 'S:reEnter']);
    });
  });

  group('non-shell navigation', () {
    GoRouter plain() => GoRouter(routes: [
          _route('/', p, routes: [_route('details', pd)]),
          _route('/other', f),
        ]);

    testWidgets('go() to unrelated route exits the whole stack',
        (tester) async {
      final router = plain();
      await _pump(tester, router);
      await _push(tester, router, '/details');
      _take();

      router.go('/other');
      await tester.pumpAndSettle();
      final events = _take();
      expect(events.toSet(),
          {'PD:hidden', 'PD:exit', 'P:exit', 'F:enter'}..remove('P:hidden'));
      // Each exited binding was hidden/exited at most once, none re-entered.
      expect(events.where((e) => e.contains('reEnter')), isEmpty);
      expect(events.where((e) => e == 'PD:exit').length, 1);
      expect(events.where((e) => e == 'P:exit').length, 1);
    });

    testWidgets('replace swaps details without re-entering parent',
        (tester) async {
      final router = plain();
      await _pump(tester, router);
      await _push(tester, router, '/details');
      _take();

      unawaited(router.replace('/other'));
      await tester.pumpAndSettle();
      final events = _take();
      expect(events.where((e) => e.contains('reEnter')), isEmpty);
      expect(events, contains('PD:exit'));
      expect(events, contains('F:enter'));
    });
  });

  group('async onEnter', () {
    testWidgets('leaving while onEnter is running still calls onExit',
        (tester) async {
      final slow = _B('PD', enterDelay: const Duration(seconds: 1));
      final router = _shellRouter(p: p, pd: slow, f: f, fd: fd);
      await _pump(tester, router);
      unawaited(router.push('/products/details/1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      _take();

      router.pop();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      final events = _take();
      // onEnter began, so cleanup must run exactly once.
      expect(events.where((e) => e == 'PD:exit').length, 1);
      expect(events.where((e) => e == 'P:reEnter(popped)').length, 1);
    });
  });

  group('more edge cases', () {
    testWidgets('path param change re-creates the page (exit then enter)',
        (tester) async {
      final router = GoRouter(routes: [
        _route('/', p),
        _route('/item/:id', pd),
      ]);
      await _pump(tester, router);
      router.go('/item/1');
      await tester.pumpAndSettle();
      _take();

      router.go('/item/2');
      await tester.pumpAndSettle();
      // The old visit's onExit completes before the new onEnter starts.
      expect(_take(all: true), ['PD:exit', 'PD:enter', 'PD:entered']);
    });

    testWidgets('same location pushed twice keeps pages independent',
        (tester) async {
      final router = GoRouter(routes: [
        _route('/', p, routes: [_route('details', pd)]),
      ]);
      await _pump(tester, router);
      await _push(tester, router, '/details');
      _take();

      await _push(tester, router, '/details');
      expect(_take(all: true), ['PD:hidden', 'PD:enter', 'PD:entered']);

      await _pop(tester, router);
      expect(_take(), ['PD:hidden', 'PD:reEnter(popped)', 'PD:exit']);
    });

    testWidgets('onEnter waits for every onInitApp', (tester) async {
      final slowInit = _B('P', initDelay: const Duration(seconds: 1));
      final router = GoRouter(routes: [_route('/', slowInit)]);
      log.clear();
      await tester.pumpWidget(PlayxNavigationBuilder(
        router: router,
        builder: (_) => MaterialApp.router(routerConfig: router),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      expect(log, isEmpty);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(log, ['P:init', 'P:enter', 'P:entered']);
    });

    testWidgets('hidden/exit never overlap a running onEnter', (tester) async {
      final slow = _B('PD', enterDelay: const Duration(seconds: 1));
      final router = _shellRouter(p: p, pd: slow, f: f, fd: fd);
      await _pump(tester, router);
      _take();
      unawaited(router.push('/products/details/1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      router.pop();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      final events = _take(all: true).where((e) => e.startsWith('PD')).toList();
      // For the in-flight instance: enter, entered, hidden, exit - in order.
      final i = events.indexOf('PD:enter');
      expect(events.sublist(i, i + 4),
          ['PD:enter', 'PD:entered', 'PD:hidden', 'PD:exit']);
    });

    testWidgets('failed onEnter: later hidden/exit are skipped',
        (tester) async {
      final bad = _B('PD')..failOnce = StateError('boom');
      final router = _shellRouter(p: p, pd: bad, f: f, fd: fd);
      await _pump(tester, router);
      unawaited(router.push('/products/details/1'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isA<StateError>());
      _take();

      router.pop();
      await tester.pumpAndSettle();
      final events = _take();
      expect(events, isNot(contains('PD:hidden')));
      expect(events, isNot(contains('PD:exit')));
      expect(events, contains('P:reEnter(popped)'));
    });

    testWidgets('plain ShellRoute: switching exits the old child',
        (tester) async {
      final router = GoRouter(routes: [
        ShellRoute(
          builder: (_, __, child) => child,
          routes: [
            _route('/a', p, routes: [_route('details', pd)]),
            _route('/b', f),
          ],
        ),
      ], initialLocation: '/a');
      await _pump(tester, router);
      await _push(tester, router, '/a/details');
      _take();

      router.go('/b');
      await tester.pumpAndSettle();
      final events = _take();
      expect(events.where((e) => e == 'PD:exit').length, 1);
      expect(events.where((e) => e == 'P:exit').length, 1);
      expect(events, contains('F:enter'));
      expect(events.where((e) => e.contains('reEnter')), isEmpty);
    });

    testWidgets('rapid push/pop within one frame ends consistent',
        (tester) async {
      final router = _shellRouter(p: p, pd: pd, f: f, fd: fd);
      await _pump(tester, router);
      unawaited(router.push('/products/details/1'));
      await tester.pump(); // one frame only, transition still running
      router.pop();
      await tester.pumpAndSettle();
      expect(
          p.currentState, anyOf(PlayxPageState.enter, PlayxPageState.reEnter));
      expect(pd.currentState, anyOf(PlayxPageState.exit, isNull));
      final events = _take();
      expect(events.where((e) => e == 'PD:enter').length,
          events.where((e) => e == 'PD:exit').length);
    });
  });

  group('details reachable from several places', () {
    late _B d, s;
    late GlobalKey<NavigatorState> rootKey;

    /// Shell (products -> details, favorites) + a top-level `/details/:id`
    /// shown above the shell, + a non-shell `/search` page.
    GoRouter build({String initial = '/products', bool preload = false}) {
      rootKey = GlobalKey<NavigatorState>();
      return GoRouter(
        navigatorKey: rootKey,
        initialLocation: initial,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, __, shell) {
              _shell = shell;
              return shell;
            },
            branches: [
              StatefulShellBranch(routes: [
                _route('/products', p, routes: [_route('details/:id', pd)]),
              ]),
              StatefulShellBranch(preload: preload, routes: [
                _route('/favorites', f, routes: [_route('details/:id', fd)]),
              ]),
            ],
          ),
          _route('/details/:id', d),
          _route('/search', s),
          _route('/login', _B('L')),
        ],
      );
    }

    setUp(() {
      d = _B('D');
      s = _B('S');
    });

    testWidgets('top-level details from products, favorites and search',
        (tester) async {
      final router = build();
      await _pump(tester, router);
      _take();

      await _push(tester, router, '/details/1');
      expect(_take(), ['P:hidden', 'D:enter']);
      await _pop(tester, router);
      expect(_take(), ['D:hidden', 'P:reEnter(popped)', 'D:exit']);

      await _branch(tester, 1);
      _take();
      await _push(tester, router, '/details/1');
      expect(_take(), ['F:hidden', 'D:enter']);
      await _pop(tester, router);
      expect(_take(), ['D:hidden', 'F:reEnter(popped)', 'D:exit']);

      await _push(tester, router, '/search');
      _take();
      await _push(tester, router, '/details/1');
      expect(_take(), ['S:hidden', 'D:enter']);
      await _pop(tester, router);
      expect(_take(), ['D:hidden', 'S:reEnter(popped)', 'D:exit']);
      await _pop(tester, router);
      expect(_take(), ['S:hidden', 'F:reEnter(popped)', 'S:exit']);
    });

    testWidgets('in-branch details -> top-level details -> back twice',
        (tester) async {
      final router = build();
      await _pump(tester, router);
      await _push(tester, router, '/products/details/1');
      _take();

      await _push(tester, router, '/details/1');
      expect(_take(), ['PD:hidden', 'D:enter']);
      await _pop(tester, router);
      expect(_take(), ['D:hidden', 'PD:reEnter(popped)', 'D:exit']);
      await _pop(tester, router);
      expect(_take(), ['PD:hidden', 'P:reEnter(popped)', 'PD:exit']);
    });

    testWidgets('one binding shared by in-branch and top-level details',
        (tester) async {
      final shared = _B('X');
      final router = GoRouter(initialLocation: '/products', routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) {
            _shell = shell;
            return shell;
          },
          branches: [
            StatefulShellBranch(routes: [
              _route('/products', p, routes: [_route('details/:id', shared)]),
            ]),
            StatefulShellBranch(routes: [_route('/favorites', f)]),
          ],
        ),
        _route('/details/:id', shared),
      ]);
      await _pump(tester, router);
      await _push(tester, router, '/products/details/1');
      _take();

      // Same binding, two live pages: the covered one is hidden, the new one
      // entered; popping re-enters the first, then exits the second.
      await _push(tester, router, '/details/2');
      expect(_take(), ['X:hidden', 'X:enter']);
      await _pop(tester, router);
      expect(_take(), ['X:hidden', 'X:reEnter(popped)', 'X:exit']);
      expect(shared.currentState, PlayxPageState.reEnter);
    });

    testWidgets('go from favorites details to products details',
        (tester) async {
      final router = build();
      await _pump(tester, router);
      await _branch(tester, 1);
      await _push(tester, router, '/favorites/details/1');
      _take();

      router.go('/products/details/7');
      await tester.pumpAndSettle();
      // Products list is mounted behind the new details: pending, not entered.
      expect(_take(), ['FD:hidden', 'PD:enter']);
      expect(p.currentState, PlayxPageState.hidden);

      await _pop(tester, router);
      expect(_take(), ['PD:hidden', 'P:reEnter(popped)', 'PD:exit']);

      // Favorites details is still alive in its branch.
      await _branch(tester, 1);
      expect(_take(), ['P:hidden', 'FD:reEnter']);
    });

    testWidgets('go to a route outside the shell exits every entered page',
        (tester) async {
      final router = build();
      await _pump(tester, router);
      await _push(tester, router, '/products/details/1');
      await _branch(tester, 1);
      _take();

      router.go('/login');
      await tester.pumpAndSettle();
      final events = _take();
      expect(events, contains('L:enter'));
      for (final name in ['P', 'PD', 'F']) {
        expect(events.where((e) => e == '$name:exit').length, 1,
            reason: '$name should exit exactly once: $events');
      }
      // Favorites details was never visited.
      expect(events.where((e) => e.startsWith('FD')), isEmpty);
      expect(events.where((e) => e.contains('reEnter')), isEmpty);
    });

    testWidgets('preloaded branch is pending until first shown',
        (tester) async {
      final router = build(preload: true);
      await _pump(tester, router);
      expect(_take(), ['P:enter']);
      expect(f.currentState, PlayxPageState.pending);

      await _branch(tester, 1);
      expect(_take(), ['P:hidden', 'F:enter']);
    });

    testWidgets('goBranch(initialLocation: true) resets the branch',
        (tester) async {
      final router = build();
      await _pump(tester, router);
      await _push(tester, router, '/products/details/1');
      _take();

      _shell.goBranch(0, initialLocation: true);
      await tester.pumpAndSettle();
      expect(_take(), ['PD:hidden', 'P:reEnter(popped)', 'PD:exit']);
    });

    testWidgets('offAndTo the same route: exit completes before enter',
        (tester) async {
      final router = build();
      await _pump(tester, router);
      await _push(tester, router, '/details/1');
      _take();

      unawaited(router.replace('/details/2'));
      await tester.pumpAndSettle();
      expect(_take(all: true), ['D:exit', 'D:enter', 'D:entered']);
      expect(d.currentState, PlayxPageState.enter);

      await _pop(tester, router);
      expect(_take(), ['D:hidden', 'P:reEnter(popped)', 'D:exit']);
    });

    testWidgets('replace with a different route swaps bindings in order',
        (tester) async {
      final router = build();
      await _pump(tester, router);
      await _push(tester, router, '/details/1');
      _take();

      unawaited(router.replace('/search'));
      await tester.pumpAndSettle();
      expect(_take(), ['D:exit', 'S:enter']);
    });

    testWidgets('guard redirecting to the current page changes nothing',
        (tester) async {
      final router = GoRouter(routes: [
        _route('/', p),
        PlayxRoute(
          path: '/blocked',
          binding: pd,
          guards: [PlayxGuard.from((_, __) => '/')],
          builder: (_, __) => _page('blocked'),
        ),
      ]);
      await _pump(tester, router);
      _take();
      router.go('/blocked');
      await tester.pumpAndSettle();
      expect(_take(), isEmpty);
      expect(p.currentState, PlayxPageState.enter);
    });
  });

  testWidgets('unknown location: error page hides, going back re-enters',
      (tester) async {
    final p = _B('P');
    final router = GoRouter(routes: [_route('/', p)]);
    await _pump(tester, router);
    _take();

    router.go('/does-not-exist');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    router.go('/');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The error page replaced the whole stack, so this is a fresh page.
    expect(_take(), ['P:hidden', 'P:exit', 'P:enter']);
  });
}
