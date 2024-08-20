import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'playx_page_configuration.dart';

/// Defines various page transition types for routing.
///
/// The [PlayxPageTransition] enum specifies the types of page transitions that can
/// be used when navigating between pages. Each type defines a different animation
/// or transition effect to enhance the user experience.
enum PlayxPageTransition {
  /// No transition effect; the page appears instantly.
  none,

  /// Uses the Material page transition effect.
  material,

  /// Uses the Cupertino page transition effect, typical for iOS apps.
  cupertino,

  /// Chooses the native page transition based on the platform:
  /// - Material for Android
  /// - Cupertino for iOS/macOS
  native,

  /// Uses a custom transition defined by [PlayxPageConfiguration].
  custom,

  /// Applies a fade transition effect.
  fade;

  /// Builds a [Page] widget with the specified transition effect.
  ///
  /// Depending on the [PlayxPageTransition] type, this method creates a [Page]
  /// with a specific transition effect, using the provided [PlayxPageConfiguration],
  /// child widget, and [GoRouterState].
  ///
  /// **Parameters:**
  /// - `config`: The configuration settings for the page transition, such as duration and transitions builder.
  /// - `child`: The widget that represents the content of the page.
  /// - `state`: The current state of the [GoRouter].
  ///
  /// **Returns:**
  /// A [Page] widget configured with the specified transition effect.
  Page<T> buildPage<T>({
    required PlayxPageConfiguration config,
    required Widget child,
    required GoRouterState state,
  }) {
    switch (this) {
      case PlayxPageTransition.material:
        return MaterialPage(
          child: child,
          key: config.key ?? state.pageKey,
          name: config.name ?? state.name,
          arguments: config.arguments,
          fullscreenDialog: config.fullscreenDialog,
          maintainState: config.maintainState,
          restorationId: config.restorationId,
          canPop: config.canPop,
          onPopInvoked: config.onPopInvoked,
        );
      case PlayxPageTransition.cupertino:
        return CupertinoPage(
          child: child,
          key: config.key ?? state.pageKey,
          name: config.name ?? state.name,
          arguments: config.arguments,
          fullscreenDialog: config.fullscreenDialog,
          maintainState: config.maintainState,
          restorationId: config.restorationId,
          canPop: config.canPop,
          onPopInvoked: config.onPopInvoked,
        );
      case PlayxPageTransition.native:
        return !kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.macOS)
            ? CupertinoPage(
                child: child,
                key: config.key ?? state.pageKey,
                name: config.name ?? state.name,
                arguments: config.arguments,
                fullscreenDialog: config.fullscreenDialog,
                maintainState: config.maintainState,
                restorationId: config.restorationId,
                canPop: config.canPop,
                onPopInvoked: config.onPopInvoked,
              )
            : MaterialPage(
                child: child,
                key: config.key ?? state.pageKey,
                name: config.name ?? state.name,
                arguments: config.arguments,
                fullscreenDialog: config.fullscreenDialog,
                maintainState: config.maintainState,
                restorationId: config.restorationId,
                canPop: config.canPop,
                onPopInvoked: config.onPopInvoked,
              );
      case PlayxPageTransition.custom:
        return CustomTransitionPage(
          child: child,
          key: config.key ?? state.pageKey,
          name: config.name ?? state.name,
          arguments: config.arguments,
          fullscreenDialog: config.fullscreenDialog,
          maintainState: config.maintainState,
          restorationId: config.restorationId,
          transitionsBuilder: config.transitionsBuilder,
          transitionDuration: config.transitionDuration,
          reverseTransitionDuration: config.reverseTransitionDuration,
          opaque: config.opaque,
          barrierDismissible: config.barrierDismissible,
          barrierColor: config.barrierColor,
          barrierLabel: config.barrierLabel,
        );
      case PlayxPageTransition.fade:
        return CustomTransitionPage(
          child: child,
          key: config.key ?? state.pageKey,
          name: config.name ?? state.name,
          arguments: config.arguments,
          fullscreenDialog: config.fullscreenDialog,
          maintainState: config.maintainState,
          restorationId: config.restorationId,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: config.transitionDuration,
          reverseTransitionDuration: config.reverseTransitionDuration,
          opaque: config.opaque,
          barrierDismissible: config.barrierDismissible,
          barrierColor: config.barrierColor,
          barrierLabel: config.barrierLabel,
        );
      case PlayxPageTransition.none:
        return NoTransitionPage(
          child: child,
          key: config.key ?? state.pageKey,
          name: config.name ?? state.name,
          arguments: config.arguments,
          restorationId: config.restorationId,
        );
    }
  }
}
