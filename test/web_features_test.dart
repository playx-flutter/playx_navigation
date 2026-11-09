import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Future<void> onHidden(BuildContext context) async => log.add('$name:hidden');

  @override
  Future<void> onReEnter(
          BuildContext context, GoRouterState? state, bool popped) async =>
      log.add('$name:reEnter${popped ? '(popped)' : ''}');

  @override
  Future<void> onExit(BuildContext context) async => log.add('$name:exit');
}

PlayxRoute _route(
  String path,
  String label, {
  String? name,
  List<RouteBase> routes = const [],
  Widget? child,
}) =>
    PlayxRoute(
      path: path,
      name: name,
      binding: _B(label),
      breadcrumb: (_, __) => label,
      builder: (_, __) => child ?? Scaffold(body: Text(label)),
      routes: routes,
    );

List<RouteBase> _routes({Widget? detailsChild}) => [
      _route('/jobs', 'Jobs', name: 'jobs', routes: [
        PlayxRoute(
          path: ':id',
          name: 'details',
          binding: _B('details'),
          breadcrumb: (_, s) => 'Job #${s.pathParameters['id']}',
          builder: (_, __) =>
              detailsChild ?? const Scaffold(body: Text('details')),
          routes: [_route('edit', 'Edit', name: 'edit')],
        ),
      ]),
      _route('/other', 'Other'),
    ];

Future<void> _pump(
  WidgetTester tester,
  GoRouter router, {
  PlayxPageTitle? pageTitle,
  bool bootElsewhere = false,
}) async {
  if (bootElsewhere) unawaited(PlayxNavigation.boot(router: router));
  await tester.pumpWidget(PlayxNavigationBuilder(
    router: bootElsewhere ? null : router,
    pageTitle: pageTitle,
    builder: (_) => MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  log.clear();
}

Future<void> _push(
    WidgetTester tester, GoRouter router, String location) async {
  unawaited(router.push(location));
  await tester.pumpAndSettle();
}

void main() {
  final titles = <String>[];

  setUp(() {
    log.clear();
    titles.clear();
  });

  void mockTitles(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setApplicationSwitcherDescription') {
          // MaterialApp's own Title widget sends an empty label; ignore it.
          final label = (call.arguments as Map)['label'] as String;
          if (label.isNotEmpty) titles.add(label);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
  }

  group('PlayxPageTitle', () {
    testWidgets('follows navigation: current page first, then parents',
        (tester) async {
      mockTitles(tester);
      final router = GoRouter(initialLocation: '/jobs', routes: _routes());
      await _pump(tester, router,
          pageTitle: const PlayxPageTitle(appName: 'Dashboard'));
      expect(titles.last, 'Jobs · Dashboard');

      await _push(tester, router, '/jobs/5');
      expect(titles.last, 'Job #5 · Jobs · Dashboard');

      await _push(tester, router, '/jobs/5/edit');
      // maxItems defaults to 2: current page and its parent.
      expect(titles.last, 'Edit · Job #5 · Dashboard');

      router.pop();
      await tester.pumpAndSettle();
      expect(titles.last, 'Job #5 · Jobs · Dashboard');
    });

    testWidgets('does not resend an unchanged title', (tester) async {
      mockTitles(tester);
      final router = GoRouter(initialLocation: '/jobs', routes: _routes());
      await _pump(tester, router, pageTitle: const PlayxPageTitle());
      final count = titles.length;
      router.refresh();
      await tester.pumpAndSettle();
      expect(titles.length, count);
    });

    testWidgets('maxItems, separator and mode', (tester) async {
      mockTitles(tester);
      final router =
          GoRouter(initialLocation: '/jobs/5/edit', routes: _routes());
      await _pump(
        tester,
        router,
        pageTitle: const PlayxPageTitle(maxItems: null, separator: ' | '),
      );
      expect(titles.last, 'Edit | Job #5 | Jobs');
    });

    testWidgets('runtime labels update the title', (tester) async {
      mockTitles(tester);
      final title = ValueNotifier<String?>(null);
      final router = GoRouter(
        initialLocation: '/jobs/5',
        routes: _routes(
          detailsChild: Scaffold(
            body: ValueListenableBuilder<String?>(
              valueListenable: title,
              builder: (_, value, __) => PlayxBreadcrumbLabel(label: value),
            ),
          ),
        ),
      );
      await _pump(tester, router,
          pageTitle: const PlayxPageTitle(appName: 'Dashboard'));
      expect(titles.last, 'Job #5 · Jobs · Dashboard');

      title.value = 'Plumbing repair';
      await tester.pumpAndSettle();
      expect(titles.last, 'Plumbing repair · Jobs · Dashboard');
    });

    testWidgets('custom builder, and null leaves the title unchanged',
        (tester) async {
      mockTitles(tester);
      final router = GoRouter(initialLocation: '/jobs', routes: _routes());
      await _pump(
        tester,
        router,
        pageTitle: PlayxPageTitle(
          builder: (context, items) =>
              items.length > 1 ? 'Deep: ${items.last.label}' : null,
        ),
      );
      expect(titles, isEmpty);

      await _push(tester, router, '/jobs/5');
      expect(titles.last, 'Deep: Job #5');
    });

    testWidgets('app name only when the page has no label', (tester) async {
      mockTitles(tester);
      final router = GoRouter(initialLocation: '/plain', routes: [
        PlayxRoute(
          path: '/plain',
          binding: _B('plain'),
          builder: (_, __) => const Scaffold(),
        ),
      ]);
      await _pump(tester, router,
          pageTitle: const PlayxPageTitle(appName: 'Dashboard'));
      expect(titles.last, 'Dashboard');
    });

    testWidgets('nothing is sent without labels or an app name',
        (tester) async {
      mockTitles(tester);
      final router = GoRouter(initialLocation: '/plain', routes: [
        PlayxRoute(
          path: '/plain',
          binding: _B('plain'),
          builder: (_, __) => const Scaffold(),
        ),
      ]);
      await _pump(tester, router, pageTitle: const PlayxPageTitle());
      expect(titles, isEmpty);
    });

    testWidgets('without pageTitle the title is never touched', (tester) async {
      mockTitles(tester);
      final router = GoRouter(initialLocation: '/jobs', routes: _routes());
      await _pump(tester, router);
      await _push(tester, router, '/jobs/5');
      expect(titles, isEmpty);
    });

    testWidgets('works when the router is booted elsewhere', (tester) async {
      mockTitles(tester);
      final router = GoRouter(initialLocation: '/jobs', routes: _routes());
      await _pump(tester, router,
          pageTitle: const PlayxPageTitle(appName: 'Dashboard'),
          bootElsewhere: true);
      await tester.pumpAndSettle();
      expect(titles.last, 'Jobs · Dashboard');
    });

    testWidgets('PlayxNavigation.pageTitle exposes the applied title',
        (tester) async {
      mockTitles(tester);
      final router = GoRouter(initialLocation: '/jobs', routes: _routes());
      await _pump(tester, router,
          pageTitle: const PlayxPageTitle(appName: 'Dashboard'));
      expect(PlayxNavigation.pageTitle, 'Jobs · Dashboard');

      await tester.pumpWidget(const SizedBox());
      expect(PlayxNavigation.pageTitle, isNull);
    });

    testWidgets('changing pageTitle re-applies it', (tester) async {
      mockTitles(tester);
      final router = GoRouter(initialLocation: '/jobs', routes: _routes());
      Widget app(PlayxPageTitle? title) => PlayxNavigationBuilder(
            router: router,
            pageTitle: title,
            builder: (_) => MaterialApp.router(routerConfig: router),
          );
      await tester.pumpWidget(app(const PlayxPageTitle(appName: 'A')));
      await tester.pumpAndSettle();
      expect(titles.last, 'Jobs · A');

      await tester.pumpWidget(app(const PlayxPageTitle(appName: 'B')));
      await tester.pumpAndSettle();
      expect(titles.last, 'Jobs · B');

      // Removing it stops updates.
      await tester.pumpWidget(app(null));
      await tester.pumpAndSettle();
      final count = titles.length;
      await _push(tester, router, '/jobs/5');
      expect(titles.length, count);
    });
  });

  group('popUntil', () {
    Future<GoRouter> stacked(WidgetTester tester) async {
      final router = GoRouter(initialLocation: '/jobs', routes: _routes());
      await _pump(tester, router);
      await _push(tester, router, '/jobs/5');
      await _push(tester, router, '/jobs/5/edit');
      log.clear();
      return router;
    }

    testWidgets('pops back to a page in the stack with its lifecycle',
        (tester) async {
      await stacked(tester);
      expect(PlayxNavigation.popUntil('/jobs'), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Jobs'), findsOneWidget);
      expect(log, containsAll(['Edit:exit', 'details:exit']));
      expect(log, contains('Jobs:reEnter(popped)'));
      expect(PlayxNavigation.currentState?.matchedLocation, '/jobs');
    });

    testWidgets('stops at a middle page', (tester) async {
      await stacked(tester);
      expect(PlayxNavigation.popUntil('/jobs/5'), isTrue);
      await tester.pumpAndSettle();
      expect(PlayxNavigation.currentState?.matchedLocation, '/jobs/5');
      expect(log, contains('details:reEnter(popped)'));
      expect(log, isNot(contains('details:exit')));
    });

    testWidgets('current page: true and nothing happens', (tester) async {
      await stacked(tester);
      expect(PlayxNavigation.popUntil('/jobs/5/edit'), isTrue);
      await tester.pumpAndSettle();
      expect(log, isEmpty);
    });

    testWidgets('ignores query parameters and fragments', (tester) async {
      await stacked(tester);
      expect(PlayxNavigation.popUntil('/jobs?tab=open#top'), isTrue);
      await tester.pumpAndSettle();
      expect(PlayxNavigation.currentState?.matchedLocation, '/jobs');
    });

    testWidgets('location not in the stack: false, or go with orGo',
        (tester) async {
      await stacked(tester);
      expect(PlayxNavigation.popUntil('/other'), isFalse);
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      expect(PlayxNavigation.currentState?.matchedLocation, '/jobs/5/edit');

      expect(PlayxNavigation.popUntil('/other', orGo: true), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('after a refresh (empty stack) orGo goes to the location',
        (tester) async {
      // Flat routes: a deep link leaves nothing to pop.
      final router = GoRouter(initialLocation: '/jobs/5/edit', routes: [
        _route('/jobs', 'Jobs'),
        _route('/jobs/:id/edit', 'Edit'),
      ]);
      await _pump(tester, router);
      expect(PlayxNavigation.popUntil('/jobs'), isFalse);
      expect(PlayxNavigation.popUntil('/jobs', orGo: true), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Jobs'), findsOneWidget);
    });

    testWidgets('popUntilNamed with path parameters', (tester) async {
      await stacked(tester);
      expect(
        PlayxNavigation.popUntilNamed('details', pathParameters: {'id': '5'}),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(PlayxNavigation.currentState?.matchedLocation, '/jobs/5');

      expect(PlayxNavigation.popUntilNamed('jobs'), isTrue);
      await tester.pumpAndSettle();
      expect(PlayxNavigation.currentState?.matchedLocation, '/jobs');
    });

    testWidgets('the page closest to the top wins', (tester) async {
      final router = GoRouter(initialLocation: '/jobs', routes: _routes());
      await _pump(tester, router);
      for (final l in ['/jobs/5', '/other', '/jobs/5', '/other']) {
        await _push(tester, router, l);
      }
      expect(PlayxNavigation.popUntil('/jobs/5'), isTrue);
      await tester.pumpAndSettle();
      expect(PlayxNavigation.currentState?.matchedLocation, '/jobs/5');
      // Only the top /other was removed: the older /other and /jobs/5 remain.
      expect(PlayxNavigation.playxRouter.pageStack.length, 4);
    });
  });
}
