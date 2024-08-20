
# Playx Navigation
[![pub package](https://img.shields.io/pub/v/playx_navigation.svg?color=1284C5)](https://pub.dev/packages/playx_navigation)

**Playx Navigation** is a robust and flexible Flutter package that enhances the navigation capabilities of your Flutter applications. It builds on the `go_router` package to provide powerful features like route-specific lifecycle management with bindings, extensive route configuration options, and custom page transitions. With `Playx Navigation`, you can create a highly modular and maintainable navigation system for your apps.

## Features

-   **Route Bindings**: Attach custom logic to specific routes, handling lifecycle events such as entering or exiting a route.
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
### Step 2: Create Your `GoRouter` Instance

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

### Step 3: Initialize `PlayxNavigationBuilder`

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
PlayxNavigation.boot(router: yourGoRouterInstance);
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


## Route Bindings

### Managing Route Lifecycle with `PlayxBinding`

`PlayxBinding` is an abstract class designed to help you manage actions when navigating between routes. Whether you're setting up resources when a user enters a route or cleaning up when they leave, `PlayxBinding` provides a clean and straightforward way to handle these tasks.

**Key Points:**

-   **Customizable onEnter/onExit:** Implement `onEnter` for setup actions when the route is first entered, and `onExit` for cleanup tasks when the route is removed from the navigation stack.
-   **Subroute Management:** The `onExit` method of a main route will only be called when the main route and all its subroutes are removed, making it easy to manage resources effectively.

**Example:**

```dart
class MyRouteBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    // Setup logic when the route is entered.
  }

  @override
  Future<void> onExit(BuildContext context) async {
    // Cleanup logic when the route is exited.
  }
}
```
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
