import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_navigation/playx_navigation.dart';

// This file runs in its own isolate, so PlayxNavigation starts un-booted.
void main() {
  test('before boot: not initialized, and using it explains why', () {
    expect(PlayxNavigation.isInitialized, isFalse);
    expect(PlayxNavigation.hasRouter, isFalse);
    expect(PlayxNavigation.bindings, isEmpty);
    expect(
      () => PlayxNavigation.currentState,
      throwsA(isA<Exception>().having(
        (e) => '$e',
        'message',
        contains('PlayxNavigation is not initialized'),
      )),
    );
    expect(() => PlayxNavigation.back(), throwsException);
    expect(() => PlayxNavigation.breadcrumbsListenable, throwsException);
  });

  testWidgets('ensureInitialized waits for boot', (tester) async {
    var done = false;
    unawaited(PlayxNavigation.ensureInitialized.then((_) => done = true));
    await tester.pump();
    expect(done, isFalse);

    final router = GoRouter(routes: [
      PlayxRoute(path: '/', builder: (_, __) => const Text('home')),
    ]);
    await PlayxNavigation.boot(router: router);
    await tester.pump();
    expect(done, isTrue);
    expect(PlayxNavigation.isInitialized, isTrue);
    expect(PlayxNavigation.hasRouter, isTrue);
  });

  testWidgets('booting again while a boot is running is safe', (tester) async {
    final gate = Completer<void>();
    final router = GoRouter(routes: [
      PlayxRoute(
        path: '/',
        binding: _SlowInit(gate),
        builder: (_, __) => const Text('home'),
      ),
    ]);
    final first = PlayxNavigation.boot(router: router);
    final second = PlayxNavigation.boot(router: router);
    gate.complete();
    await Future.wait([first, second]);
    expect(PlayxNavigation.isInitialized, isTrue);
  });
}

class _SlowInit extends PlayxBinding {
  _SlowInit(this.gate);
  final Completer<void> gate;

  @override
  Future<void> onInitApp() => gate.future;

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {}
}
