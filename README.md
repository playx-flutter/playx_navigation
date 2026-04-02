
# Playx Navigation
[![pub package](https://img.shields.io/pub/v/playx_navigation.svg?color=1284C5)](https://pub.dev/packages/playx_navigation)

**Playx Navigation** is a robust and flexible Flutter package that enhances the navigation capabilities of your Flutter applications. It builds on the `go_router` package to provide powerful features like route-specific lifecycle management with bindings, extensive route configuration options, and custom page transitions. With `Playx Navigation`, you can create a highly modular and maintainable navigation system for your apps.

## Features

-   **Route Bindings**: Attach custom logic to specific routes, handling lifecycle events such as entering or exiting a route.
-   **App Initialization Lifecycle**: Register app-level dependencies (repositories, datasources, services) via `onInitApp` in your bindings, called automatically during boot.
-   **Initialization Awaiting**: Use `PlayxNavigation.ensureInitialized` to gate startup logic until all bindings are initialized.
-   **Binding Registry**: Access any registered binding by type via `PlayxNavigation.findBinding<T>()`.
-   **Advanced Route Configuration**: Fine-tune the behavior of your routes with extensive configuration options, including custom transitions, modal behavior, and state management.
-   **Route Management**: Easily navigate to routes, replace routes, and handle navigation stacks without the need for buildcontext.
-   **Custom Page Transitions**: Use predefined transitions or create your own to enhance the user experience.

## Installation

Add `Playx Navigation` to your `pubspec.yaml`:

```yaml
dependencies:
  playx_navigation: ^0.0.1 
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

### Shell Route Behavior

```
Branch A (Home) ↔ Branch B (Products)

1. Enter Home         → home.onEnter
2. Switch to Products → home.onHidden, products.onEnter
3. Switch back        → products.onHidden, home.onReEnter(wasPoppedAndReentered: false)
```

```
Parent → Child (push/pop)

1. Enter List         → list.onEnter
2. Push Details       → list.onHidden, details.onEnter
3. Pop Details        → details.onExit, list.onReEnter(wasPoppedAndReentered: true)
4. Navigate away      → list.onExit
```

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

##  Configuring Routes

###  Advanced Routing and Custom Transitions with `PlayxRoute`
The `PlayxRoute` class extends the functionality of the `GoRoute` class, providing advanced features that allow developers to have granular control over routing in Flutter applications. With `PlayxRoute`, you can implement custom page transitions, bind route-specific lifecycle events, and configure page settings with ease.

#### **Overview of PlayxRoute**

`PlayxRoute` is designed to enhance navigation by offering:

-   **Lifecycle Management**: Attach custom logic that runs when a route is entered or exited, enabling better control over the state and behavior of your app.
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
