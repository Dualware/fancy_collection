import 'dart:collection';

import 'package:fancy_collection/fancy_collection_event.dart';
import 'package:fancy_collection/fancy_collection_mixin.dart';
import 'package:fancy_collection/fancy_list.dart';

/// A [Map] that notifies listeners when entries are added, replaced or
/// removed.
///
/// [Map] and [List] values assigned to a [FancyMap] are converted into a
/// nested [FancyMap] or [FancyList], so changes deep inside the structure
/// bubble up to listeners registered on the root:
///
/// ```dart
/// final user = FancyMap<String, dynamic>();
/// user.addListener('address', FancyCollectionValueChangeListener(
///   onCollectionEvent: (e) => print('${e.attributePath} -> ${e.value}'),
/// ));
/// user['address'] = {'city': 'Berlin'};
/// (user['address'] as Map)['city'] = 'Paris'; // address.city -> Paris
/// ```
///
/// Because nested values are stored as `FancyMap<dynamic, dynamic>` and
/// `FancyList<dynamic>`, declare the value type as `dynamic` (or `Object?`)
/// when storing maps or lists.
class FancyMap<K, V> extends MapBase<K, V> with FancyCollectionMixin {
  final Map<K, V> _values = {};

  /// Creates an untyped map containing the entries of [other], converting
  /// nested [Map]s and [List]s into [FancyMap]s and [FancyList]s.
  static FancyMap initWithMap(Map other) {
    FancyMap fancyMap = FancyMap();
    other.forEach((key, value) => fancyMap[key] = value);
    return fancyMap;
  }

  String _pathFor(Object? key) =>
      "${(attributePath != null) ? "$attributePath." : ""}$key";

  @override
  V? operator [](Object? key) => _values[key];

  @override
  void operator []=(K key, V value) {
    final event = FancyCollectionEvent();

    if (_values.containsKey(key)) {
      event.type = FancyCollectionEventType.update;
      event.oldValue = _values[key];
    } else {
      event.type = FancyCollectionEventType.add;
    }

    event.value = value;
    event.key = key;

    if (value is Map) {
      FancyMap nestedMap = FancyMap.initWithMap(value);
      nestedMap.parent = this;
      nestedMap.attributePath = _pathFor(key);
      _values[key] = nestedMap as V;
    } else if (value is List) {
      FancyList nestedList = FancyList.initWithList(value);
      nestedList.parent = this;
      nestedList.attributePath = _pathFor(key);
      _values[key] = nestedList as V;
    } else {
      _values[key] = value;
    }

    event.attributePath = _pathFor(key);
    processEvent(event);
  }

  /// Removes all entries. No events are emitted.
  @override
  void clear() {
    _values.clear();
  }

  @override
  Iterable<K> get keys => _values.keys;

  /// Removes [key] and emits a [FancyCollectionEventType.remove] event.
  ///
  /// Returns `null` without emitting an event when [key] is not present.
  @override
  V? remove(Object? key) {
    if (!_values.containsKey(key)) return null;

    V? returnValue = _values.remove(key);

    final event =
        FancyCollectionEvent()
          ..attributePath = _pathFor(key)
          ..key = key
          ..type = FancyCollectionEventType.remove;

    processEvent(event);
    return returnValue;
  }
}
