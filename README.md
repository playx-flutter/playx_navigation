
# Playx Navigation
[![pub package](https://img.shields.io/pub/v/playx_navigation.svg?color=1284C5)](https://pub.dev/packages/playx_navigation)

**Playx Navigation** is a robust and flexible Flutter package that enhances the navigation capabilities of your Flutter applications. It builds on the `go_router` package to provide powerful features like route-specific lifecycle management with bindings, extensive route configuration options, and custom page transitions. With `Playx Navigation`, you can create a highly modular and maintainable navigation system for your apps.

## Features

-   **Route Bindings**: Attach custom logic to specific routes, handling lifecycle events such as entering or exiting a route.
-   **App Initialization Lifecycle**: Register app-level dependencies (repositories, datasources, services) via `onInitApp` in your bindings, called automatically during boot.
-   **Initialization Awaiting**: Use `PlayxNavigation.ensureInitialized` to gate startup logic until all bindings are initialized.
-   **Binding Registry**: Access any registered binding by type via `PlayxNavigation.findBinding<T>()`.
-   **Shell Builder**: Render page chrome (AppBar, Drawer, Scaffold) immediately during transitions — no more blank frames while bindings initialize.
-   **Init-Aware Builder**: Use `initBuilder` with `(context, state, isInitialized)` for full control over rendering during initialization.
-   **Non-Blocking Initialization**: Optionally render pages immediately with `waitForBinding: false`.
-   **Global Page Configuration**: Set default loading widgets, shell builders, and initialization behavior for all routes via `PlayxPageConfig`.
-   **Advanced Route Configuration**: Fine-tune the behavior of your routes with extensive configuration options, including custom transitions, modal behavior, and state management.
-   **Route Management**: Easily navigate to routes, replace routes, and handle navigation stacks without the need for buildcontext.
-   **Custom Page Transitions**: Use predefined transitions or create your own to enhance the user experience.

## Installation

Add `Playx Navigation` to your `pubspec.yaml`:

```yaml
dependencies:
  playx_navigation: ^2.1.0 
```
Then, run:

```bash
flutter pub get
```

## Setup

### Step 1: Define Your Routes (Optional)

You can optionally define your route names and paths for easier management:

```dart  
abstract class Routes {  
  static const home = 'home';  
  static const products = 'products';  
  static const details = 'productDetails';  
}  
  
abstract class Paths {  
  static const home = '/home';  
  static const products = '/products';  
  static const details = ':id';  
}  
```  

### Step 2: Create Your Route Bindings

Create bindings for each route to handle lifecycle events such as app initialization, entering or exiting a route. This ensures that your app's logic is properly managed.

```dart
class ProductsBinding extends PlayxBinding {
  @override
  Future<void> onInitApp() async {
    // Register app-level dependencies during initialization.
    // This is called once when the app boots, before any route is entered.
  }

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    // Initialize resources for the products page.
  }

  @override
  Future<void> onExit(BuildContext context) async {
    // Clean up resources when leaving the products page.
  }
}
```
### Step 3 : Create Your `GoRouter` Instance

Use the `PlayxRoute` to define your app's navigation structure:

```dart  
final router = GoRouter(  
  initialLocation: Paths.home,  
  debugLogDiagnostics: true,  
  routes: [  
    PlayxRoute(  
      path: Paths.home,  
      name: Routes.home,  
      builder: (context, state) => const HomePage(),  
      binding: HomeBinding(),  
    ),  
    PlayxRoute(  
      path: Paths.products,  
      name: Routes.products,  
      builder: (context, state) => ProductsPage(),  
      binding: ProductsBinding(),  
      routes: [  
        PlayxRoute(  
          path: Paths.details,  
          name: Routes.details,  
          builder: (context, state) =>   
            ProductDetailsPage(product: state.extra as Product),  
          binding: DetailsBinding(),  
        ),  
      ],  
    ),  
  ],  
);  
```  

### Step 4 : Initialize `PlayxNavigationBuilder`

Wrap your `MaterialApp` or `CupertionApp` in `PlayxNavigationBuilder` and pass the router instance to it to enable Playx Navigation and manage route changes:

```dart  
class MyApp extends StatelessWidget {  
  const MyApp({super.key});  
  
  @override  
  Widget build(BuildContext context) {  
    return PlayxNavigationBuilder(  
      router: router,
      config: PlayxPageConfig(
        loadingWidget: Center(child: CircularProgressIndicator()),
      ),  
      builder: (context) {  
        return MaterialApp.router(  
          title: 'Playx',  
          theme: ThemeData(  
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),  
          ),  
          routerDelegate: router.routerDelegate,  
          routeInformationParser: router.routeInformationParser,  
          routeInformationProvider: router.routeInformationProvider,  
          backButtonDispatcher: router.backButtonDispatcher,  
        );  
      });  
  }  
}  
```  

`PlayxNavigationBuilder` simplifies the setup process by providing a centralized way to configure and manage routes, bindings, and other navigation-related settings.

## PlayxNavigation Methods and Utilities

The `PlayxNavigation` class offers a variety of static methods for managing navigation within your Flutter application using the `GoRouter` package. Before utilizing any of these methods, ensure that `PlayxNavigation` has been initialized by calling `PlayxNavigation.boot()` or by including the `PlayxNavigationBuilder` widget in your widget tree.

### Initialization

Before using any navigation methods, initialize `PlayxNavigation`:

```dart
await PlayxNavigation.boot(router: yourGoRouterInstance);
```
Alternatively, use `PlayxNavigationBuilder` to automatically initialize the navigation system:

```dart
return PlayxNavigationBuilder(
  router: router,
  builder: (context) {
    return MaterialApp.router(
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
    );
  });
```

### Awaiting Initialization

Since `boot()` is asynchronous (it calls `onInitApp()` on all discovered bindings), you can await initialization anywhere in your app using `ensureInitialized`:

```dart
// In a splash screen or startup flow:
await PlayxNavigation.ensureInitialized;
// All bindings are now initialized — safe to proceed.
```

You can also check synchronously whether initialization has completed:

```dart
if (PlayxNavigation.isInitialized) {
  // Navigation is ready.
}
```

### Methods Overview

-   **Navigating to Routes**
    No need of BuildContext as you can call the navigation methods from anywhere.

    -   **`to`**: Pushes a new route onto the navigation stack.

          ```dart
        await PlayxNavigation.to('/details', extra: {'id': 1});
        ```
    -   **`offAll`**: Replaces all previous routes in the stack with a new route.

          ```dart
        await PlayxNavigation.offAll('/home', extra: {'clearHistory': true});
        ```

    -   **`offAndTo`**: Replaces the current route with a new route.
        ```dart
        await PlayxNavigation.offAndTo('/profile', extra: {'userId': 123});
        ```

-   **Named Route Navigation**

    -   **`toNamed**: Pushes a named route onto the navigation stack.
        ```dart
		await PlayxNavigation.toNamed('details', pathParameters: {'id': '1'});
		```

    -   **`offAllNamed`**: Replaces all previous routes in the stack with a named route.

          ```dart
        await PlayxNavigation.offAllNamed('home');
        ```

    -   **`offAndToNamed`**: Replaces the current route with a named route.
           ```dart
             await PlayxNavigation.offAndToNamed('profile', pathParameters: {'userId': '123'});
        ```

-   **Navigation Control**

    -   **`goToBranch`**: Navigates to the current location of the branch at the provided index of  `StatefulShellRoute`.
    -
    -   **`pop([T? result])`**: Pops the top-most route off the navigation stack.

           ```dart
         PlayxNavigation.pop();`
           ```

    -   **`canPop()`**: Returns `true` if there are routes in the navigation stack that can be popped.

        ```dart
        if (PlayxNavigation.canPop()) {
          PlayxNavigation.pop();
        }
        ```


### Accessing Current Route Information and Managing Route Changes

-   **`currentRoute`**: Gets the current `RouteMatch` object representing the current route in the navigation stack.
-   **`currentRouteName`**: Gets the name of the current route, if available.

-   **`addRouteChangeListener(VoidCallback listener)`**: Adds a listener for route changes.
-   **`removeRouteChangeListener(VoidCallback listener)`**: Removes a previously added route change listener.

### Accessing Bindings

After initialization, all discovered `PlayxBinding` instances are stored and can be accessed by type:

-   **`bindings`**: Returns an unmodifiable list of all discovered `PlayxBinding` instances.

    ```dart
    final allBindings = PlayxNavigation.bindings;
    ```

-   **`findBinding<T>()`**: Finds and returns the first binding of the specified type. Throws `StateError` if not found.

    ```dart
    final productsBinding = PlayxNavigation.findBinding<ProductsBinding>();
    ```

-   **`findBindingOrNull<T>()`**: Same as `findBinding<T>()` but returns `null` instead of throwing.

    ```dart
    final binding = PlayxNavigation.findBindingOrNull<ProductsBinding>();
    if (binding != null) {
      // Use the binding.
    }
    ```


## Route Bindings

### Managing Route Lifecycle with `PlayxBinding`

`PlayxBinding` is an abstract class in the PlayxNavigation package designed to manage actions during both the app's initialization and a route's lifecycle. This includes registering app-level dependencies at startup, initializing resources when a route is entered, handling tasks when it's revisited, pausing actions when it's hidden, and cleaning up when it's removed from the navigation stack.

**Key Features:**

- **App Initialization:** Register app-level dependencies (repositories, datasources, services) via `onInitApp`, called once at startup.
- **Widget-Lifecycle Driven:** `onEnter` fires from `PlayxPage.initState` (once on mount), `onExit` fires from `PlayxPage.dispose` (only when truly removed from the tree).
- **Initialization Blocking:** By default, the route's child widget is only built after its binding's `onEnter` completes. This guarantees any dependencies registered in `onEnter` (like GetX controllers) are available during the first build. Set `waitForBinding: false` to render immediately.
- **Shell Builder:** Provide a `shellBuilder` to render page chrome (AppBar, Drawer, Scaffold) immediately during transitions while only the body waits for initialization.
- **Custom Loading Widget:** Each route can provide a `loadingWidget` to be displayed while `onEnter` is initializing (defaults to `SizedBox.shrink()`). Set a global default via `PlayxPageConfig.loadingWidget`.
- **Route-Change Driven:** `onHidden` and `onReEnter` fire from the route-change listener when the top route changes.
- **Shell Route Aware:** In `StatefulShellRoute`, branch switching fires `onHidden`/`onReEnter` (not `onExit`/`onEnter`) because the widget stays alive in its branch.
- **Binding Access:** Retrieve any binding by type via `PlayxNavigation.findBinding<T>()` after initialization.

### Lifecycle Methods

1. **onInitApp:** Called once during `boot()`. Register app-level dependencies. Runs before any route is entered.
2. **onEnter:** Fires from `PlayxPage.initState` when the page widget first mounts. Guaranteed to fire exactly once per route entry.
3. **onHidden:** Fires when another route takes the foreground (push, branch switch) while this route stays in the stack.
4. **onReEnter:** Fires when this route returns to the foreground after being hidden. Receives `wasPoppedAndReentered`:
   - `true` — a child route was popped, revealing this parent.
   - `false` — a branch switch brought this route back.
5. **onExit:** Fires from `PlayxPage.dispose` when the page is truly removed from the widget tree.

### Lifecycle Order

```
onInitApp()  →  onEnter()  →  onHidden() ⇌ onReEnter()  →  onExit()
     ↑              ↑               ↑                          ↑
  once at boot   widget mount   route changes            widget dispose
```

### Lifecycle Guarantees

Each page instance in the navigation stack has its own lifecycle:

- **Per page, not per route.** `details/1` and `details/2` pushed on top of each other are two independent pages: the first gets `onHidden` when the second is pushed, and `onReEnter` when it is popped. The same applies when one binding instance is shared by several routes.
- **Callbacks never overlap.** For one page they run strictly in order. If you navigate away while `onEnter` is still running, `onHidden` / `onExit` wait for it to finish, so cleanup always runs after setup.
- **Leaving before entering.** On a single navigation, every `onHidden` starts before any `onEnter` / `onReEnter`.
- **`onExit` runs after the exit animation.** When a page is popped, the revealed page gets `onReEnter` immediately, and the popped page gets `onHidden` right away and `onExit` once it is removed from the tree.
- **`onEnter` waits for `onInitApp`.** No page runs `onEnter` before every binding's `onInitApp` has completed.
- **Replace / changed path parameters.** `replace` (`offAndTo`) or `go` from `/item/1` to `/item/2` ends the old visit and starts a new one on the same page: `onExit` completes before the new `onEnter` starts, and `onEnter` receives the new parameters. Query parameter changes alone don't restart the lifecycle.
- **Deep links and preloaded branches.** A page mounted behind the top page (the parent of a deep-linked child, or a `preload: true` shell branch) is *pending* (`PlayxPageState.pending`): it gets `onEnter`, not `onReEnter`, when it is first shown.
- **`wasPoppedAndReentered`** is `true` when the pages above this one were removed (pop, `go` to a parent, resetting a branch), and `false` when it comes back through a branch switch.
- **Failed `onEnter`.** If `onEnter` throws or times out, no `onHidden` / `onReEnter` / `onExit` is called for that page, since it never entered.
- **Only router navigation counts.** Dialogs, bottom sheets and routes pushed with `Navigator.push` (outside go_router) don't hide the page underneath.

> **Sharing a binding between pages that are alive at the same time** (the same route stacked twice, or one binding instance used by several routes): every page gets its own `onEnter` / `onExit`, so `onExit` of one page can run while another page of the same binding is still active. Keep controllers in the page's [`PlayxScope`](#page-scopes-and-state-management) (or tag them with `scope.id`), or check `activeScopes` before deleting shared resources.

### Navigation Scenarios

Shell with `products → details` and `favorites → details` branches, plus a top-level `/details/:id` route:

| Navigation | Events |
|---|---|
| Products → push details | `products.onHidden`, `details.onEnter` |
| Pop details | `details.onHidden`, `products.onReEnter(popped: true)`, `details.onExit` |
| Favorites details → products tab | `favDetails.onHidden`, `products.onReEnter(popped: false)` |
| Back to favorites tab | `products.onHidden`, `favDetails.onReEnter(popped: false)` |
| Push top-level `/details/1` from any tab or page, then pop | `origin.onHidden`, `details.onEnter`, then `details.onHidden`, `origin.onReEnter(popped: true)`, `details.onExit` |
| `go('/products/details/7')` from favorites details | `favDetails.onHidden`, `details.onEnter` (favorites details stays alive in its branch) |
| Deep link to `/products/details/1`, then pop | `details.onEnter`, then `products.onEnter` (not re-enter) |
| `goBranch(i, initialLocation: true)` with details open | `details.onHidden`, `products.onReEnter(popped: true)`, `details.onExit` |
| `go('/login')` (outside the shell) | `onExit` once for every page that was entered, in every branch |

**Example:**

```dart
class MyRouteBinding extends PlayxBinding {
  @override
  Future<void> onInitApp() async {
    // Register app-level dependencies during initialization.
    // Called once at boot, before any route lifecycle events.
  }

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    // Initialize resources or fetch data for the route.
  }

  @override
  Future<void> onReEnter(
    BuildContext context,
    GoRouterState? state,
    bool wasPoppedAndReentered,
  ) async {
    // Handle special cases when the route is revisited.
    // wasPoppedAndReentered: true if a child was popped, false if branch switched.
  }

  @override
  Future<void> onHidden(BuildContext context) async {
    // Pause tasks or release temporary resources.
  }

  @override
  Future<void> onExit(BuildContext context) async {
    // Cleanup resources or save state when the route is exited.
  }
}
```

### Example Use Cases

- **App-Level Dependency Registration:** Register repositories, datasources, and services in `onInitApp` so they're available before any route is entered.
- **Data Fetching:** Fetch required data when a route is entered for the first time.
- **Resource Cleanup:** Release heavy resources when the route is completely exited. For shell routes, `onExit` only fires when the route is truly removed—not on branch switches.
- **Temporary Pauses:** Pause animations or background tasks when the route is hidden (push or branch switch).
- **Revisit Handling:** Refresh UI or state when the route is re-entered. Use `wasPoppedAndReentered` to distinguish between pop and branch switch.
- **Binding Access:** Retrieve a specific binding from anywhere: `PlayxNavigation.findBinding<MyBinding>()`.

By extending `PlayxBinding`, you can efficiently manage both app-level initialization and route-specific lifecycle, ensuring that resources are used optimally.

## Global Page Configuration

### `PlayxPageConfig`

Provide a `PlayxPageConfig` to `PlayxNavigationBuilder` to set global defaults for all routes. Individual route parameters override these globals.

```dart
PlayxNavigationBuilder(
  router: router,
  config: PlayxPageConfig(
    // Default loading widget for all routes:
    loadingWidget: Center(child: CircularProgressIndicator()),
    // Don't block page build by default:
    waitForBinding: false,
    // Global shell for persistent AppBar:
    shellBuilder: (context, state, isInitialized, child) => Scaffold(
      appBar: AppBar(title: Text('My App')),
      body: child,
    ),
  ),
  builder: (context) => MyApp(),
)
```

**Resolution order:** Route-level parameter → Global `PlayxPageConfig` → Built-in default.

| Setting | Route Param | Global Config | Default |
|---|---|---|---|
| Loading widget | `PlayxRoute.loadingWidget` | `PlayxPageConfig.loadingWidget` | `SizedBox.shrink()` |
| Wait for binding | `PlayxRoute.waitForBinding` | `PlayxPageConfig.waitForBinding` | `true` |
| Shell builder | `PlayxRoute.shellBuilder` | `PlayxPageConfig.shellBuilder` | `null` |
| Init transition | `PlayxRoute.initTransitionDuration` | `PlayxPageConfig.initTransitionDuration` | `null` (no animation) |

### Shell Builder

The `shellBuilder` renders page chrome (AppBar, Drawer, Scaffold) **immediately** during navigation transitions. Only the body content waits for the binding's `onEnter` to complete, preventing blank frames. Only applies when using the standard `builder`.

```dart
PlayxRoute(
  path: '/channels',
  name: 'channels',
  builder: (context, state) => ChannelsListView(),
  shellBuilder: (context, state, isInitialized, child) => Scaffold(
    appBar: AppBar(title: Text('Channels')),
    drawer: isInitialized ? MyDrawer() : null,
    body: child, // loading widget or actual content
  ),
  binding: ChannelsBinding(),
)
```

### Non-Blocking Initialization

Set `waitForBinding: false` to render the page content immediately while `onEnter` runs in the background:

```dart
PlayxRoute(
  path: '/profile',
  name: 'profile',
  builder: (context, state) => ProfilePage(),
  binding: ProfileBinding(),
  waitForBinding: false,
)
```

### Init-Aware Builder

For full control over what renders during initialization, use `initBuilder` instead of `builder`. The `initBuilder` receives `isInitialized` so the user can handle loading states:

```dart
PlayxRoute(
  path: '/profile',
  name: 'profile',
  initBuilder: (context, state, isInitialized) {
    if (!isInitialized) return ProfileSkeleton();
    return ProfilePage();
  },
  binding: ProfileBinding(),
)
```

When using `initBuilder`, the library does **not** apply `shellBuilder`, `loadingWidget`, `waitForBinding`, or `initTransitionDuration` — the user handles everything.

### Initialization Animation

Set `initTransitionDuration` to smoothly crossfade from the loading widget to the page content using an `AnimatedSwitcher`. Only applies when using the standard `builder`:

```dart
// Global: apply to all routes
PlayxPageConfig(
  initTransitionDuration: Duration(milliseconds: 300),
)

// Per-route: override for a specific route
PlayxRoute(
  path: '/dashboard',
  builder: (context, state) => DashboardPage(),
  binding: DashboardBinding(),
  initTransitionDuration: Duration(milliseconds: 500),
)
```

Set to `Duration.zero` to explicitly disable animation for a specific route when a global duration is set.

## Page Scopes and State Management

Every page with a binding gets a `PlayxScope`: one per page visit, from `onEnter` to `onExit`. It works with any state management (GetX, Bloc, Provider, ChangeNotifier...) and solves the classic problem of stacked pages (`details/1` → `details/2`, or `edit` → `create` sharing a `JobFormController`) overwriting or deleting each other's controllers.

Get it with `PlayxScope.of(context)`, both in binding callbacks (using the `context` they receive) and in the page's widgets.

| Member | Purpose |
|---|---|
| `id` | Unique per page visit. Use it as a GetX `tag`, a family key, etc. |
| `put<T>(value, dispose: ...)` / `get<T>()` / `maybeGet<T>()` / `has<T>()` | Store objects in the page itself, no global registry. |
| `onDispose(callback)` | Runs after `onExit` completes, e.g. to unregister from a global registry. |
| `state`, `pageState`, `isActive` | This page's `GoRouterState` and lifecycle state (`binding.currentState` is shared by every page of the binding). |

**Option 1: keep controllers in the scope (no global registry).**

```dart
class JobDetailsBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    PlayxScope.of(context).put(
      JobDetailsController(id: state.intPathParam('id')!, job: state.extraAs<Job>()),
      dispose: (controller) => controller.onClose(),
    );
  }

  @override
  Future<void> onExit(BuildContext context) async {}
}

// In the page:
final controller = PlayxScope.of(context).get<JobDetailsController>();
```

**Option 2: GetX with a per-page tag.**

```dart
@override
Future<void> onEnter(BuildContext context, GoRouterState state) async {
  final scope = PlayxScope.of(context);
  Get.put(JobDetailsController(...), tag: scope.id);
  scope.onDispose(() => Get.delete<JobDetailsController>(tag: scope.id));
}

// In the page:
final controller = Get.find<JobDetailsController>(tag: PlayxScope.of(context).id);
```

**Shared (unscoped) resources:** `binding.activeScopes` lists the pages currently using the binding. A page leaves the list before its `onExit` runs, so `if (activeScopes.isEmpty) Get.delete<JobsController>();` only cleans up when no other page needs it.

### Validating Before the Page Is Built

Override `redirect` on the binding to validate parameters before the page is built. Return a location to redirect there, or `null` to continue. It runs after the route's `guards` and only when the binding's own route is the destination, not its sub-routes. This is better than navigating away inside `onEnter`, where the page would still be built with missing data.

```dart
@override
FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
    state.intPathParam('id') == null ? '/jobs' : null;
```

## Web

- **`extra` is not part of the URL.** After a refresh, a typed or shared URL, or a deep link, `state.extra` is `null`. Treat it as an optional shortcut and load data by id: `state.extraAs<Job>()` returns `null` instead of throwing, and `state.intPathParam('id')` / `state.intQueryParam('page')` parse safely. To keep `extra` across browser back/forward, give `GoRouter` an `extraCodec`.
- **Back buttons.** After a refresh or deep link there may be nothing to pop. Use `PlayxNavigation.popOrGo('/jobs')` (or `popOrGoNamed`) to pop when possible and otherwise go to a fallback.
- **Browser back/forward** work like pop and push: the page that was left gets `onExit`, the revealed page `onReEnter`, and going forward creates a new page with `onEnter`.
- **Refresh** restarts the app: `onInitApp` runs again, and the pages of the URL behave like a deep link (only the visible page enters; pages behind it are pending).
- Call `PlayxNavigation.setupWeb()` before `runApp` for path URLs and URLs that reflect `push`.

## Route Guards

Attach `PlayxGuard`s to a route to redirect before it is entered. Guards run in order, before the route's own `redirect`; the first non-null location wins. They also apply to sub-routes.

```dart
class AuthGuard extends PlayxGuard {
  const AuthGuard();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      AuthService.isLoggedIn ? null : '/login';
}

PlayxRoute(
  path: '/account',
  guards: [AuthGuard()], // or PlayxGuard.from((context, state) => ...)
  builder: (context, state) => AccountPage(),
)
```

## Handling `onEnter` Errors

If a binding's `onEnter` throws or exceeds `enterTimeout`, show an error UI with a retry option:

```dart
PlayxRoute(
  path: '/products',
  binding: ProductsBinding(),
  enterTimeout: const Duration(seconds: 10),
  errorBuilder: (context, state, error, stackTrace, retry) =>
      ErrorView(message: '$error', onRetry: retry),
  builder: (context, state) => ProductsPage(),
)
```

Set `errorBuilder` / `enterTimeout` on `PlayxPageConfig` for a global default. Without an `errorBuilder`, the error is reported through `FlutterError.reportError` and the loading state is kept.

##  Configuring Routes

###  Advanced Routing and Custom Transitions with `PlayxRoute`
The `PlayxRoute` class extends the functionality of the `GoRoute` class, providing advanced features that allow developers to have granular control over routing in Flutter applications. With `PlayxRoute`, you can implement custom page transitions, bind route-specific lifecycle events, and configure page settings with ease.

#### **Overview of PlayxRoute**

`PlayxRoute` is designed to enhance navigation by offering:

-   **Lifecycle Management**: Attach custom logic that runs when a route is entered or exited, enabling better control over the state and behavior of your app.
-   **Shell Builder**: Render page chrome immediately during transitions to prevent blank frames.
-   **Init-Aware Builder**: Use `initBuilder` with `isInitialized` for full control over rendering during initialization.
-   **Non-Blocking Initialization**: Render pages immediately with `waitForBinding: false`.
-   **Page Configuration**: Customize various settings like page title, transition duration, and modal behavior.
-   **Custom Transitions**: Apply predefined or custom animations for transitioning between pages.

1.  **Lifecycle Management with PlayxBinding**

    -   **onEnter and onExit**: Attach custom logic to handle what happens when a route is entered or exited. This is useful for managing resources, fetching data, or other setup/teardown tasks.
    -   **Redirection Handling**: Implement custom redirection logic that can dynamically change the navigation flow based on your app's state.

    **Example:**

```dart
PlayxRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => DashboardPage(),
      binding: DashboardBinding(), 
    );
 ```
As discussed in the previous Route Bindings section.
#### 2. Custom Page Configuration with PlayxPageConfiguration
The PlayxPageConfiguration class allows you to fine-tune the behavior, transitions, and appearance of routes in your application. Whether you need to customize transition durations, manage the modal behavior of a route, or configure state management, PlayxPageConfiguration has you covered.

**Key Configuration Options:**

-   **Flexible Settings**: Adjust properties such as transition duration, modal behavior, and whether the route should be maintained in memory (`maintainState`).
-   **Comprehensive Configuration**: Use `PlayxPageConfiguration` to set up the page title, key, and other important settings. This allows for detailed customization of each route.

**Example:**

```dart
final config = PlayxPageConfiguration.customTransition(
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(opacity: animation, child: child);
  },
  transitionDuration: Duration(milliseconds: 500),
  opaque: true,
  fullscreenDialog: true,
);
```
With PlayxPageConfiguration, you have the flexibility to adjust nearly every aspect of how your routes are displayed and managed, ensuring that the navigation experience matches your application's needs.

#### 3. Creating Custom Transitions
One of the standout features of PlayxRoute is its ability to define custom page transitions or leverage existing transition types like Material, Cupertino, and fade transitions.

**Predefined Transition Types:**

- Material: Standard Android-style transition.
- Cupertino: iOS-style transition.
-  Fade: A simple fade in/out transition.
- Native: Automatically selects the appropriate transition based on the
  platform.
- None: Disables any transition effects.

**Creating a Custom Transition:**
To create a custom transition, use the `PlayxPageConfiguration.customTransition` constructor. This allows you
to define how the route should animate when it is pushed or popped.

Example:

```dart
PlayxRoute(
  path: '/custom',
  name: 'customRoute',
  builder: (context, state) => CustomPage(),
  binding: CustomBinding(),
  pageConfiguration: PlayxPageConfiguration.customTransition(
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(scale: animation, child: child);
    },
    transitionDuration: Duration(milliseconds: 400),
  ),
)
```
In this example, the route uses a ScaleTransition to animate the page with a custom scale effect. The transition duration is set to 400 milliseconds, providing a smooth and customized animation.




## Support and Contribution[](https://pub.dev/packages/playx_navigation#support-and-contribution)

For questions, issues, or feature requests, visit the  [GitHub repository](https://github.com/playx-flutter/playx_navigation). Contributions are welcome!

## See Also[](https://pub.dev/packages/playx_navigation#see-also)

-   [Playx](https://pub.dev/packages/playx): Ecosystem for redundant features, less code, more productivity, better organizing.
-   [Playx_core](https://pub.dev/packages/playx_core): Core of the Playx ecosystem, helping with app theming and localization.
-   [Playx_localization](https://pub.dev/packages/playx_localization): Localization and internationalization for Flutter apps from the Playx ecosystem.

## License[](https://pub.dev/packages/playx_navigation#license)

This project is licensed under the MIT License - see the  [LICENSE](https://github.com/playx-flutter/playx_navigation/blob/main/LICENSE)  file for details.
