/// Represents the various states a page can have in the PlayxNavigation system.
///
/// - [enter]: The page has been entered for the first time.
/// - [reEnter]: The page has been re-entered after being previously visited, without being removed from the stack.
/// - [hidden]: The page is temporarily hidden but still in the navigation stack.
/// - [exit]: The page has been exited and removed from the navigation stack.
enum PlayxPageState {
  enter,
  reEnter,
  hidden,
  exit,
}
