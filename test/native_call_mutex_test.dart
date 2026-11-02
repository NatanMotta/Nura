import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nura_app/core/services/music_player_manager.dart';

void main() {
  test('three waiting native calls execute one at a time', () async {
    final mutex = NativeCallMutex();
    final releaseFirst = Completer<void>();
    final releaseSecond = Completer<void>();
    final events = <String>[];
    final first = mutex.runLocked(() async {
      events.add('first');
      await releaseFirst.future;
    });
    final second = mutex.runLocked(() async {
      events.add('second');
      await releaseSecond.future;
    });
    final third = mutex.runLocked(() async => events.add('third'));

    expect(events, ['first']);
    releaseFirst.complete();
    await first;
    await Future<void>.delayed(Duration.zero);
    expect(events, ['first', 'second']);
    releaseSecond.complete();
    await Future.wait([second, third]);
    expect(events, ['first', 'second', 'third']);
  });

  test('a failed call releases the lock', () async {
    final mutex = NativeCallMutex();
    await expectLater(mutex.runLocked(() async => throw StateError('failure')),
        throwsStateError);
    expect(await mutex.runLocked(() async => 42), 42);
  });
}
