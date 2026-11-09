import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_navigation/playx_navigation.dart';

final List<String> log = [];

class _B extends PlayxBinding {
  _B(this.name, {this.label, this.runtimeLabel});
  final String name;
  final String? label;
  String? runtimeLabel;

  @override
  String? breadcrumb(BuildContext context, GoRouterState state) => label;

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    log.add('$name:enter');
    if (runtimeLabel != null) {
      PlayxNavigation.setBreadcrumbLabel(context, runtimeLabel);
    }
  }

  @override
  Future<void> onHidden(BuildContext context) async => log.add('$name:hidden');

  @override
  Future<void> onReEnter(
          BuildContext context, GoRouterState? state, bool popped) async =>
      log.add('$name:reEnter${popped ? '(popped)' : ''}');

  @override
  Future<void> onExit(BuildContext context) async => log.add('$name:exit');
}

/// A page showing the current breadcrumbs as text, for assertions.
Widget _page(String text) => Scaffold(body: Text(text));

String _trail(BuildContext context,
        [PlayxBreadcrumbMode mode = PlayxBreadcrumbMode.hierarchy,
        String? root]) =>
    PlayxNavigation.breadcrumbs(context, mode: mode, rootLocation: root)
        .map((i) => i.isCurrent ? '[${i.label}]' : i.label)
        .join(' > ');

PlayxRoute _route(
  String path,
  String? label, {
  List<RouteBase> routes = const [],
  PlayxBinding? binding,
  PlayxParentLocation? parentLocation,
  Widget? child,
}) =>
    PlayxRoute(
      path: path,
      binding: binding ?? _B(label ?? path),
      breadcrumb: label == null ? null : (_, __) => label,
      parentLocation: parentLocation,
      builder: (_, __) => child ?? _page(label ?? path),
      routes: routes,
    );

/// Jobs > Job #id > Edit, nested.
List<RouteBase> _jobsRoutes({Widget? detailsChild}) => [
      _route('/home', 'Home'),
      _route('/jobs', 'Jobs', routes: [
        PlayxRoute(
          path: ':id',
          binding: _B('details'),
          breadcrumb: (_, s) => 'Job #${s.pathParameters['id']}',
          builder: (_, __) => detailsChild ?? _page('details'),
          routes: [_route('edit', 'Edit')],
        ),
      ]),
    ];

late BuildContext _ctx;

/// Header placed above the router, like a persistent shell header.
Future<void> _pump(WidgetTester tester, GoRouter router,
    {Widget Function(BuildContext)? header}) async {
  await tester.pumpWidget(PlayxNavigationBuilder(
    router: router,
    builder: (_) => MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => Column(children: [
        Builder(builder: (c) {
          _ctx = c;
          return header?.call(c) ?? const SizedBox();
        }),
        Expanded(child: child!),
      ]),
    ),
  ));
  await tester.pumpAndSettle();
  log.clear();
}

void main() {
  setUp(log.clear);

  group('hierarchy', () {
    testWidgets('nested routes, deep linked: full trail', (tester) async {
      final router =
          GoRouter(initialLocation: '/jobs/5/edit', routes: _jobsRoutes());
      await _pump(tester, router);
      expect(_trail(_ctx), 'Jobs > Job #5 > [Edit]');
      expect(_trail(_ctx, PlayxBreadcrumbMode.hierarchy, '/home'),
          'Home > Jobs > Job #5 > [Edit]');
    });

    testWidgets('rootLocation is not duplicated', (tester) async {
      final router = GoRouter(initialLocation: '/home', routes: _jobsRoutes());
      await _pump(tester, router);
      expect(_trail(_ctx, PlayxBreadcrumbMode.hierarchy, '/home'), '[Home]');
    });

    testWidgets('flat routes and explicit parentLocation', (tester) async {
      final router = GoRouter(initialLocation: '/edit-job/5', routes: [
        _route('/jobs', 'Jobs'),
        _route('/jobs/:id', 'Job'),
        _route('/edit-job/:id', 'Edit',
            parentLocation: (s) => '/jobs/${s.pathParameters['id']}'),
      ]);
      await _pump(tester, router);
      expect(_trail(_ctx), 'Jobs > Job > [Edit]');
    });

    testWidgets('unlabeled routes are skipped but walked through',
        (tester) async {
      final router = GoRouter(initialLocation: '/a/b/c', routes: [
        _route('/a', 'A', routes: [
          _route('b', null, routes: [_route('c', 'C')]),
        ]),
      ]);
      await _pump(tester, router);
      expect(_trail(_ctx), 'A > [C]');
    });

    testWidgets('tapping a crumb goes there with the normal lifecycle',
        (tester) async {
      final router = GoRouter(initialLocation: '/jobs', routes: _jobsRoutes());
      await _pump(tester, router);
      unawaited(router.push('/jobs/5'));
      await tester.pumpAndSettle();
      unawaited(router.push('/jobs/5/edit'));
      await tester.pumpAndSettle();
      log.clear();

      final items = PlayxNavigation.breadcrumbs(_ctx);
      expect(items.last.isCurrent, isTrue);
      items.last.navigate(); // current: no-op
      await tester.pumpAndSettle();
      expect(log, isEmpty);

      items.first.navigate();
      await tester.pumpAndSettle();
      expect(find.text('Jobs'), findsOneWidget);
      expect(log, containsAll(['Edit:exit', 'details:exit']));
      expect(log, contains('Jobs:reEnter(popped)'));
    });
  });

  group('shellBranch', () {
    GoRouter shellRouter(String initial) => GoRouter(
          initialLocation: initial,
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (_, __, shell) => shell,
              branches: [
                StatefulShellBranch(routes: [_route('/home', 'Home')]),
                StatefulShellBranch(routes: [_jobsRoutes()[1]]),
              ],
            ),
            _route('/job/:id', 'Job page', parentLocation: (_) => '/jobs'),
            _route('/settings', 'Settings'),
          ],
        );

    testWidgets('starts at the branch root', (tester) async {
      await _pump(tester, shellRouter('/jobs/5/edit'));
      expect(_trail(_ctx, PlayxBreadcrumbMode.shellBranch, '/home'),
          'Jobs > Job #5 > [Edit]');
      // hierarchy with a root for comparison:
      expect(_trail(_ctx, PlayxBreadcrumbMode.hierarchy, '/home'),
          'Home > Jobs > Job #5 > [Edit]');
    });

    testWidgets('page above the shell stops at the branch root parent',
        (tester) async {
      await _pump(tester, shellRouter('/job/5'));
      expect(
          _trail(_ctx, PlayxBreadcrumbMode.shellBranch), 'Jobs > [Job page]');
    });

    testWidgets('outside any shell behaves like hierarchy', (tester) async {
      await _pump(tester, shellRouter('/settings'));
      expect(_trail(_ctx, PlayxBreadcrumbMode.shellBranch), '[Settings]');
    });
  });

  group('history', () {
    testWidgets('stack order, tap pops back to that page', (tester) async {
      final router = GoRouter(initialLocation: '/jobs', routes: [
        ..._jobsRoutes(),
        _route('/other', 'Other'),
      ]);
      await _pump(tester, router);
      for (final location in ['/jobs/5', '/other', '/jobs/6']) {
        unawaited(router.push(location));
        await tester.pumpAndSettle();
      }
      expect(_trail(_ctx, PlayxBreadcrumbMode.history),
          'Jobs > Job #5 > Other > [Job #6]');
      log.clear();

      final items =
          PlayxNavigation.breadcrumbs(_ctx, mode: PlayxBreadcrumbMode.history);
      items[1].navigate(); // Job #5
      await tester.pumpAndSettle();
      expect(_trail(_ctx, PlayxBreadcrumbMode.history), 'Jobs > [Job #5]');
      expect(log, contains('details:reEnter(popped)'));
      expect(log.where((e) => e.endsWith(':exit')).length, 2);
    });
  });

  group('labels', () {
    testWidgets('binding label, route label wins, runtime label wins',
        (tester) async {
      final c = _B('c', label: 'Binding C', runtimeLabel: 'Live C');
      final router = GoRouter(initialLocation: '/a/b', routes: [
        PlayxRoute(
          path: '/a',
          binding: _B('a', label: 'From binding'),
          builder: (_, __) => _page('a'),
          routes: [
            PlayxRoute(
              path: 'b',
              binding: _B('b', label: 'Binding B'),
              breadcrumb: (_, __) => 'Route B',
              builder: (_, __) => _page('b'),
              routes: [
                PlayxRoute(
                  path: 'c',
                  binding: c,
                  builder: (_, __) => _page('c'),
                ),
              ],
            ),
          ],
        ),
      ]);
      await _pump(tester, router);
      // Ancestor /a is not entered (deep link), its binding label still works.
      expect(_trail(_ctx), 'From binding > [Route B]');

      unawaited(router.push('/a/b/c'));
      await tester.pumpAndSettle();
      expect(_trail(_ctx), 'From binding > Route B > [Live C]');

      router.pop();
      await tester.pumpAndSettle();
      // Runtime label removed when c's scope is disposed: re-entering
      // without setting it shows the binding label again.
      c.runtimeLabel = null;
      unawaited(router.push('/a/b/c'));
      await tester.pumpAndSettle();
      expect(_trail(_ctx), 'From binding > Route B > [Binding C]');
    });

    testWidgets('PlayxBreadcrumbLabel renames a page, also as an ancestor',
        (tester) async {
      final title = ValueNotifier<String?>(null);
      final router = GoRouter(
        initialLocation: '/jobs/5',
        routes: _jobsRoutes(
          detailsChild: Scaffold(
            body: ValueListenableBuilder<String?>(
              valueListenable: title,
              builder: (_, value, __) => PlayxBreadcrumbLabel(label: value),
            ),
          ),
        ),
      );
      await _pump(tester, router,
          header: (_) => const PlayxBreadcrumbs(maxItems: null));
      expect(find.text('Job #5'), findsOneWidget);

      // Data loads: label set during build, no errors.
      title.value = 'Plumbing repair';
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Plumbing repair'), findsOneWidget);

      unawaited(router.push('/jobs/5/edit'));
      await tester.pumpAndSettle();
      expect(_trail(_ctx), 'Jobs > Plumbing repair > [Edit]');

      router.go('/jobs');
      await tester.pumpAndSettle();
      router.go('/jobs/5/edit');
      await tester.pumpAndSettle();
      // The details page that set the label is gone.
      expect(_trail(_ctx), 'Jobs > Job #5 > [Edit]');
    });

    testWidgets('localized labels use the header context', (tester) async {
      final router = GoRouter(initialLocation: '/x', routes: [
        PlayxRoute(
          path: '/x',
          breadcrumb: (context, _) =>
              Localizations.localeOf(context).languageCode,
          builder: (_, __) => _page('x'),
        ),
      ]);
      await _pump(tester, router, header: (_) => const PlayxBreadcrumbs());
      expect(find.text('en'), findsOneWidget);
    });
  });

  group('widgets', () {
    testWidgets('PlayxBreadcrumbs rebuilds on navigation, taps navigate',
        (tester) async {
      final router = GoRouter(initialLocation: '/jobs', routes: _jobsRoutes());
      await _pump(tester, router,
          header: (_) => const PlayxBreadcrumbs(hideIfSingle: true));
      expect(find.byType(InkWell), findsNothing); // single item hidden

      unawaited(router.push('/jobs/5'));
      await tester.pumpAndSettle();
      expect(find.text('Job #5'), findsNWidgets(1));
      expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);

      await tester.tap(find.widgetWithText(InkWell, 'Jobs'));
      await tester.pumpAndSettle();
      expect(log, contains('details:exit'));
    });

    testWidgets('collapses long trails; the ellipsis menu navigates',
        (tester) async {
      final router = GoRouter(initialLocation: '/a/b/c/d/e', routes: [
        _route('/a', 'A', routes: [
          _route('b', 'B', routes: [
            _route('c', 'C', routes: [
              _route('d', 'D', routes: [_route('e', 'E')]),
            ]),
          ]),
        ]),
      ]);
      await _pump(tester, router,
          header: (_) => PlayxBreadcrumbs(
                separator: const Text('/'),
                itemBuilder: (_, item) => Text('<${item.label}>'),
              ));
      // first, …, last 3
      expect(find.text('<A>'), findsOneWidget);
      expect(find.text('…'), findsOneWidget);
      expect(find.text('<B>'), findsNothing);
      for (final l in ['<C>', '<D>', '<E>']) {
        expect(find.text(l), findsOneWidget);
      }
      expect(find.text('/'), findsNWidgets(4));

      await tester.tap(find.text('…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B').last);
      await tester.pumpAndSettle();
      expect(_trail(_ctx), 'A > [B]');
    });

    testWidgets('PlayxBreadcrumbsBuilder feeds a custom widget',
        (tester) async {
      final router =
          GoRouter(initialLocation: '/jobs/5/edit', routes: _jobsRoutes());
      await _pump(tester, router,
          header: (_) => PlayxBreadcrumbsBuilder(
                mode: PlayxBreadcrumbMode.hierarchy,
                rootLocation: '/home',
                builder: (_, items) =>
                    Text(items.map((i) => i.label).join(' / ')),
              ));
      expect(find.text('Home / Jobs / Job #5 / Edit'), findsOneWidget);
    });
  });
}
