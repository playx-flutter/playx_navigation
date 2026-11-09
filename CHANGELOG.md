# Changelog

## 2.2.0

### New Features
- **Route guards**: Added `PlayxGuard` and `PlayxRoute.guards` (also on `PlayxShellBranch`). Guards run in order before the route's `redirect`; the first one returning a location redirects there. Guards also apply to sub-routes.
  ```dart
  PlayxRoute(
    path: '/account',
    guards: [PlayxGuard.from((context, state) => isLoggedIn ? null : '/login')],
    builder: (context, state) => AccountPage(),
  )
  ```
- **`onEnter` error handling**: Added `errorBuilder` and `enterTimeout` to `PlayxRoute`, `PlayxShellBranch` and `PlayxPageConfig` (route values override global ones). If `onEnter` throws or times out, `errorBuilder` receives the error and a `retry` callback. Without an `errorBuilder`, the error is reported via `FlutterError.reportError` instead of being an unhandled async error, and the loading state is kept.

- **Page scopes (`PlayxScope`)**: every page with a binding gets a scope for its visit, from `onEnter` to `onExit`. Get it with `PlayxScope.of(context)` in binding callbacks and page widgets. It provides a unique `id` (for GetX tags and similar registries), a small `put` / `get` container with automatic `dispose`, `onDispose` callbacks that run after `onExit`, and the page's own `pageState`. This keeps controllers of stacked pages (`details/1` → `details/2`, edit → create) from overwriting or deleting each other.
- **Route controllers**: `PlayxRoute<T>(controller: ..., disposeController: ...)` (and `PlayxShellBranch<T>`) creates one controller per page visit, stores it in the page's scope, and disposes it when the page exits. No binding is needed. Controllers can mix in **`PlayxPageLifecycle`** (`onPageEnter`, `onPageHidden`, `onPageReEnter`, `onPageExit`).
- **`PlayxView<T>`**: a `GetView<T>`-like base widget with `buildView(context, controller)`, plus `context.controller<T>()` / `maybeController<T>()`. Works for page views and child widgets in any file, with route controllers and with controllers a binding stores in the scope. **`PlayxScopeProvider`** makes a page's controllers reachable from dialogs and bottom sheets.
- **Controller hooks on `PlayxPageConfig`**: `registerController`, `unregisterController` and `findController`, for optional interop with GetX or another registry.
- `PlayxScope.get` / `maybeGet` / `has` also match values of a subtype (one `PlayxView<JobFormController>` for create and edit pages).
- **`PlayxBinding.redirect`**: validate navigation before the page is built (e.g. a missing or invalid id). Runs only when the binding's own route is the destination.
- **`PlayxBinding.onExit` is now optional** (no-op by default), for bindings that register cleanup with `PlayxScope.onDispose` / `PlayxScope.put` in `onEnter`. Existing overrides are unaffected.
- **`PlayxBinding.activeScopes`**: the pages currently using a binding, for cleaning up shared resources only when the last page leaves.
- **`PlayxNavigation.back()`**: pop, or go to the current page's parent when there is nothing to pop (web refresh, typed URLs, deep links). The parent is the route's new **`parentLocation`**, or the nearest shorter path that matches a route. Also adds `PlayxNavigation.canGoBack`, `PlayxNavigation.parentLocation` and a **`PlayxBackButton`** widget for app bars.
- **`PlayxNavigation.popOrGo` / `popOrGoNamed`**: pop, or go to a fallback when there is nothing to pop (web refresh, deep links).
- **`GoRouterState` helpers**: `extraAs<T>()`, `intPathParam(name)`, `intQueryParam(name)`, which return `null` instead of throwing.

### Fixes
- **Binding lifecycle rewritten per page instance.** Each `PlayxPage` now owns its lifecycle instead of `PlayxNavigationBuilder` comparing top routes. This fixes:
  - `onHidden` / `onReEnter` not firing for the initial route.
  - `router.replace(...)` reusing the old page state, so the new binding never ran `onEnter` and the old one never ran `onExit`.
  - Changed path parameters (`/item/1` -> `/item/2`) not re-running `onEnter` with the new parameters. Replace and parameter changes now end the old visit (`onExit`) before starting the new one (`onEnter`).
  - The same route stacked twice (`details/1` over `details/2`), or one binding shared by several routes, mixing up lifecycle state (spurious `onReEnter`, missing `onHidden`).
  - `onExit` being skipped when leaving a page while its `onEnter` was still running.
  - `onEnter` possibly starting before `onInitApp` finished.
- Lifecycle callbacks of a page now run strictly in order, and on one navigation every `onHidden` starts before any `onEnter` / `onReEnter`.
- `wasPoppedAndReentered` is now based on the router's page stack instead of a path-prefix check. It is now correct when popping a top-level route back into a shell tab, and when popping `details/2` back to `details/1`.
- `PlayxNavigation.currentState`, `currentRoute` and `currentRouteName` return `null` instead of throwing while go_router shows its error page for an unknown location. Previously this also crashed every page listening to route changes. Added `PlayxRouter.stateOrNull`.
- `PlayxPageState` is now exported.

### Other
- Guard chains stay synchronous unless a guard returns a `Future`, so routes with bindings or guards don't resolve a frame later.
- Added unit/widget tests for the binding lifecycle, scopes, binding redirects, web back/forward, error handling and guards.
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
