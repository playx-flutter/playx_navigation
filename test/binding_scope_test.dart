import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_navigation/playx_navigation.dart';

/// Minimal stand-in for GetX's registry with the same `put` semantics:
/// putting a type (+ tag) that is already registered keeps the old instance.
class _Registry {
  final Map<String, Object> _items = {};
  String _key(Type t, String? tag) => '$t#${tag ?? ''}';

  T put<T extends Object>(T value, {String? tag}) =>
      _items.putIfAbsent(_key(T, tag), () => value) as T;
  T find<T extends Object>({String? tag}) {
    final value = _items[_key(T, tag)];
    if (value == null) throw StateError('$T ($tag) not registered');
    return value as T;
  }

  bool isRegistered<T extends Object>({String? tag}) =>
      _items.containsKey(_key(T, tag));
  void delete<T extends Object>({String? tag}) => _items.remove(_key(T, tag));
}

final _get = _Registry();
final List<String> log = [];

class Job {
  final int id;
  const Job(this.id);
}

class JobDetailsController {
  final int jobId;
  final Job? job;
  bool disposed = false;
  JobDetailsController(this.jobId, this.job);
}

abstract class JobFormController {
  String get kind;
}

class CreateJobController implements JobFormController {
  @override
  String get kind => 'create';
}

class EditJobController implements JobFormController {
  final int id;
  EditJobController(this.id);
  @override
  String get kind => 'edit:$id';
}

class JobsBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async =>
      log.add('jobs:enter');

  @override
  Future<void> onExit(BuildContext context) async => log.add('jobs:exit');
}

/// Job details the "scoped" way: validation in redirect, controller kept in
/// the page's scope, works without `extra` (web refresh / deep link).
class JobDetailsBinding extends PlayxBinding {
  final List<String> seenScopeIds = [];

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    log.add('details:redirect');
    return state.intPathParam('id') == null ? '/jobs' : null;
  }

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    final scope = PlayxScope.of(context);
    seenScopeIds.add(scope.id);
    scope.put(
      JobDetailsController(state.intPathParam('id')!, state.extraAs<Job>()),
      dispose: (c) => c.disposed = true,
    );
    log.add('details:enter:${state.intPathParam('id')}');
  }

  @override
  Future<void> onHidden(BuildContext context) async {
    seenScopeIds.add(PlayxScope.of(context).id);
  }

  @override
  Future<void> onReEnter(
      BuildContext context, GoRouterState? state, bool wasPopped) async {
    seenScopeIds.add(PlayxScope.of(context).id);
  }

  @override
  Future<void> onExit(BuildContext context) async {
    final scope = PlayxScope.of(context);
    seenScopeIds.add(scope.id);
    // Scope values are still available in onExit; disposed right after.
    log.add('details:exit:${scope.get<JobDetailsController>().jobId}');
  }
}

/// The same binding written with a global registry and per-page tags.
class TaggedDetailsBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    final scope = PlayxScope.of(context);
    _get.put(JobDetailsController(state.intPathParam('id')!, null),
        tag: scope.id);
    scope.onDispose(() => _get.delete<JobDetailsController>(tag: scope.id));
  }

  @override
  Future<void> onExit(BuildContext context) async {}
}

/// The same binding written like the original (untagged global registry).
class UntaggedDetailsBinding extends PlayxBinding {
  final bool guardWithActiveScopes;
  UntaggedDetailsBinding({this.guardWithActiveScopes = false});

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    _get.put(JobDetailsController(state.intPathParam('id')!, null));
  }

  @override
  Future<void> onExit(BuildContext context) async {
    if (guardWithActiveScopes && activeScopes.isNotEmpty) return;
    _get.delete<JobDetailsController>();
  }
}

class CreateJobBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    PlayxScope.of(context).put<JobFormController>(CreateJobController());
  }

  @override
  Future<void> onExit(BuildContext context) async {}
}

class EditJobBinding extends PlayxBinding {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      state.intPathParam('id') == null ? '/jobs' : null;

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    PlayxScope.of(context)
        .put<JobFormController>(EditJobController(state.intPathParam('id')!));
  }

  @override
  Future<void> onExit(BuildContext context) async {}
}

/// A page that reads its controller from the scope, like a real view would.
class _FormView extends StatelessWidget {
  const _FormView();

  @override
  Widget build(BuildContext context) {
    final form = PlayxScope.of(context).get<JobFormController>();
    return Scaffold(body: Text('form:${form.kind}'));
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView();

  @override
  Widget build(BuildContext context) {
    final c = PlayxScope.of(context).get<JobDetailsController>();
    return Scaffold(body: Text('details:${c.jobId}:${c.job != null}'));
  }
}

PlayxBinding? _lastDetailsBinding;

GoRouter _jobsRouter({
  required PlayxBinding details,
  String initial = '/jobs',
  bool detailsTopLevel = false,
}) {
  _lastDetailsBinding = details;
  final detailsRoute = PlayxRoute(
    path: detailsTopLevel ? '/job/:id' : 'details/:id',
    binding: details,
    builder: (_, __) => details is JobDetailsBinding
        ? const _DetailsView()
        : const Scaffold(body: Text('details')),
  );
  return GoRouter(initialLocation: initial, routes: [
    PlayxRoute(
      path: '/jobs',
      binding: JobsBinding(),
      builder: (_, __) => const Scaffold(body: Text('jobs')),
      routes: [
        if (!detailsTopLevel) detailsRoute,
        PlayxRoute(
          path: 'create',
          binding: CreateJobBinding(),
          builder: (_, __) => const _FormView(),
        ),
        PlayxRoute(
          path: 'edit/:id',
          binding: EditJobBinding(),
          builder: (_, __) => const _FormView(),
        ),
      ],
    ),
    if (detailsTopLevel) detailsRoute,
  ]);
}

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(PlayxNavigationBuilder(
    router: router,
    builder: (_) => MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  log.clear();
}

Future<void> _push(WidgetTester tester, GoRouter router, String location,
    {Object? extra}) async {
  unawaited(router.push(location, extra: extra));
  await tester.pumpAndSettle();
}

Future<void> _pop(WidgetTester tester, GoRouter router) async {
  router.pop();
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    log.clear();
    _get._items.clear();
  });

  group('PlayxScope', () {
    testWidgets('one scope per visit, same in every callback and widget',
        (tester) async {
      final details = JobDetailsBinding();
      final router = _jobsRouter(details: details);
      await _pump(tester, router);

      await _push(tester, router, '/jobs/details/1', extra: const Job(1));
      expect(find.text('details:1:true'), findsOneWidget);
      final scope = details.activeScopes.single;
      expect(scope.isActive, isTrue);

      await _push(tester, router, '/jobs/create');
      expect(scope.pageState, PlayxPageState.hidden);
      await _pop(tester, router);
      await _pop(tester, router);

      // enter, hidden, reEnter, hidden, exit: all saw the same scope.
      expect(details.seenScopeIds, List.filled(5, scope.id));
      expect(details.activeScopes, isEmpty);
      expect(scope.isDisposed, isTrue);
      expect(log, contains('details:exit:1'));
    });

    testWidgets('stacked details of the same route get separate scopes',
        (tester) async {
      final details = JobDetailsBinding();
      final router = _jobsRouter(details: details);
      await _pump(tester, router);

      await _push(tester, router, '/jobs/details/1');
      final first = details.activeScopes.single;
      final firstController = first.get<JobDetailsController>();
      await _push(tester, router, '/jobs/details/2');
      expect(details.activeScopes.length, 2);
      expect(find.text('details:2:false'), findsOneWidget);

      await _pop(tester, router);
      expect(details.activeScopes, [first]);
      expect(firstController.disposed, isFalse);
      expect(find.text('details:1:false'), findsOneWidget);
      expect(log, [
        'details:redirect',
        'details:enter:1',
        'details:redirect',
        'details:enter:2',
        'details:exit:2'
      ]);
    });

    testWidgets('replace to another id: old scope disposed before new enter',
        (tester) async {
      final details = JobDetailsBinding();
      final router = _jobsRouter(details: details);
      await _pump(tester, router);
      await _push(tester, router, '/jobs/details/1');
      final old = details.activeScopes.single;
      final oldController = old.get<JobDetailsController>();

      unawaited(router.replace('/jobs/details/2'));
      await tester.pumpAndSettle();
      final current = details.activeScopes.single;
      expect(current.id, isNot(old.id));
      expect(oldController.disposed, isTrue);
      expect(log.where((e) => !e.endsWith('redirect')),
          ['details:enter:1', 'details:exit:1', 'details:enter:2']);
      expect(find.text('details:2:false'), findsOneWidget);
    });

    testWidgets('create over edit: each form page keeps its own controller',
        (tester) async {
      final router = _jobsRouter(details: JobDetailsBinding());
      await _pump(tester, router);

      await _push(tester, router, '/jobs/edit/3');
      expect(find.text('form:edit:3'), findsOneWidget);
      await _push(tester, router, '/jobs/create');
      expect(find.text('form:create'), findsOneWidget);
      await _pop(tester, router);
      expect(find.text('form:edit:3'), findsOneWidget);
    });

    testWidgets('scope id as a registry tag keeps stacked controllers apart',
        (tester) async {
      final router = _jobsRouter(details: TaggedDetailsBinding());
      await _pump(tester, router);
      await _push(tester, router, '/jobs/details/1');
      await _push(tester, router, '/jobs/details/2');
      final scopes = _lastDetailsBinding!.activeScopes;
      expect(_get.find<JobDetailsController>(tag: scopes[0].id).jobId, 1);
      expect(_get.find<JobDetailsController>(tag: scopes[1].id).jobId, 2);

      await _pop(tester, router);
      expect(_get.find<JobDetailsController>(tag: scopes[0].id).jobId, 1);
      expect(
          _get.isRegistered<JobDetailsController>(tag: scopes[1].id), isFalse);
    });

    testWidgets('untagged registry: the original binding loses the controller',
        (tester) async {
      final router = _jobsRouter(details: UntaggedDetailsBinding());
      await _pump(tester, router);
      await _push(tester, router, '/jobs/details/1');
      await _push(tester, router, '/jobs/details/2');
      // put() kept details 1's controller, and popping details 2 deletes it.
      expect(_get.find<JobDetailsController>().jobId, 1);
      await _pop(tester, router);
      expect(_get.isRegistered<JobDetailsController>(), isFalse);
    });

    testWidgets('activeScopes lets an untagged binding skip shared cleanup',
        (tester) async {
      final router = _jobsRouter(
          details: UntaggedDetailsBinding(guardWithActiveScopes: true));
      await _pump(tester, router);
      await _push(tester, router, '/jobs/details/1');
      await _push(tester, router, '/jobs/details/2');
      await _pop(tester, router);
      expect(_get.isRegistered<JobDetailsController>(), isTrue);
      await _pop(tester, router);
      expect(_get.isRegistered<JobDetailsController>(), isFalse);
    });

    testWidgets('PlayxScope.of throws outside a page with a binding',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }));
      expect(PlayxScope.maybeOf(ctx), isNull);
      expect(() => PlayxScope.of(ctx), throwsStateError);
    });
  });

  group('PlayxBinding.redirect', () {
    testWidgets('invalid id redirects before the page is built',
        (tester) async {
      final details = JobDetailsBinding();
      final router = _jobsRouter(details: details);
      await _pump(tester, router);

      await _push(tester, router, '/jobs/details/abc');
      expect(find.text('jobs'), findsOneWidget);
      // The details page is never built, so onEnter/onExit never run.
      // (A redirected push pushes the redirect target, like go_router does.)
      expect(log.where((e) => e.startsWith('details')), ['details:redirect']);
      expect(details.activeScopes, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('parent binding redirect does not run for child routes',
        (tester) async {
      var parentRedirects = 0;
      final parent = _RedirectBinding((_) {
        parentRedirects++;
        return null;
      });
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: parent,
          builder: (_, __) => const Text('home'),
          routes: [
            PlayxRoute(
              path: 'child',
              binding: _RedirectBinding((_) => null),
              builder: (_, __) => const Text('child'),
            ),
          ],
        ),
      ]);
      await _pump(tester, router);
      expect(parentRedirects, 1);
      router.go('/child');
      await tester.pumpAndSettle();
      expect(parentRedirects, 1);
    });

    testWidgets('async binding redirect', (tester) async {
      final router = GoRouter(routes: [
        PlayxRoute(path: '/', builder: (_, __) => const Text('home')),
        PlayxRoute(
          path: '/login',
          builder: (_, __) => const Text('login'),
        ),
        PlayxRoute(
          path: '/account',
          binding: _RedirectBinding((_) async => '/login'),
          builder: (_, __) => const Text('account'),
        ),
      ]);
      await _pump(tester, router);
      router.go('/account');
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);
    });
  });

  group('web', () {
    testWidgets('deep link / refresh: extra is missing, page still works',
        (tester) async {
      final details = JobDetailsBinding();
      final router = _jobsRouter(details: details, initial: '/jobs/details/9');
      await _pump(tester, router);
      expect(find.text('details:9:false'), findsOneWidget);
    });

    testWidgets('popOrGo falls back when there is nothing to pop',
        (tester) async {
      final router = _jobsRouter(
        details: JobDetailsBinding(),
        initial: '/job/9',
        detailsTopLevel: true,
      );
      await _pump(tester, router);
      expect(PlayxNavigation.canPop(), isFalse);

      PlayxNavigation.popOrGo('/jobs');
      await tester.pumpAndSettle();
      expect(find.text('jobs'), findsOneWidget);
      expect(log, contains('details:exit:9'));
    });

    testWidgets('browser back and forward behave like pop and push',
        (tester) async {
      final details = JobDetailsBinding();
      final router = _jobsRouter(details: details);
      await _pump(tester, router);

      // What the browser stores in its history for each entry.
      RouteInformation entry() => router.routeInformationParser
          .restoreRouteInformation(router.routerDelegate.currentConfiguration)!;
      final jobsEntry = entry();
      await _push(tester, router, '/jobs/details/1', extra: const Job(1));
      final detailsEntry = entry();
      log.clear();

      // Back button.
      router.routeInformationProvider.didPushRouteInformation(jobsEntry);
      await tester.pumpAndSettle();
      expect(find.text('jobs'), findsOneWidget);
      expect(log, ['details:exit:1']);
      expect(details.activeScopes, isEmpty);
      log.clear();

      // Forward button: a fresh details page.
      router.routeInformationProvider.didPushRouteInformation(detailsEntry);
      await tester.pumpAndSettle();
      expect(find.textContaining('details:1:'), findsOneWidget);
      expect(
          log.where((e) => e.startsWith('details:enter')), ['details:enter:1']);
      expect(details.activeScopes.length, 1);
    });
  });

  test('extraAs and int params never throw', () {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox()),
    ]);
    GoRouterState state(Object? extra, String id) => GoRouterState(
          router.configuration,
          uri: Uri.parse('/x/$id?page=2'),
          matchedLocation: '/x/$id',
          fullPath: '/x/:id',
          pathParameters: {'id': id},
          pageKey: const ValueKey('k'),
          extra: extra,
        );
    expect(state(const Job(1), '1').extraAs<Job>()?.id, 1);
    expect(state({'id': 1}, '1').extraAs<Job>(), isNull);
    expect(state(null, '1').extraAs<Job>(), isNull);
    expect(state(null, '7').intPathParam('id'), 7);
    expect(state(null, 'abc').intPathParam('id'), isNull);
    expect(state(null, '1').intQueryParam('page'), 2);
    expect(state(null, '1').intQueryParam('missing'), isNull);
  });
}

class _RedirectBinding extends PlayxBinding {
  final FutureOr<String?> Function(GoRouterState state) onRedirect;
  _RedirectBinding(this.onRedirect);

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      onRedirect(state);

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {}

  @override
  Future<void> onExit(BuildContext context) async {}
}
