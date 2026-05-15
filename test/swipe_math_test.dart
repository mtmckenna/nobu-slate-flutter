import 'package:flutter_test/flutter_test.dart';
import 'package:nobu_slate/services/swipe_math.dart';

void main() {
  group('swipeValue', () {
    test('increments plain integer', () {
      expect(swipeValue('1', 1), '2');
    });

    test('decrements plain integer', () {
      expect(swipeValue('2', -1), '1');
    });

    test('floors plain integer at 1', () {
      expect(swipeValue('1', -1), '1');
    });

    test('preserves digit width when padding', () {
      expect(swipeValue('05', 1), '06');
      expect(swipeValue('001', 1), '002');
      expect(swipeValue('099', 1), '100');
    });

    test('increments letter, keeping number', () {
      expect(swipeValue('1A', 1), '1B');
      expect(swipeValue('1a', 1), '1B');
    });

    test('decrements letter, keeping number', () {
      expect(swipeValue('12B', -1), '12A');
      expect(swipeValue('1a', -1), '1A');
    });

    test('clamps letter at Z on increment', () {
      expect(swipeValue('1Z', 1), '1Z');
    });

    test('clamps letter at A on decrement', () {
      expect(swipeValue('1A', -1), '1A');
    });

    test('uppercases letter input', () {
      expect(swipeValue('5c', 1), '5D');
    });

    test('no-op for non-matching text', () {
      expect(swipeValue('WildTrack', 1), 'WildTrack');
    });
  });
}
