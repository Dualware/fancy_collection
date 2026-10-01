part of 'fancy_collection_core.dart';

/// A [Map] that notifies listeners when entries are added, replaced or
/// removed.
///
/// Every mutating operation emits one event per affected entry: `[]=`,
/// [addAll], [putIfAbsent], [update], [updateAll], [remove], [removeWhere]
/// and [clear].
///
/// [Map] and [List] values are converted into a nested [FancyMap] or
/// [FancyList] (when that fits the value type [V]), so changes deep inside
/// the structure bubble up to listeners registered on the root:
///
/// ```dart
/// final user = FancyMap<String, dynamic>();
/// user.addListener('address', FancyCollectionValueChangeListener(
///   onCollectionEvent: (e) => print('${e.attributePath} -> ${e.value}'),
/// ));
/// user['address'] = {'city': 'Berlin'};
/// (user['address'] as Map)['city'] = 'Paris'; // address.city -> Paris
/// ```
class FancyMap<K, V> extends MapBase<K, V> with FancyCollectionMixin {
  final Map<K, V> _values = {};

  /// Creates an empty map.
  FancyMap();

  /// Creates an untyped map containing the entries of [other], converting
  /// nested [Map]s and [List]s into [FancyMap]s and [FancyList]s.
  static FancyMap initWithMap(Map other) =>
      FancyMap<dynamic, dynamic>()..addAll(other);

  @override
  FancyMap<K, V> _copy() {
    final copy = FancyMap<K, V>();
    _values.forEach((key, value) => copy[key] = value);
    return copy;
  }

  void _emitChange(
    FancyCollectionEventType type,
    Object? key, {
    Object? value,
    Object? oldValue,
  }) {
    _emit(
      FancyCollectionEvent()
        ..type = type
        ..key = key
        ..value = value
        ..oldValue = oldValue
        .._segments = [key],
    );
  }

  @override
  V? operator [](Object? key) => _values[key];

  @override
  void operator []=(K key, V value) {
    final existed = _values.containsKey(key);
    final old = _values[key];
    final stored =
        identical(old, value) && existed
            ? old as V
            : _adopt<V>(value, key) as V;
    if (!identical(old, stored)) _release(old);
    _values[key] = stored;

    _emitChange(
      existed ? FancyCollectionEventType.update : FancyCollectionEventType.add,
      key,
      value: stored,
      oldValue: existed ? old : null,
    );
  }

  @override
  Iterable<K> get keys => _values.keys;

  @override
  int get length => _values.length;

  @override
  bool containsKey(Object? key) => _values.containsKey(key);

  /// Removes [key] and emits a [FancyCollectionEventType.remove] event.
  ///
  /// Returns `null` without emitting an event when [key] is not present.
  @override
  V? remove(Object? key) {
    if (!_values.containsKey(key)) return null;

    final old = _values.remove(key);
    _release(old);
    _emitChange(FancyCollectionEventType.remove, key, oldValue: old);
    return old;
  }

  /// Removes all entries, emitting a [FancyCollectionEventType.remove] event
  /// for each.
  @override
  void clear() {
    for (final key in _values.keys.toList()) {
      remove(key);
    }
  }
}
