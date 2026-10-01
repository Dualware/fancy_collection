import 'dart:math';

import 'package:fancy_collection/fancy_collection.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records `type@path` for every event delivered to [path] on [collection].
List<String> record(FancyCollectionMixin collection, [String path = '*']) {
  final events = <String>[];
  collection.addListener(
    path,
    FancyCollectionValueChangeListener(
      onCollectionEvent:
          (e) => events.add('${e.type!.name}@${e.attributePath}'),
    ),
  );
  return events;
}

FancyList<int> numbers() => FancyList<int>()..addAll([1, 2, 3, 4]);

void main() {
  group('FancyList emits one event per change', () {
    final cases =
        <String, (void Function(FancyList<int>), List<String>, List<int>?)>{
          'add': ((l) => l.add(5), ['add@[4]'], [1, 2, 3, 4, 5]),
          'addAll': (
            (l) => l.addAll([5, 6]),
            ['add@[4]', 'add@[5]'],
            [1, 2, 3, 4, 5, 6],
          ),
          'addAll(self)': (
            (l) => l.addAll(l),
            ['add@[4]', 'add@[5]', 'add@[6]', 'add@[7]'],
            [1, 2, 3, 4, 1, 2, 3, 4],
          ),
          'insert': ((l) => l.insert(0, 9), ['add@[0]'], [9, 1, 2, 3, 4]),
          'insertAll': (
            (l) => l.insertAll(1, [8, 9]),
            ['add@[1]', 'add@[2]'],
            [1, 8, 9, 2, 3, 4],
          ),
          '[]=': ((l) => l[1] = 9, ['update@[1]'], [1, 9, 3, 4]),
          'first=': ((l) => l.first = 9, ['update@[0]'], [9, 2, 3, 4]),
          'setAll': (
            (l) => l.setAll(1, [8, 9]),
            ['update@[1]', 'update@[2]'],
            [1, 8, 9, 4],
          ),
          'setRange': (
            (l) => l.setRange(0, 2, [7, 8, 9], 1),
            ['update@[0]', 'update@[1]'],
            [8, 9, 3, 4],
          ),
          'fillRange': (
            (l) => l.fillRange(0, 2, 0),
            ['update@[0]', 'update@[1]'],
            [0, 0, 3, 4],
          ),
          'remove': ((l) => l.remove(2), ['remove@[1]'], [1, 3, 4]),
          'remove(missing)': ((l) => l.remove(42), [], [1, 2, 3, 4]),
          // ignore: collection_methods_unrelated_type
          'remove(other type)': ((l) => l.remove('x'), [], [1, 2, 3, 4]),
          'removeAt': ((l) => l.removeAt(0), ['remove@[0]'], [2, 3, 4]),
          'removeLast': ((l) => l.removeLast(), ['remove@[3]'], [1, 2, 3]),
          'removeWhere': (
            (l) => l.removeWhere((e) => e.isOdd),
            ['remove@[*]'],
            [2, 4],
          ),
          'removeWhere(none)': (
            (l) => l.removeWhere((e) => e > 9),
            [],
            [1, 2, 3, 4],
          ),
          'retainWhere': (
            (l) => l.retainWhere((e) => e.isEven),
            ['remove@[*]'],
            [2, 4],
          ),
          'removeRange': ((l) => l.removeRange(1, 3), ['remove@[*]'], [1, 4]),
          'removeRange(empty)': ((l) => l.removeRange(1, 1), [], [1, 2, 3, 4]),
          'clear': ((l) => l.clear(), ['remove@[*]'], []),
          'length shrink': ((l) => l.length = 2, ['remove@[*]'], [1, 2]),
          'replaceRange': (
            (l) => l.replaceRange(0, 2, [9]),
            ['remove@[*]', 'add@[0]'],
            [9, 3, 4],
          ),
          'sort': (
            (l) => l.sort((a, b) => b - a),
            ['update@[*]'],
            [4, 3, 2, 1],
          ),
          'shuffle': ((l) => l.shuffle(Random(1)), ['update@[*]'], null),
        };

    cases.forEach((name, testCase) {
      final (operation, expectedEvents, expectedValues) = testCase;
      test(name, () {
        final list = numbers();
        final events = record(list);
        operation(list);
        expect(events, expectedEvents);
        if (expectedValues != null) expect(list, expectedValues);
      });
    });

    test('clear on an empty list emits nothing', () {
      final list = FancyList<int>();
      final events = record(list);
      list.clear();
      list.sort();
      expect(events, isEmpty);
    });

    test('growing a nullable list emits adds', () {
      final list = FancyList<int?>()..add(1);
      final events = record(list);
      list.length = 3;
      expect(events, ['add@[1]', 'add@[2]']);
      expect(list, [1, null, null]);
    });

    test('remove listeners see list.remove', () {
      final list = numbers();
      final removed = <int?>[];
      list.addListener(
        '*',
        FancyCollectionValueChangeListener(
          listensFor: FancyCollectionEventType.remove,
          onCollectionEvent: (e) => removed.add(e.value as int?),
        ),
      );
      list.remove(3);
      expect(removed, [3]);
    });

    test('update events carry the old value', () {
      final list = numbers();
      final events = <FancyCollectionEvent>[];
      list.addListener(
        '*',
        FancyCollectionValueChangeListener(onCollectionEvent: events.add),
      );
      list[0] = 10;
      expect(events.single.oldValue, 1);
      expect(events.single.value, 10);
    });

    test('invalid arguments throw without emitting', () {
      final list = numbers();
      final events = record(list);
      expect(() => list.insert(9, 1), throwsRangeError);
      expect(() => list.removeRange(3, 1), throwsRangeError);
      expect(() => list.setRange(0, 3, [1]), throwsStateError);
      expect(() => FancyList<int>().removeLast(), throwsRangeError);
      expect(events, isEmpty);
    });
  });

  group('FancyMap emits one event per change', () {
    FancyMap<String, int> letters() =>
        FancyMap<String, int>()..addAll({'a': 1, 'b': 2});

    final cases = <
      String,
      (void Function(FancyMap<String, int>), List<String>, Map<String, int>)
    >{
      '[]= new': ((m) => m['c'] = 3, ['add@c'], {'a': 1, 'b': 2, 'c': 3}),
      '[]= existing': ((m) => m['a'] = 9, ['update@a'], {'a': 9, 'b': 2}),
      'addAll': (
        (m) => m.addAll({'c': 3}),
        ['add@c'],
        {'a': 1, 'b': 2, 'c': 3},
      ),
      'putIfAbsent': ((m) => m.putIfAbsent('a', () => 9), [], {'a': 1, 'b': 2}),
      'update': (
        (m) => m.update('a', (v) => v + 1),
        ['update@a'],
        {'a': 2, 'b': 2},
      ),
      'updateAll': (
        (m) => m.updateAll((k, v) => v * 10),
        ['update@a', 'update@b'],
        {'a': 10, 'b': 20},
      ),
      'remove': ((m) => m.remove('a'), ['remove@a'], {'b': 2}),
      'remove(missing)': ((m) => m.remove('z'), [], {'a': 1, 'b': 2}),
      'removeWhere': (
        (m) => m.removeWhere((k, v) => v == 1),
        ['remove@a'],
        {'b': 2},
      ),
      'clear': ((m) => m.clear(), ['remove@a', 'remove@b'], {}),
    };

    cases.forEach((name, testCase) {
      final (operation, expectedEvents, expectedValues) = testCase;
      test(name, () {
        final map = letters();
        final events = record(map);
        operation(map);
        expect(events, expectedEvents);
        expect(map, expectedValues);
      });
    });

    test('remove events carry the removed value as oldValue', () {
      final map = letters();
      final events = <FancyCollectionEvent>[];
      map.addListener(
        '*',
        FancyCollectionValueChangeListener(onCollectionEvent: events.add),
      );
      map.remove('b');
      expect(events.single.oldValue, 2);
      expect(events.single.key, 'b');
    });
  });

  group('nested collections', () {
    test('removed child no longer reports to its old parent', () {
      final root = FancyMap<String, dynamic>();
      root['a'] = {'x': 1};
      final child = root['a'] as FancyMap;
      final events = record(root);

      root.remove('a');
      child['x'] = 2;

      expect(events, ['remove@a']);
    });

    test('replaced child no longer reports to its old parent', () {
      final root = FancyMap<String, dynamic>();
      root['a'] = {'x': 1};
      final old = root['a'] as FancyMap;
      root['a'] = {'y': 1};
      final events = record(root);

      old['x'] = 5;
      (root['a'] as FancyMap)['y'] = 2;

      expect(events, ['update@a.y']);
    });

    test('cleared list children are detached', () {
      final root = FancyMap<String, dynamic>();
      root['items'] = [
        {'n': 1},
      ];
      final child = (root['items'] as FancyList)[0] as FancyMap;
      (root['items'] as FancyList).clear();
      final events = record(root);

      child['n'] = 2;

      expect(events, isEmpty);
    });

    test('child paths follow index shifts', () {
      final list =
          FancyList<dynamic>()..addAll([
            {'n': 0},
            {'n': 1},
          ]);
      final second = list[1] as FancyMap;
      final events = record(list);

      list.insert(0, 'first');
      second['n'] = 2;
      list.removeAt(0);
      list.removeAt(0);
      second['n'] = 3;
      list.add({'n': 4});
      list.sort((a, b) => (b['n'] as int) - (a['n'] as int));
      second['n'] = 5;

      expect(events, [
        'add@[0]',
        'update@[2].n',
        'remove@[0]',
        'remove@[0]',
        'update@[0].n',
        'add@[1]',
        'update@[*]',
        'update@[1].n',
      ]);
    });

    test('changes inside list elements propagate', () {
      final root = FancyMap<String, dynamic>();
      root['items'] = [
        {'n': 1},
      ];
      final events = record(root);

      ((root['items'] as List)[0] as Map)['n'] = 2;
      (root['items'] as FancyList).add({'n': 3});
      ((root['items'] as List)[1] as Map)['n'] = 4;

      expect(events, [
        'update@items[0].n',
        'add@items[1]',
        'update@items[1].n',
      ]);
      expect((root['items'] as List)[1], isA<FancyMap>());
    });

    test('nested lists inside lists propagate', () {
      final list = FancyList<dynamic>()..add(<dynamic>[]);
      final events = record(list);

      (list[0] as FancyList).add(1);

      expect(events, ['add@[0][0]']);
    });

    test('listeners on a nested collection see paths relative to it', () {
      final root = FancyMap<String, dynamic>();
      root['user'] = {'address': <String, dynamic>{}};
      final user = root['user'] as FancyMap;
      final userEvents = record(user, 'address.city');
      final rootEvents = record(root, 'user.address.city');

      (user['address'] as Map)['city'] = 'Paris';

      expect(userEvents, ['add@address.city']);
      expect(rootEvents, ['add@user.address.city']);
    });

    test('a root FancyMap is adopted, not copied', () {
      final child = FancyMap<String, int>()..['k'] = 1;
      final childEvents = record(child);
      final root = FancyMap<String, dynamic>();
      final rootEvents = record(root);

      root['c'] = child;
      child['k'] = 2;

      expect(identical(root['c'], child), isTrue);
      expect(childEvents, ['update@k']);
      expect(rootEvents, ['add@c', 'update@c.k']);
    });

    test('a collection that already has a parent is copied with its type', () {
      final a = FancyMap<String, dynamic>();
      a['x'] = FancyMap<String, int>()..['k'] = 1;
      final b = FancyMap<String, dynamic>();

      b['y'] = a['x'];

      expect(identical(a['x'], b['y']), isFalse);
      expect(b['y'], isA<FancyMap<String, int>>());
      expect(b['y'], {'k': 1});
    });

    test('a collection cannot contain itself or an ancestor', () {
      final root = FancyMap<String, dynamic>();
      root['a'] = <String, dynamic>{};
      final child = root['a'] as FancyMap;

      expect(() => root['self'] = root, throwsArgumentError);
      expect(() => child['loop'] = root, throwsArgumentError);
    });
  });

  group('typed nested values', () {
    test('Map<String, dynamic> values become FancyMap<String, dynamic>', () {
      final map = FancyMap<String, Map<String, dynamic>>();
      final events = record(map);

      map['a'] = {'x': 1};
      map['a']!['x'] = 2;

      expect(map['a'], isA<FancyMap<String, dynamic>>());
      expect(events, ['add@a', 'update@a.x']);
    });

    test('values that cannot be made observable are stored as-is', () {
      final map = FancyMap<String, List<int>>();
      map['a'] = [1];
      expect(map['a'], [1]);
      expect(map['a'], isNot(isA<FancyList>()));

      final maps = FancyMap<String, Map<String, int>>();
      maps['a'] = {'x': 1};
      expect(maps['a'], {'x': 1});
    });

    test('FancyList.from with typed elements', () {
      final ofMaps = FancyList<Map<String, dynamic>>.from([
        {'a': 1},
      ]);
      final ofLists = FancyList<List<int>>.from([
        [1],
      ]);

      expect(ofMaps.single, isA<FancyMap<String, dynamic>>());
      expect(ofLists.single, [1]);
    });

    test('assigning a FancyMap of the wrong type still throws', () {
      final map = FancyMap<String, Map<String, int>>();
      expect(
        () => map['a'] = FancyMap<dynamic, dynamic>() as dynamic,
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('re-entrancy', () {
    test('listeners can be added and removed during dispatch', () {
      final list = FancyList<int>();
      var nested = 0;
      list.addListener(
        '*',
        FancyCollectionValueChangeListener(
          onCollectionEvent: (_) {
            list.addListener(
              '[0]',
              FancyCollectionValueChangeListener(
                onCollectionEvent: (_) => nested++,
              ),
            );
            list.getValueNotifier('[${list.length}]');
            list.removeAllListeners('*');
          },
        ),
      );

      list.add(1);
      list[0] = 2;

      expect(nested, 1);
    });

    test('a listener can mutate the collection', () {
      final list = FancyList<int>();
      final events = record(list);
      list.addListener(
        '[0]',
        FancyCollectionValueChangeListener(
          listensFor: FancyCollectionEventType.add,
          onCollectionEvent: (_) => list.add(99),
        ),
      );

      list.add(1);

      expect(list, [1, 99]);
      expect(events, ['add@[0]', 'add@[1]']);
    });
  });

  group('path syntax', () {
    test('keys are compared exactly', () {
      final map = FancyMap<String, dynamic>();
      map['first'] = <String, dynamic>{};
      final events = record(map, 'first.name');

      map['first-name'] = 1;
      map['first name'] = 1;
      map['firstname'] = 1;
      (map['first'] as Map)['name'] = 1;

      expect(events, ['add@first.name']);
    });

    test('non-ASCII keys', () {
      final map = FancyMap<String, int>();
      final events = record(map, 'café');

      map['caf'] = 1;
      map['café'] = 1;

      expect(events, ['add@café']);
    });

    test('keys with special characters are escaped and round-trip', () {
      final map = FancyMap<String, dynamic>();
      final all = <String>[];
      map.addListener(
        '*',
        FancyCollectionValueChangeListener(
          onCollectionEvent: (e) => all.add(e.attributePath),
        ),
      );

      map['a.b'] = 1;
      map['x[0]'] = 1;
      map['*'] = 1;
      map[r'back\slash'] = 1;

      expect(all, [r'a\.b', r'x\[0\]', r'\*', r'back\\slash']);
      for (final path in List.of(all)) {
        final hits = record(map, path);
        map.updateAll((key, value) => value);
        expect(hits, hasLength(1), reason: path);
      }
    });

    test('an escaped star is a literal key, not a wildcard', () {
      final map = FancyMap<String, int>();
      final events = record(map, r'\*');

      map['a'] = 1;
      map['*'] = 1;

      expect(events, [r'add@\*']);
    });

    test('non-string keys match their toString()', () {
      final map = FancyMap<int, String>();
      final events = record(map, '1');

      map[1] = 'a';
      map[12] = 'b';

      expect(events, ['add@1']);
    });

    test('list indexes and map keys are distinct', () {
      final map = FancyMap<String, dynamic>();
      map['items'] = [0, 0];
      final byIndex = record(map, 'items[1]');
      final byKey = record(map, 'items.1');

      (map['items'] as FancyList)[1] = 5;

      expect(byIndex, ['update@items[1]']);
      expect(byKey, isEmpty);
    });

    test('malformed paths are rejected', () {
      final list = FancyList<int>();
      final listener = FancyCollectionValueChangeListener(
        onCollectionEvent: (_) {},
      );
      for (final path in [
        '[',
        '[x]',
        '[-1]',
        'a]',
        'a..b',
        '.a',
        'a.',
        r'a\',
        '[0]x',
      ]) {
        expect(
          () => list.addListener(path, listener),
          throwsArgumentError,
          reason: path,
        );
        expect(() => list.getValueNotifier(path), throwsArgumentError);
      }
    });

    test('valid paths are accepted', () {
      final list = FancyList<int>();
      final listener = FancyCollectionValueChangeListener(
        onCollectionEvent: (_) {},
      );
      for (final path in [
        '',
        '*',
        '[0]',
        '[*]',
        '[0][1].a',
        'a.b[2].c',
        r'a\.b',
        'current.*',
      ]) {
        list.addListener(path, listener);
      }
    });
  });
}
