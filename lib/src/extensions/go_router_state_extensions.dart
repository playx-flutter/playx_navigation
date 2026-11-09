import 'package:go_router/go_router.dart';

/// Helpers for reading navigation data from a [GoRouterState].
extension PlayxGoRouterStateExtensions on GoRouterState {
  /// Returns [GoRouterState.extra] if it is a [T], otherwise `null`.
  ///
  /// Unlike `state.extra as T?`, this never throws. `extra` is often missing
  /// or of another type: on web after a refresh, when the URL is typed or
  /// shared, on a deep link, or after browser back/forward without an
  /// `extraCodec`. Load the data by id in that case.
  ///
  /// ```dart
  /// final job = state.extraAs<Job>(); // null on refresh / deep link
  /// ```
  T? extraAs<T>() {
    final value = extra;
    return value is T ? value : null;
  }

  /// Returns the path parameter [name] parsed as an [int], or `null` if it is
  /// missing or not a valid integer.
  int? intPathParam(String name) => int.tryParse(pathParameters[name] ?? '');

  /// Returns the query parameter [name] parsed as an [int], or `null` if it is
  /// missing or not a valid integer.
  int? intQueryParam(String name) =>
      int.tryParse(uri.queryParameters[name] ?? '');
}
