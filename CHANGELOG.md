# Changelog

## 3.0.0

The binding lifecycle is now tracked per page instance, which fixes a set of navigation bugs and
changes a few observable behaviors. This release also adds page scopes, route controllers, web
helpers, breadcrumbs and browser tab titles. See the
[migration guide](https://playx-flutter.github.io/playx_navigation/migration/) for details.
(The unpublished 2.2.0 is included in this release.)

### Breaking changes and behavior changes
- **Lifecycle per page instance.** `PlayxNavigationBuilder` no longer compares top routes; every `PlayxPage` owns its lifecycle. Observable differences:
  - `onHidden` / `onReEnter` now also fire for the initial route.
  - `replace` (`offAndTo`) and changed path parameters (`/item/1` to `/item/2`) end the old page's lifecycle (`onExit` completes) before the new page's `onEnter` starts; `onEnter` receives the new parameters. A binding no longer needs `onReEnter` to refresh its parameters.
  - Stacked pages of one route, or one binding shared by several routes, each have their own lifecycle.
  - `onExit` runs after a still-running `onEnter` finishes; lifecycle callbacks of a page never overlap, and on one navigation every `onHidden` starts before any `onEnter` / `onReEnter`.
  - On pop, the revealed page's `onReEnter` runs immediately and the popped page's `onExit` after its exit animation.
  - `onEnter` waits for every `onInitApp`.
  - A failed `onEnter` is reported (or shown by `errorBuilder`) instead of being an unhandled async error, and no `onHidden` / `onReEnter` / `onExit` runs for that page.
  - `wasPoppedAndReentered` is based on the router's page stack instead of a path-prefix check.
- **`PlayxNavigation.offAndTo` / `offAndToNamed` are generic and return `Future<T?>`** (they were `Future<void>`). The future completes with the replacing page's result when it is popped, like `to`; it no longer looks like it hangs because of an `async` wrapper. Fire-and-forget calls are unaffected.
- **`PlayxNavigation.isInitialized` is `false` after a failed boot** (it was `true` because a failed completer counts as completed).
- `PlayxRoute` and `PlayxShellBranch` are generic (`PlayxRoute<T extends Object>`); existing code infers `Object` and is unaffected.
- `PlayxBinding.onExit` is optional (no-op by default). Existing overrides are unaffected.
- `PlayxNavigation.currentState`, `currentRoute` and `currentRouteName` return `null` instead of throwing while go_router shows its error page. Previously this also crashed every page listening to route changes.

### New features
- **Page scopes (`PlayxScope`)**: every page with a binding or controller gets a scope for its visit, from `onEnter` to `onExit`. `PlayxScope.of(context)` provides a unique `id` (for GetX tags and similar registries), a `put` / `get` container with automatic `dispose`, `onDispose` callbacks that run after `onExit`, and the page's own `pageState`. Controllers of stacked pages (`details/1` over `details/2`, edit over create) no longer overwrite or delete each other. Also `PlayxBinding.activeScopes` to clean up shared resources when the last page leaves, and `PlayxScopeProvider` to reach a page's controllers from dialogs and bottom sheets.
- **Route controllers**: `PlayxRoute<T>(controller: ..., disposeController: ...)` (and `PlayxShellBranch<T>`) creates one controller per page visit, stores it in the page's scope, and disposes it when the page exits. No binding is needed. Controllers can mix in **`PlayxPageLifecycle`** (`onPageEnter`, `onPageHidden`, `onPageReEnter`, `onPageExit`).
- **`PlayxView<T>`**: a `GetView<T>`-like base widget with `buildView(context, controller)`, plus `context.controller<T>()` / `maybeController<T>()`. Works for page views and child widgets in any file, with route controllers and with controllers a binding stores in the scope.
- **GetX interop hooks on `PlayxPageConfig`**: `registerController`, `unregisterController` and `findController`.
- **Route guards**: `PlayxGuard` and `PlayxRoute.guards`. Guards run in order before the binding's `redirect` and the route's `redirect`; the first non-null location wins. They also protect child routes. `PlayxGuard.from(callback)` creates one inline.
- **`PlayxBinding.redirect`**: validate parameters before the page is built. Runs only when the binding's own route is the destination.
- **`onEnter` error handling**: `errorBuilder` (receives the error and a `retry` callback) and `enterTimeout` on `PlayxRoute`, `PlayxShellBranch` and `PlayxPageConfig` (route values override global ones).
- **Breadcrumbs**: routes and bindings declare labels (`PlayxRoute.breadcrumb`, `PlayxShellBranch.breadcrumb`, `PlayxBinding.breadcrumb`), and pages can set runtime labels from loaded data (`PlayxBreadcrumbLabel`, `PlayxNavigation.setBreadcrumbLabel`). Trail modes: `hierarchy` (with an optional `rootLocation`), `shellBranch` and `history`. Use the customizable `PlayxBreadcrumbs` widget (collapses long trails, "..." opens a menu), `PlayxBreadcrumbsBuilder` for your own widget, or `PlayxNavigation.breadcrumbs(context)` for the data.
- **Browser tab titles**: `PlayxNavigationBuilder(pageTitle: PlayxPageTitle(appName: ...))` keeps the tab title in sync with the current page using the breadcrumb labels (`Plumbing repair · Jobs · My App`). `PlayxNavigation.pageTitle` exposes the applied title for `MaterialApp.onGenerateTitle`, since `MaterialApp` resets the title when it rebuilds.
- **`PlayxNavigation.back()`**: pops, or goes to the current page's parent when there is nothing to pop (web refresh, typed URLs, deep links). The parent is the route's new `parentLocation`, or the nearest shorter path that matches a route. Also `canGoBack`, `parentLocation` and a `PlayxBackButton` widget for app bars.
- **`PlayxNavigation.popUntil` / `popUntilNamed`**: pop back to the page showing a location, with an optional `orGo` fallback for an empty stack.
- **`PlayxNavigation.popOrGo` / `popOrGoNamed`**: pop, or go to a fallback location.
- **`GoRouterState` helpers**: `extraAs<T>()`, `intPathParam(name)`, `intQueryParam(name)`, which return `null` instead of throwing.
- `PlayxNavigation.playxRouter`, `hasRouter`, and `PlayxRouter` helpers (`parentOf`, `stateFor`, `isShellBranchRoot`, `pageStack`, `popToPage`, `stateOrNull`).
- `PlayxPageState` is now exported.

### Fixes
- `router.replace` reused the old page's state, so the new binding never ran `onEnter` and the old one never ran `onExit`.
- Changed path parameters did not re-run `onEnter` with the new parameters.
- `onExit` was skipped when a page was left while its `onEnter` was still running.
- `PlayxNavigation.ensureInitialized` awaited before `boot` never completed (`boot` replaced its completer). `boot` now reuses a pending completer, and booting again while a boot is running no longer completes twice.
- A failed boot is no longer also reported as an unhandled async error.
- `PlayxNavigationBuilder` did not boot a different router given to the same builder.
- Guard chains stay synchronous unless a guard returns a `Future`, so routes with bindings or guards don't resolve a frame later.

### Documentation, tests and tooling
- New documentation site (MkDocs, published to GitHub Pages) with guides for every feature, a migration guide and troubleshooting, plus the dartdoc API reference. `llms.txt` and `llms-full.txt` are published for AI assistants.
- The README was reorganized around the documentation site.
- Test suite grown from none to ~190 tests (99% line coverage); the coverage gate in CI is now 90%.
- CI uses current actions and also analyzes the example app.
- Updated `go_router` to ^17.5.0 and refreshed dependencies and the example app.

## 2.1.0

### New Features
- **Init-aware builder (`initBuilder`)**: Added an optional `initBuilder` parameter to `PlayxRoute` and `PlayxShellBranch` that receives `(context, state, isInitialized)`. When provided, the user has full control over what to render based on the binding's initialization state. The existing `builder` with `(context, state)` signature remains unchanged — the library continues to manage loading/content switching automatically.
  ```dart
  // Standard builder — library manages loading (unchanged from 1.0.0):
  PlayxRoute(
    path: '/products',
    builder: (context, state) => ProductsPage(),
    binding: ProductsBinding(),
  )

  // Init-aware builder — user handles everything:
  PlayxRoute(
    path: '/profile',
    initBuilder: (context, state, isInitialized) {
      if (!isInitialized) return ProfileSkeleton();
      return ProfilePage();
    },
    binding: ProfileBinding(),
  )
  ```
- **Shell Builder**: Added `shellBuilder` parameter to `PlayxRoute`, `PlayxShellBranch`, and `PlayxPageConfig`. The shell (AppBar, Drawer, Scaffold) renders immediately during navigation transitions, preventing blank frames. Only the body content waits for the binding's `onEnter` to complete. Only applies when using `builder`, not `initBuilder`.
  ```dart
  PlayxRoute(
    path: '/channels',
    builder: (context, state) => ChannelsListView(),
    shellBuilder: (context, state, isInitialized, child) => Scaffold(
      appBar: AppBar(title: Text('Channels')),
      drawer: MyDrawer(),
      body: child,
    ),
    binding: ChannelsBinding(),
  )
  ```
- **Non-blocking initialization**: Added `waitForBinding` parameter to `PlayxRoute`, `PlayxShellBranch`, and `PlayxPageConfig`. When set to `false`, the page content renders immediately while `onEnter` runs in the background. Only applies when using `builder`.
- **Initialization transition animation**: Added `initTransitionDuration` parameter to `PlayxRoute`, `PlayxShellBranch`, and `PlayxPageConfig`. When set, an `AnimatedSwitcher` crossfade smoothly transitions from the loading widget to the page content. Only applies when using `builder`.
- **Global page configuration via `PlayxPageConfig`**: Added `config` parameter to `PlayxNavigationBuilder` to set global defaults for `loadingWidget`, `waitForBinding`, `shellBuilder`, and `initTransitionDuration`. Individual routes can override any of these settings.
  ```dart
  PlayxNavigationBuilder(
    router: router,
    config: PlayxPageConfig(
      loadingWidget: Center(child: CircularProgressIndicator()),
      waitForBinding: true,
      initTransitionDuration: Duration(milliseconds: 300),
    ),
    builder: (context) => MyApp(),
  )
  ```
- **New typedefs**: `PlayxRouteWidgetBuilder` and `PlayxShellWidgetBuilder` for type-safe builder signatures.

### Configuration Resolution
Route-level parameter → Global `PlayxPageConfig` → Built-in default.
These settings only apply when using the standard `builder`, not `initBuilder`:
- `loadingWidget`: Route > Global > `SizedBox.shrink()`
- `waitForBinding`: Route > Global > `true`
- `shellBuilder`: Route > Global > `null`
- `initTransitionDuration`: Route > Global > `null` (no animation)

## 1.0.0

### New Features
- **New `onInitApp` Lifecycle Method for `PlayxBinding`**: Added a new `onInitApp()` lifecycle method that is called once during app initialization. This allows developers to register app-level instances (repositories, datasources, services) directly from their bindings before any route lifecycle events are triggered.
- `PlayxNavigation.boot()` now returns a `Future<void>` and automatically discovers all `PlayxBinding` instances in the route tree, calling `onInitApp()` on each during initialization.
- **New `ensureInitialized`**: A static `Future<void>` getter that completes when `boot()` and all `onInitApp()` calls finish. Useful for gating startup logic (e.g., splash screens).
- **New `isInitialized`**: A static `bool` getter that returns `true` after `boot()` has completed.
- **New `bindings`**: A static getter that returns an unmodifiable list of all discovered `PlayxBinding` instances from the route tree.
- **New `findBinding<T>()`**: Type-safe lookup to retrieve a specific binding by its concrete type. Throws `StateError` if not found.
- **New `findBindingOrNull<T>()`**: Same as `findBinding<T>()` but returns `null` instead of throwing if no match is found.
- **Custom Loading Widget**: Added `loadingWidget` option to `PlayxRoute` and `PlayxShellBranch`. This widget is displayed while `onEnter` is being initialized, defaulting to `SizedBox.shrink()`.
- **Initialization Blocking**: The route's child widget is only built after `onEnter` completes. This ensures dependencies registered in `onEnter` (e.g., GetX controllers) are available during the first build.

### Lifecycle Refactoring (Breaking Changes)
- **Removed redirect hack**: Binding lifecycle methods (`onEnter`, `onReEnter`) are no longer triggered through GoRoute's `redirect` callback. The `redirect` parameter on `PlayxRoute` is now passed through directly for user-defined redirection logic only.
- **`onEnter` is now fired from `PlayxPage.initState`**: Guarantees it fires exactly once when the page widget mounts. This is more reliable than the previous redirect-based approach.
- **`onExit` is now fired from `PlayxPage.dispose`**: Fires only when the page is truly removed from the widget tree. For shell routes, this means `onExit` does NOT fire on branch switches (the widget stays alive), only when the route is actually removed.
- **`onHidden` / `onReEnter` handled by route-change listener**: These fire when the top route changes — covering push (child covers parent), pop (child removed, parent revealed), and branch switching.
- **`wasPoppedAndReentered` detection improved**: Now uses path-based comparison to distinguish between a child being popped (`true`) and a branch switch (`false`).
- **Removed `shouldExecuteOnExit`**: No longer needed since `PlayxPage.dispose` directly handles `onExit`.
- `PlayxNavigationBuilder` updated to handle the async boot process seamlessly.

## 0.3.0
- Update GoRouter to v17.0.0


## 0.2.0
- Update GoRouter to v16.0.0
- Update minimum Dart SDK version to 3.6.0 and Flutter SDK version to 3.27.0
- Refactored `PlayxRoute` and `PlayxNavigationBuilder` to better handle route state and binding events.
- `GoRouterState` now passed correctly to `onReEnter`.

## 0.1.2
- Update GoRouter to v14.8.1
- Add `setupWeb`  method for `PlayxNavigation` which allows for using path-based URLs and enables URL-based imperative APIs

## 0.1.0 - 0.1.1

### New Features
- **`PlayxShellBranch`**:
    - Introduced the `PlayxShellBranch` class, an extension of `StatefulShellBranch` for creating branches with a single or multiple routes using `[PlayxRoute]`.

- **`PlayxNavigation`**:
    - Added new `rootNavigatorKey` and `navigationContext` getters for enhanced navigation control.
    - Introduced a new `maybePop` method in the `PlayxNavigation` class for conditional navigation stack popping.
    - Added a new `goRouter` getter that returns the `GoRouter` instance used for navigation.
    - Introduced a new `currentState` getter that retrieves the current `GoRouterState` object representing the state of the navigation stack.
    - Updated `currentRoute` to now return `GoRoute` instead of `RouteMatch` as it is based on the current state.
    - Updated `currentRouteName` to now return the route name based on the current state.

### Dependency Updates
- Upgraded the `go_router` package to version `14.6.3`.

### Enhancements to `PlayxBinding`
- **Refactored Behavior:**
    - **`onEnter` and `onExit`:**
        - Now triggered only when a route is entered or exited for the **first time** correctly.

    - **`onReEnter`:**
        - A new method that fires when a route is re-entered after being previously visited but not removed from the stack.
        - Example scenarios:
            - Switching between branches in a `StatefulShellBranch` while the route remains in memory (`wasPoppedAndReentered` is `false`).
            - Navigating back to a route after temporarily leaving it using `PlayxNavigation.toNamed`, where `onHidden` is called before `onReEnter` (`wasPoppedAndReentered` is `true`).

    - **`onHidden`:**
        - A new method called when a route is **hidden but not removed** from the stack.
        - Key use cases:
            - Pausing tasks or releasing temporary resources when a route is no longer visible but remains in memory.
            - Switching to another branch in a `StatefulShellBranch` or navigating away while leaving the route active in the background.
        - Sequence of calls:
            - If the route is removed, `onExit` is called after `onHidden`.
            - If revisited, `onReEnter` is called after `onHidden`.


## 0.0.1
- Initial release
