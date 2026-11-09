import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_navigation/playx_navigation.dart';

/// Ordered log of everything that happens, across controllers and bindings.
final List<String> log = [];

/// Minimal stand-in for GetX's registry (type + tag).
final Map<String, Object> registry = {};
String _key(Type t, String? tag) => '$t#${tag ?? ''}';

class Job {
  final int id;
  const Job(this.id);
}

class JobsController with PlayxPageLifecycle {
  JobsController() {
    log.add('jobs:create');
  }

  int refreshes = 0;
  bool closed = false;

  void refresh() => refreshes++;

  @override
  void onPageEnter(GoRouterState state) => log.add('jobs:pageEnter');

  @override
  void onPageHidden() => log.add('jobs:pageHidden');

  @override
  void onPageReEnter(GoRouterState? state, bool wasPopped) =>
      log.add('jobs:pageReEnter${wasPopped ? '(popped)' : ''}');

  @override
  void onPageExit() => log.add('jobs:pageExit');
}

class DetailsController with PlayxPageLifecycle {
  DetailsController(this.id, this.job) {
    log.add('details:create:$id');
  }

  final int id;
  Job? job;
  bool closed = false;

  @override
  Future<void> onPageEnter(GoRouterState state) async {
    // Load by id when extra is missing (web refresh / deep link).
    job ??= Job(id);
    log.add('details:pageEnter:$id');
  }

  @override
  void onPageExit() => log.add('details:pageExit:$id');
}

/// Plain controller without lifecycle hooks.
class CounterController {
  int value = 0;
}

abstract class JobFormController {
  String get kind;
}

class CreateJobController implements JobFormController {
  @override
  String get kind => 'create';
}

class EditJobController implements JobFormController {
  EditJobController(this.id);
  final int id;
  @override
  String get kind => 'edit:$id';
}

class LoggingBinding extends PlayxBinding {
  LoggingBinding(this.name);
  final String name;

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    // The route controller already exists when the binding enters.
    final c = PlayxScope.of(context).maybeGet<JobsController>();
    log.add('$name:enter(controller:${c != null})');
  }

  @override
  Future<void> onHidden(BuildContext context) async => log.add('$name:hidden');

  @override
  Future<void> onReEnter(BuildContext context, GoRouterState? state,
          bool wasPoppedAndReentered) async =>
      log.add('$name:reEnter');

  @override
  Future<void> onExit(BuildContext context) async {
    final c = PlayxScope.of(context).maybeGet<JobsController>();
    log.add('$name:exit(controller:${c != null})');
  }
}

// ---------- Views ----------

class JobsView extends PlayxView<JobsController> {
  const JobsView({super.key});

  @override
  Widget buildView(BuildContext context, JobsController controller) {
    return Scaffold(
      body: Column(children: [
        Text('jobs:${identityHashCode(controller)}'),
        const BuildJobsList(),
        TextButton(onPressed: controller.refresh, child: const Text('refresh')),
      ]),
    );
  }
}

/// A child widget, as if in a separate file.
class BuildJobsList extends PlayxView<JobsController> {
  const BuildJobsList({super.key});

  @override
  Widget buildView(BuildContext context, JobsController controller) {
    return Column(children: [
      Text('list:${identityHashCode(controller)}'),
      const _PlainChild(),
    ]);
  }
}

/// A plain widget using the context extension.
class _PlainChild extends StatelessWidget {
  const _PlainChild();

  @override
  Widget build(BuildContext context) {
    final c = context.controller<JobsController>();
    return Text('plain:${identityHashCode(c)}');
  }
}

class DetailsView extends PlayxView<DetailsController> {
  const DetailsView({super.key});

  @override
  Widget buildView(BuildContext context, DetailsController controller) =>
      Scaffold(body: Text('details:${controller.id}:${controller.job?.id}'));
}

class JobFormView extends PlayxView<JobFormController> {
  const JobFormView({super.key});

  @override
  Widget buildView(BuildContext context, JobFormController controller) =>
      Scaffold(body: Text('form:${controller.kind}'));
}

class CounterView extends PlayxView<CounterController> {
  const CounterView({super.key});

  @override
  Widget buildView(BuildContext context, CounterController controller) =>
      Scaffold(body: Text('counter:${controller.value}'));
}

// ---------- Helpers ----------

PlayxRoute<DetailsController> _detailsRoute({
  String path = 'details/:id',
  bool waitForBinding = true,
}) =>
    PlayxRoute<DetailsController>(
      path: path,
      controller: (context, state) =>
          DetailsController(state.intPathParam('id')!, state.extraAs<Job>()),
      disposeController: (c) {
        c.closed = true;
        log.add('details:dispose:${c.id}');
      },
      waitForBinding: waitForBinding,
      loadingWidget: const Text('loading'),
      builder: (_, __) => const DetailsView(),
    );

GoRouter _router({
  String initial = '/jobs',
  PlayxBinding? jobsBinding,
  bool detailsWait = true,
}) {
  return GoRouter(initialLocation: initial, routes: [
    PlayxRoute<JobsController>(
      path: '/jobs',
      binding: jobsBinding,
      controller: (_, __) => JobsController(),
      disposeController: (c) {
        c.closed = true;
        log.add('jobs:dispose');
      },
      builder: (_, __) => const JobsView(),
      routes: [
        _detailsRoute(waitForBinding: detailsWait),
        PlayxRoute<CreateJobController>(
          path: 'create',
          controller: (_, __) => CreateJobController(),
          builder: (_, __) => const JobFormView(),
        ),
        PlayxRoute<EditJobController>(
          path: 'edit/:id',
          controller: (_, state) =>
              EditJobController(state.intPathParam('id')!),
          builder: (_, __) => const JobFormView(),
        ),
      ],
    ),
    PlayxRoute(path: '/other', builder: (_, __) => const Text('other')),
  ]);
}

Future<void> _pump(WidgetTester tester, GoRouter router,
    {PlayxPageConfig? config}) async {
  await tester.pumpWidget(PlayxNavigationBuilder(
    router: router,
    config: config,
    builder: (_) => MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
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

List<String> _take() {
  final r = List<String>.of(log);
  log.clear();
  return r;
}

void main() {
  setUp(() {
    log.clear();
    registry.clear();
  });

  group('route controller', () {
    testWidgets('created once, shared by the view, children and context',
        (tester) async {
      await _pump(tester, _router());
      expect(_take(), ['jobs:create', 'jobs:pageEnter']);

      final id = find.textContaining('jobs:').evaluate().single.widget as Text;
      final hash = id.data!.split(':').last;
      expect(find.text('list:$hash'), findsOneWidget);
      expect(find.text('plain:$hash'), findsOneWidget);

      // Closures in buildView use the same controller.
      await tester.tap(find.text('refresh'));
      final c = PlayxScope.of(tester.element(find.byType(BuildJobsList)))
          .get<JobsController>();
      expect(c.refreshes, 1);
    });

    testWidgets('full lifecycle order without a binding', (tester) async {
      final router = _router();
      await _pump(tester, router);
      _take();

      await _push(tester, router, '/jobs/details/1', extra: const Job(1));
      expect(_take(), [
        'jobs:pageHidden',
        'details:create:1',
        'details:pageEnter:1',
      ]);
      expect(find.text('details:1:1'), findsOneWidget);

      await _pop(tester, router);
      expect(_take(), [
        'jobs:pageReEnter(popped)',
        'details:pageExit:1',
        'details:dispose:1',
      ]);

      router.go('/other');
      await tester.pumpAndSettle();
      expect(_take(), ['jobs:pageHidden', 'jobs:pageExit', 'jobs:dispose']);
    });

    testWidgets('lifecycle order with a binding', (tester) async {
      final router = _router(jobsBinding: LoggingBinding('B'));
      await _pump(tester, router);
      expect(_take(), [
        'jobs:create',
        'B:enter(controller:true)',
        'jobs:pageEnter',
      ]);

      await _push(tester, router, '/jobs/create');
      expect(_take(), ['B:hidden', 'jobs:pageHidden']);
      await _pop(tester, router);
      expect(_take(), ['B:reEnter', 'jobs:pageReEnter(popped)']);

      router.go('/other');
      await tester.pumpAndSettle();
      expect(_take(), [
        'B:hidden',
        'jobs:pageHidden',
        'B:exit(controller:true)',
        'jobs:pageExit',
        'jobs:dispose',
      ]);
    });

    testWidgets('const views on stacked pages get their own controllers',
        (tester) async {
      final router = _router();
      await _pump(tester, router);
      await _push(tester, router, '/jobs/details/1');
      await _push(tester, router, '/jobs/details/2');
      expect(find.text('details:2:2'), findsOneWidget);
      _take();

      await _pop(tester, router);
      expect(find.text('details:1:1'), findsOneWidget);
      expect(_take().where((e) => e.startsWith('details')),
          ['details:pageExit:2', 'details:dispose:2']);
    });

    testWidgets('replace: old controller disposed before the new one exists',
        (tester) async {
      final router = _router();
      await _pump(tester, router);
      await _push(tester, router, '/jobs/details/1');
      _take();

      unawaited(router.replace('/jobs/details/2'));
      await tester.pumpAndSettle();
      expect(_take(), [
        'details:pageExit:1',
        'details:dispose:1',
        'details:create:2',
        'details:pageEnter:2',
      ]);
      expect(find.text('details:2:2'), findsOneWidget);
    });

    testWidgets('shell tabs: switching hides and re-enters, never disposes',
        (tester) async {
      late StatefulNavigationShell shell;
      final router = GoRouter(initialLocation: '/jobs', routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, s) {
            shell = s;
            return s;
          },
          branches: [
            PlayxShellBranch<JobsController>(
              path: '/jobs',
              controller: (_, __) => JobsController(),
              disposeController: (_) => log.add('jobs:dispose'),
              builder: (_, __) => const JobsView(),
            ),
            PlayxShellBranch<CounterController>(
              path: '/counter',
              controller: (_, __) => CounterController(),
              builder: (_, __) => const CounterView(),
            ),
          ],
        ),
      ]);
      await _pump(tester, router);
      _take();

      shell.goBranch(1);
      await tester.pumpAndSettle();
      expect(find.text('counter:0'), findsOneWidget);
      shell.goBranch(0);
      await tester.pumpAndSettle();
      expect(_take(), ['jobs:pageHidden', 'jobs:pageReEnter']);
    });

    testWidgets(
        'non-blocking + deep link: pending parent waits for its '
        'controller', (tester) async {
      final router = GoRouter(initialLocation: '/c/details/5', routes: [
        PlayxRoute<CounterController>(
          path: '/c',
          controller: (_, __) {
            log.add('counter:create');
            return CounterController();
          },
          waitForBinding: false,
          loadingWidget: const Text('parent-loading'),
          builder: (_, __) => const CounterView(),
          routes: [_detailsRoute(waitForBinding: false)],
        ),
      ]);
      await _pump(tester, router);
      expect(tester.takeException(), isNull);
      expect(log, isNot(contains('counter:create')));
      expect(find.text('details:5:5'), findsOneWidget);

      await _pop(tester, router);
      expect(tester.takeException(), isNull);
      expect(log, contains('counter:create'));
      expect(find.text('counter:0'), findsOneWidget);
    });

    testWidgets('throwing factory: errorBuilder, retry creates a fresh one',
        (tester) async {
      var attempts = 0;
      final router = GoRouter(routes: [
        PlayxRoute<CounterController>(
          path: '/',
          controller: (_, __) {
            attempts++;
            if (attempts == 1) throw StateError('boom');
            return CounterController();
          },
          errorBuilder: (_, __, error, ___, retry) =>
              TextButton(onPressed: retry, child: Text('error:$error')),
          builder: (_, __) => const CounterView(),
        ),
      ]);
      await _pump(tester, router);
      expect(find.textContaining('boom'), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(find.text('counter:0'), findsOneWidget);
      expect(attempts, 2);
    });

    testWidgets('supertype lookup: one form view for create and edit',
        (tester) async {
      final router = _router();
      await _pump(tester, router);
      await _push(tester, router, '/jobs/edit/3');
      expect(find.text('form:edit:3'), findsOneWidget);
      await _push(tester, router, '/jobs/create');
      expect(find.text('form:create'), findsOneWidget);
      await _pop(tester, router);
      expect(find.text('form:edit:3'), findsOneWidget);
    });

    testWidgets('register/unregister hooks get the route type and scope',
        (tester) async {
      final calls = <String>[];
      final router = _router();
      await _pump(
        tester,
        router,
        config: PlayxPageConfig(
          registerController: <T extends Object>(T c, PlayxScope s) {
            calls.add('register:$T');
            registry[_key(T, s.id)] = c;
          },
          unregisterController: <T extends Object>(T c, PlayxScope s) {
            calls.add('unregister:$T');
            registry.remove(_key(T, s.id));
          },
        ),
      );
      await _push(tester, router, '/jobs/edit/3');
      await _pop(tester, router);
      expect(calls, [
        'register:JobsController',
        'register:EditJobController',
        'unregister:EditJobController',
      ]);
      expect(registry.keys.single, startsWith('JobsController#'));
    });

    testWidgets('dialogs reach the controller through PlayxScopeProvider',
        (tester) async {
      await _pump(tester, _router());
      final pageContext = tester.element(find.byType(BuildJobsList));
      final scope = PlayxScope.of(pageContext);

      unawaited(showModalBottomSheet<void>(
        context: pageContext,
        builder: (_) =>
            PlayxScopeProvider(scope: scope, child: const BuildJobsList()),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(BuildJobsList), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('PlayxView with plain bindings', () {
    testWidgets('binding stores the controller in the scope', (tester) async {
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: _ScopeBinding(),
          builder: (_, __) => const CounterView(),
        ),
      ]);
      await _pump(tester, router);
      expect(find.text('counter:7'), findsOneWidget);
    });

    testWidgets('binding registers by tag, findController resolves it',
        (tester) async {
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: _TaggedBinding(),
          builder: (_, __) => const CounterView(),
        ),
      ]);
      await _pump(
        tester,
        router,
        config: PlayxPageConfig(
          findController: <T extends Object>(PlayxScope s) =>
              registry[_key(T, s.id)] as T?,
        ),
      );
      expect(find.text('counter:9'), findsOneWidget);
    });

    testWidgets('missing controller throws a clear StateError', (tester) async {
      final router = GoRouter(routes: [
        PlayxRoute(
          path: '/',
          binding: _EmptyBinding(),
          builder: (_, __) => const CounterView(),
        ),
      ]);
      await _pump(tester, router);
      final error = tester.takeException();
      expect(error, isA<StateError>());
      expect('$error', contains('No CounterController found for this page'));
    });

    testWidgets('outside any page: maybeController is null', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }));
      expect(ctx.maybeController<CounterController>(), isNull);
      expect(() => ctx.controller<CounterController>(), throwsStateError);
    });
  });
}

class _ScopeBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    PlayxScope.of(context).put(CounterController()..value = 7);
  }
}

class _TaggedBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    registry[_key(CounterController, PlayxScope.of(context).id)] =
        CounterController()..value = 9;
  }
}

class _EmptyBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {}
}
