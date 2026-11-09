# Playx Navigation

[![pub package](https://img.shields.io/pub/v/playx_navigation.svg?color=1284C5)](https://pub.dev/packages/playx_navigation)
[![Build](https://github.com/playx-flutter/playx_navigation/actions/workflows/build.yml/badge.svg)](https://github.com/playx-flutter/playx_navigation/actions/workflows/build.yml)
[![codecov](https://codecov.io/gh/playx-flutter/playx_navigation/branch/main/graph/badge.svg)](https://codecov.io/gh/playx-flutter/playx_navigation)
[![Docs](https://img.shields.io/badge/docs-playx--flutter.github.io-1284C5)](https://playx-flutter.github.io/playx_navigation/)

**Playx Navigation** is a navigation package for Flutter built on [`go_router`](https://pub.dev/packages/go_router).
It keeps everything go_router gives you and adds what larger apps keep rebuilding by hand: a reliable
**page lifecycle**, **page-scoped state**, **web-friendly navigation**, and **navigation without a `BuildContext`**.

📖 **[Read the documentation](https://playx-flutter.github.io/playx_navigation/)** ·
[API reference](https://playx-flutter.github.io/playx_navigation/api/) ·
[Changelog](CHANGELOG.md) ·
[`llms.txt`](https://playx-flutter.github.io/playx_navigation/llms.txt)

## Features

- **Page lifecycle**: `onEnter`, `onHidden`, `onReEnter`, `onExit` per page, correct with shell routes, stacked pages, deep links, replace and the browser's back button.
- **App initialization**: `onInitApp` registers app-level dependencies at boot; `PlayxNavigation.ensureInitialized` gates startup logic.
- **Page scopes and route controllers**: a controller per page that stacked pages can't overwrite, created and disposed for you (`PlayxRoute<T>(controller: ...)`), with a `GetView`-like `PlayxView<T>` and optional GetX interop.
- **Guards, redirects and error handling**: `PlayxGuard`, binding `redirect`, `errorBuilder` / `enterTimeout` with retry.
- **Loading without blank frames**: shell builder, init-aware builder, non-blocking init, cross-fade, global `PlayxPageConfig`.
- **Web**: `back()` to the parent when nothing can be popped, `popUntil`, `PlayxBackButton`, safe `extraAs` / `intPathParam`, breadcrumbs and browser tab titles.
- **Navigate from anywhere**: `PlayxNavigation.to`, `toNamed`, `offAll`, `offAndTo`, `popUntil`, ... no `BuildContext` needed.
- **Custom page transitions** and a **binding registry** (`PlayxNavigation.findBinding<T>()`).

## Installation

```yaml
dependencies:
  playx_navigation: ^3.0.0
```

```bash
flutter pub get
```

`playx_navigation` re-exports `go_router`, so one import is enough:

```dart
import 'package:playx_navigation/playx_navigation.dart';
```

Requires Flutter `>=3.27.0` and Dart `>=3.6.0`. Upgrading from 2.x? See the
[migration guide](https://playx-flutter.github.io/playx_navigation/migration/).

## Quick start

**1. Routes.** Use `PlayxRoute` (a `GoRoute`) and give it a controller, a binding, or both:

```dart
final router = GoRouter(
  initialLocation: '/jobs',
  routes: [
    PlayxRoute<JobsController>(
      path: '/jobs',
      breadcrumb: (context, state) => 'Jobs',
      controller: (context, state) => JobsController(),
      disposeController: (controller) => controller.onClose(),
      builder: (context, state) => const JobsView(),
      routes: [
        PlayxRoute<JobDetailsController>(
          path: ':id',
          breadcrumb: (context, state) => 'Job #${state.pathParameters['id']}',
          controller: (context, state) =>
              JobDetailsController(id: state.intPathParam('id')!, job: state.extraAs<Job>()),
          builder: (context, state) => const JobDetailsView(),
        ),
      ],
    ),
  ],
);
```

**2. Views.** `PlayxView<T>` gives the page's controller, like `GetView<T>`. Child widgets in other files work too:

```dart
class JobsView extends PlayxView<JobsController> {
  const JobsView({super.key});

  @override
  Widget buildView(BuildContext context, JobsController controller) => Scaffold(
        body: const BuildJobsList(),
        floatingActionButton: FloatingActionButton(onPressed: controller.refresh),
      );
}
```

**3. App.** Wrap your app in `PlayxNavigationBuilder`. It boots navigation and runs every binding's `onInitApp`:

```dart
PlayxNavigationBuilder(
  router: router,
  config: const PlayxPageConfig(loadingWidget: Center(child: CircularProgressIndicator())),
  builder: (context) => MaterialApp.router(routerConfig: router),
)
```

**4. Navigate from anywhere.**

```dart
PlayxNavigation.toNamed('jobDetails', pathParameters: {'id': '5'}, extra: job);
PlayxNavigation.back();                          // pops, or goes to the parent page on web
PlayxNavigation.popUntil('/jobs', orGo: true);
```

Prefer explicit lifecycle methods? Use a binding:

```dart
class JobsBinding extends PlayxBinding {
  @override
  Future<void> onInitApp() async => JobsRepository.register();         // once, at boot

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    PlayxScope.of(context).put(JobsController(), dispose: (c) => c.onClose());
  }

  @override
  Future<void> onReEnter(BuildContext context, GoRouterState? state, bool popped) async {
    // The page is visible again (popped: a child page was removed, otherwise a tab switch).
  }
}
```

## Choosing an approach

| | Binding | Binding + scope | Route controller |
|---|---|---|---|
| You write | a `PlayxBinding` | a `PlayxBinding` | a `controller:` factory |
| Safe when the same route is stacked | only if keyed by hand | yes | yes |
| Best for | app-level setup, redirects | async setup, several resources | one controller per page |

The three can be mixed in one app.
[Compare them in detail](https://playx-flutter.github.io/playx_navigation/choosing-an-approach/).

## Documentation

| Topic | |
|---|---|
| [Installation and setup](https://playx-flutter.github.io/playx_navigation/getting-started/) | Step-by-step setup |
| [Routes and transitions](https://playx-flutter.github.io/playx_navigation/routes/) | `PlayxRoute`, shell branches, transitions |
| [Bindings and lifecycle](https://playx-flutter.github.io/playx_navigation/bindings/) | Callbacks, guarantees, a table of scenarios |
| [Page configuration](https://playx-flutter.github.io/playx_navigation/page-configuration/) | Loading widget, shell builder, init builder |
| [Guards and redirects](https://playx-flutter.github.io/playx_navigation/guards-and-redirects/) | Protect routes, validate parameters |
| [Error handling](https://playx-flutter.github.io/playx_navigation/error-handling/) | `errorBuilder`, `enterTimeout`, retry |
| [Scopes](https://playx-flutter.github.io/playx_navigation/scopes/) and [route controllers and views](https://playx-flutter.github.io/playx_navigation/controllers-and-views/) | Page-scoped state, `PlayxView` |
| [GetX and other registries](https://playx-flutter.github.io/playx_navigation/state-management-interop/) | Interop hooks |
| [PlayxNavigation API](https://playx-flutter.github.io/playx_navigation/navigation-api/) | Every navigation method |
| [Web](https://playx-flutter.github.io/playx_navigation/web/) and [breadcrumbs and page titles](https://playx-flutter.github.io/playx_navigation/breadcrumbs/) | Refresh, deep links, back, tab titles |
| [Testing your app](https://playx-flutter.github.io/playx_navigation/testing/) | Testing bindings, controllers, guards |
| [Troubleshooting](https://playx-flutter.github.io/playx_navigation/troubleshooting/) | Common problems |

For AI assistants: [`llms.txt`](https://playx-flutter.github.io/playx_navigation/llms.txt) and
[`llms-full.txt`](https://playx-flutter.github.io/playx_navigation/llms-full.txt).

## Example

The [`example`](example) app shows shell routes with tabs, parent and child pages, route controllers
with `PlayxView`, bindings, breadcrumbs and the page lifecycle.

## Contributing

Issues and pull requests are welcome. Before opening a PR run:

```bash
dart format .
flutter analyze lib test
flutter test --coverage
```

The documentation lives in [`docs`](docs) (MkDocs). To preview it locally:

```bash
pip install -r tool/requirements-docs.txt
python tool/build_llms_full.py
mkdocs serve
```

## Support

For questions, issues or feature requests, visit the
[GitHub repository](https://github.com/playx-flutter/playx_navigation).

## See also

- [Playx](https://pub.dev/packages/playx): ecosystem for redundant features, less code, more productivity, better organizing.
- [Playx_core](https://pub.dev/packages/playx_core): core of the Playx ecosystem, helping with app theming and localization.
- [Playx_localization](https://pub.dev/packages/playx_localization): localization and internationalization for Flutter apps from the Playx ecosystem.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
