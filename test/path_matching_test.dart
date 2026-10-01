import 'package:fancy_collection/fancy_collection.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _record(FancyCollectionMixin collection, String path) {
  final paths = <String>[];
  collection.addListener(
    path,
    FancyCollectionValueChangeListener(
      onCollectionEvent: (e) => paths.add(e.attributePath),
    ),
  );
  return paths;
}

void main() {
  test('listener on a parent path receives nested changes', () {
    final map = FancyMap<String, dynamic>();
    final hits = _record(map, 'a');

    map['a'] = {'b': 1};
    (map['a'] as Map)['b'] = 2;

    expect(hits, ['a', 'a.b']);
  });

  test('listener on a child path receives parent replacement', () {
    final map = FancyMap<String, dynamic>();
    final hits = _record(map, 'a.b');

    map['a'] = {'b': 1};
    map['x'] = 1;

    expect(hits, ['a']);
  });

  test('sibling paths do not match', () {
    final map = FancyMap<String, dynamic>();
    map['address'] = {'city': 'Berlin', 'zip': '10115'};
    final hits = _record(map, 'address.city');

    (map['address'] as Map)['zip'] = '75001';
    (map['address'] as Map)['city'] = 'Paris';

    expect(hits, ['address.city']);
  });

  test('[*] matches any index and bulk removals match specific indexes', () {
    final map = FancyMap<String, dynamic>();
    map['items'] = <dynamic>[];
    final items = map['items'] as FancyList;
    final any = _record(map, 'items[*]');
    final second = _record(map, 'items[1]');

    items.add('a');
    items.add('b');
    items.removeWhere((e) => e == 'a');

    expect(any, contains('items[0]'));
    expect(any, contains('items[1]'));
    expect(any.last, 'items[*]');
    expect(second, ['items[1]', 'items[*]']);
  });

  test('event fields that do not apply are null instead of throwing', () {
    final list = FancyList<int>();
    final map = FancyMap<String, int>();
    final events = <FancyCollectionEvent>[];
    final listener = FancyCollectionValueChangeListener(
      onCollectionEvent: events.add,
    );
    list.addListener('*', listener);
    map.addListener('*', listener);

    list.add(1);
    map['a'] = 1;
    map.remove('a');

    expect(events[0].key, isNull);
    expect(events[0].oldValue, isNull);
    expect(events[0].index, 0);
    expect(events[1].index, isNull);
    expect(events[2].value, isNull);
    expect(events[2].type, FancyCollectionEventType.remove);
  });

  test('removing a missing key returns null without an event', () {
    final map = FancyMap<String, int>();
    final hits = _record(map, '*');

    expect(map.remove('missing'), isNull);
    expect(hits, isEmpty);
  });

  test('listener can remove itself while being notified', () {
    final list = FancyList<int>();
    late FancyCollectionValueChangeListener listener;
    var calls = 0;
    listener = FancyCollectionValueChangeListener(
      onCollectionEvent: (_) {
        calls++;
        list.removeListener('*', listener);
      },
    );
    list.addListener('*', listener);

    list.add(1);
    list.add(2);

    expect(calls, 1);
  });
}
