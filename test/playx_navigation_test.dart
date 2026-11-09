import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_navigation/playx_navigation.dart';

class _Binding extends PlayxBinding {
  final List<String> events = [];
  Completer<void>? enterCompleter;
  Object? enterError;
  int enterCalls = 0;

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    enterCalls++;
    events.add('enter');
    if (enterError != null && enterCalls == 1) throw enterError!;
    await enterCompleter?.future;
  }

  @override
  Future<void> onExit(BuildContext context) async => events.add('exit');

  @override
  Future<void> onHidden(BuildContext context) async => events.add('hidden');

  @override
  Future<void> onReEnter(
    BuildContext context,
    GoRouterState? state,
    bool wasPoppedAndReentered,
  ) async =>
      events.add('reEnter:$wasPoppedAndReentered');
}

Widget _app(GoRouter router, {PlayxPageConfig? config}) {
  return PlayxNavigationBuilder(
    router: router,
    config: config,
    builder: (_) => MaterialApp.router(routerConfig: router),
  );
}

Widget _page(String text) => Scaffold(body: Text(text));

void main() {
  testWidgets('shows loading until onEnter completes', (tester) async {
    final binding = _Binding()..enterCompleter = Completer<void>();
    final router = GoRouter(routes: [
      PlayxRoute(
        path: '/',
        binding: binding,
        loadingWidget: const Text('loading'),
        builder: (_, __) => _page('home'),
      ),
    ]);

    await tester.pumpWidget(_app(router));
    await tester.pump();
    expect(find.text('loading'), findsOneWidget);
    expect(find.text('home'), findsNothing);

    binding.enterCompleter!.complete();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(binding.events, ['enter']);
  });

  testWidgets('lifecycle: hidden, reEnter and exit', (tester) async {
    final home = _Binding();
    final details = _Binding();
    final router = GoRouter(routes: [
      PlayxRoute(
        path: '/',
        binding: home,
        builder: (_, __) => _page('home'),
        routes: [
          PlayxRoute(
            path: 'details',
            binding: details,
            builder: (_, __) => _page('details'),
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    expect(home.events, ['enter']);

    unawaited(router.push('/details'));
    await tester.pumpAndSettle();
    expect(find.text('details'), findsOneWidget);
    expect(home.events, ['enter', 'hidden']);
    expect(details.events, ['enter']);

    router.pop();
    await tester.pumpAndSettle();
    expect(home.events, ['enter', 'hidden', 'reEnter:true']);
    expect(details.events, ['enter', 'hidden', 'exit']);
  });

  group('onEnter errors', () {
    testWidgets('errorBuilder is shown and retry re-runs onEnter',
        (tester) async {
      final binding = _Binding()..enterError = StateError('boom');
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: binding,
          errorBuilder: (_, __, error, ___, retry) => TextButton(
            onPressed: retry,
            child: Text('error: $error'),
          ),
          builder: (_, __) => _page('home'),
        ),
      ]);

      await tester.pumpWidget(_app(router));
      await tester.pumpAndSettle();
      expect(find.textContaining('boom'), findsOneWidget);
      expect(binding.currentState, PlayxPageState.pending);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(binding.enterCalls, 2);
      expect(binding.currentState, PlayxPageState.enter);
    });

    testWidgets('timeout surfaces TimeoutException to global errorBuilder',
        (tester) async {
      final binding = _Binding()..enterCompleter = Completer<void>();
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: binding,
          enterTimeout: const Duration(seconds: 1),
          builder: (_, __) => _page('home'),
        ),
      ]);

      await tester.pumpWidget(_app(
        router,
        config: PlayxPageConfig(
          errorBuilder: (_, __, error, ___, ____) =>
              Text('timeout: ${error is TimeoutException}'),
        ),
      ));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text('timeout: true'), findsOneWidget);
    });

    testWidgets('global enterTimeout applies when the route sets none',
        (tester) async {
      final binding = _Binding()..enterCompleter = Completer<void>();
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: binding,
          builder: (_, __) => _page('home'),
        ),
      ]);

      await tester.pumpWidget(_app(
        router,
        config: PlayxPageConfig(
          enterTimeout: const Duration(seconds: 1),
          errorBuilder: (_, __, error, ___, ____) =>
              Text('timeout: ${error is TimeoutException}'),
        ),
      ));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text('timeout: true'), findsOneWidget);
    });

    testWidgets('without errorBuilder the error is reported, not unhandled',
        (tester) async {
      final binding = _Binding()..enterError = StateError('boom');
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: binding,
          loadingWidget: const Text('loading'),
          builder: (_, __) => _page('home'),
        ),
      ]);

      await tester.pumpWidget(_app(router));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isA<StateError>());
      expect(find.text('loading'), findsOneWidget);
    });
  });

  group('guards', () {
    GoRouter buildRouter(List<PlayxGuard> guards,
        {GoRouterRedirect? redirect}) {
      return GoRouter(routes: [
        PlayxRoute(path: '/', builder: (_, __) => _page('home')),
        PlayxRoute(path: '/login', builder: (_, __) => _page('login')),
        PlayxRoute(path: '/other', builder: (_, __) => _page('other')),
        PlayxRoute(
          path: '/account',
          guards: guards,
          redirect: redirect,
          builder: (_, __) => _page('account'),
        ),
      ]);
    }

    Future<void> go(WidgetTester tester, GoRouter router) async {
      await tester.pumpWidget(_app(router));
      await tester.pumpAndSettle();
      router.go('/account');
      await tester.pumpAndSettle();
    }

    testWidgets('redirects when a guard returns a location', (tester) async {
      final router = buildRouter([PlayxGuard.from((_, __) => '/login')]);
      await go(tester, router);
      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('allows navigation when guards return null', (tester) async {
      final router = buildRouter([PlayxGuard.from((_, __) async => null)]);
      await go(tester, router);
      expect(find.text('account'), findsOneWidget);
    });

    testWidgets('first redirecting guard wins, before route redirect',
        (tester) async {
      final router = buildRouter(
        [
          PlayxGuard.from((_, __) => null),
          PlayxGuard.from((_, __) async => '/login'),
          PlayxGuard.from((_, __) => '/other'),
        ],
        redirect: (_, __) => '/other',
      );
      await go(tester, router);
      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('route redirect still runs when guards pass', (tester) async {
      final router = buildRouter(
        [PlayxGuard.from((_, __) => null)],
        redirect: (_, __) => '/other',
      );
      await go(tester, router);
      expect(find.text('other'), findsOneWidget);
    });
  });
}
