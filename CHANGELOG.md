# Changelog

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
