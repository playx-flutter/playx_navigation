# Changelog

## 1.0.0

### New Features
- **New `onInitApp` Lifecycle Method for `PlayxBinding`**: Added a new `onInitApp()` lifecycle method that is called once during app initialization. This allows developers to register app-level instances (repositories, datasources, services) directly from their bindings before any route lifecycle events are triggered.
- `PlayxNavigation.boot()` now returns a `Future<void>` and automatically discovers all `PlayxBinding` instances in the route tree, calling `onInitApp()` on each during initialization.
- **New `ensureInitialized`**: A static `Future<void>` getter that completes when `boot()` and all `onInitApp()` calls finish. Useful for gating startup logic (e.g., splash screens).
- **New `isInitialized`**: A static `bool` getter that returns `true` after `boot()` has completed.
- **New `bindings`**: A static getter that returns an unmodifiable list of all discovered `PlayxBinding` instances from the route tree.
- **New `findBinding<T>()`**: Type-safe lookup to retrieve a specific binding by its concrete type. Throws `StateError` if not found.
- **New `findBindingOrNull<T>()`**: Same as `findBinding<T>()` but returns `null` instead of throwing if no match is found.

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
