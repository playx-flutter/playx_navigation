import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_navigation/playx_navigation.dart';

class _RedirectBinding extends PlayxBinding {
  _RedirectBinding(this.location, this.calls);
  final String? location;
  final List<String> calls;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    calls.add('binding');
    return location;
  }

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {}
}

Widget _page(String text) => Scaffold(body: Text(text));

Future<GoRouter> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(PlayxNavigationBuilder(
    router: router,
    builder: (_) => MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  // A different router given to the same builder is booted too.
  expect(PlayxNavigation.goRouter, same(router));
  return router;
}

void main() {
  testWidgets('a guard on a parent protects its child routes', (tester) async {
    final router = GoRouter(routes: [
      PlayxRoute(path: '/', builder: (_, __) => _page('home')),
      PlayxRoute(path: '/login', builder: (_, __) => _page('login')),
      PlayxRoute(
        path: '/account',
        guards: [PlayxGuard.from((_, __) => '/login')],
        builder: (_, __) => _page('account'),
        routes: [
          PlayxRoute(path: 'settings', builder: (_, __) => _page('settings')),
        ],
      ),
    ]);
    await _pump(tester, router);
    router.go('/account/settings');
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('order: guards, then binding redirect, then route redirect',
      (tester) async {
    final calls = <String>[];
    GoRouter build({
      String? guard,
      String? binding,
      String? route,
    }) {
      calls.clear();
      return GoRouter(routes: [
        PlayxRoute(path: '/', builder: (_, __) => _page('home')),
        PlayxRoute(path: '/guard', builder: (_, __) => _page('guard')),
        PlayxRoute(path: '/binding', builder: (_, __) => _page('binding')),
        PlayxRoute(path: '/route', builder: (_, __) => _page('route')),
        PlayxRoute(
          path: '/target',
          guards: [
            PlayxGuard.from((_, __) {
              calls.add('guard');
              return guard;
            }),
          ],
          binding: _RedirectBinding(binding, calls),
          redirect: (_, __) {
            calls.add('route');
            return route;
          },
          builder: (_, __) => _page('target'),
        ),
      ]);
    }

    var router = build(guard: '/guard', binding: '/binding', route: '/route');
    await _pump(tester, router);
    router.go('/target');
    await tester.pumpAndSettle();
    expect(find.text('guard'), findsOneWidget);
    expect(calls, ['guard']);

    router = build(binding: '/binding', route: '/route');
    await _pump(tester, router);
    router.go('/target');
    await tester.pumpAndSettle();
    expect(find.text('binding'), findsOneWidget);
    expect(calls, ['guard', 'binding']);

    router = build(route: '/route');
    await _pump(tester, router);
    router.go('/target');
    await tester.pumpAndSettle();
    expect(find.text('route'), findsOneWidget);
    expect(calls, ['guard', 'binding', 'route']);

    router = build();
    await _pump(tester, router);
    router.go('/target');
    await tester.pumpAndSettle();
    expect(find.text('target'), findsOneWidget);
  });

  testWidgets('async guards are awaited', (tester) async {
    final router = GoRouter(routes: [
      PlayxRoute(path: '/', builder: (_, __) => _page('home')),
      PlayxRoute(path: '/login', builder: (_, __) => _page('login')),
      PlayxRoute(
        path: '/private',
        guards: [
          PlayxGuard.from((_, __) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return '/login';
          }),
        ],
        builder: (_, __) => _page('private'),
      ),
    ]);
    await _pump(tester, router);
    router.go('/private');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
  });
}
