/// Represents the various states a page can have in the PlayxNavigation system.
///
/// - [pending]: The page widget has mounted but is not the active/visible route
///   (e.g., a parent route mounted as backstack when deep-linking to a child).
///   `onEnter` has NOT been called yet.
/// - [enter]: The page has been entered for the first time and `onEnter` has completed.
/// - [reEnter]: The page has been re-entered after being hidden.
/// - [hidden]: The page is temporarily hidden but still in the navigation stack.
/// - [exit]: The page has been exited and removed from the navigation stack.
enum PlayxPageState {
  pending,
  enter,
  reEnter,
  hidden,
  exit,
}
