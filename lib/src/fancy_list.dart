part of 'fancy_collection_core.dart';

/// A [List] that notifies listeners when elements are added, replaced or
/// removed.
///
/// ```dart
/// final todos = FancyList<String>();
/// todos.addListener('*', FancyCollectionValueChangeListener(
///   onCollectionEvent: (e) => print('${e.type} at ${e.attributePath}'),
/// ));
/// todos.add('Write docs'); // FancyCollectionEventType.add at [0]
/// ```
///
/// Each change emits exactly one event per affected element:
///
/// * [add], [addAll], [insert], [insertAll] and growing [length]: an `add`
///   event per new element, at its final index.
/// * `[]=`, [setAll], [setRange], [fillRange]: an `update` per element.
/// * [remove], [removeAt], [removeLast]: a `remove` event at the index the
///   element had.
/// * [removeWhere], [retainWhere], [removeRange], [clear] and shrinking
///   [length]: a single bulk `remove` event at `[*]` with `index == -1`,
///   only if something was removed.
/// * [sort] and [shuffle]: a single bulk `update` event at `[*]`.
/// * [replaceRange]: a bulk `remove` followed by an `add` per new element.
///
/// [Map] and [List] elements are converted into a nested [FancyMap] or
/// [FancyList] (when that fits the element type [T]) and their changes
/// bubble up to this list's listeners.
class FancyList<T> extends ListBase<T> with FancyCollectionMixin {
  final List<T> _values = [];

  /// Creates an empty list.
  FancyList();

  /// Creates an untyped list from [other], converting nested [Map]s and
  /// [List]s into [FancyMap]s and [FancyList]s.
  static FancyList initWithList(List other) => FancyList<dynamic>.from(other);

  /// Creates a list containing the elements of [other], converting nested
  /// [Map]s and [List]s into [FancyMap]s and [FancyList]s where that fits
  /// [T].
  factory FancyList.from(Iterable other) {
    final list = FancyList<T>();
    for (final element in other) {
      list.add(element as T);
    }
    return list;
  }

  @override
  FancyList<T> _copy() => FancyList<T>()..addAll(_values);

  T _adoptAt(Object? element, int index) =>
      _adopt<T>(element, _Position(index)) as T;

  void _reindexFrom(int start) {
    for (var i = start; i < _values.length; i++) {
      final element = _values[i];
      if (element is FancyCollectionMixin && identical(element._parent, this)) {
        element._segment = _Position(i);
      }
    }
  }

  void _emitChange(
    FancyCollectionEventType type,
    int? index, {
    Object? value,
    Object? oldValue,
  }) {
    _emit(
      FancyCollectionEvent()
        ..type = type
        ..index = index ?? -1
        ..value = value
        ..oldValue = oldValue
        .._segments = [index == null ? _Position.bulk : _Position(index)],
    );
  }

  void _removedAll(List<T> removed, {required int reindexFrom}) {
    if (removed.isEmpty) return;
    removed.forEach(_release);
    _reindexFrom(reindexFrom);
    _emitChange(FancyCollectionEventType.remove, null);
  }

  @override
  int get length => _values.length;

  @override
  set length(int newLength) {
    final oldLength = _values.length;
    if (newLength < oldLength) {
      final removed = _values.sublist(newLength);
      _values.length = newLength;
      _removedAll(removed, reindexFrom: newLength);
    } else if (newLength > oldLength) {
      _values.length = newLength;
      for (var i = oldLength; i < newLength; i++) {
        _emitChange(FancyCollectionEventType.add, i);
      }
    }
  }

  @override
  T operator [](int index) => _values[index];

  @override
  void operator []=(int index, T value) {
    final old = _values[index];
    final stored = identical(old, value) ? old : _adoptAt(value, index);
    if (!identical(old, stored)) _release(old);
    _values[index] = stored;
    _emitChange(
      FancyCollectionEventType.update,
      index,
      value: stored,
      oldValue: old,
    );
  }

  @override
  void add(T element) {
    final index = _values.length;
    final stored = _adoptAt(element, index);
    _values.add(stored);
    _emitChange(FancyCollectionEventType.add, index, value: stored);
  }

  @override
  void addAll(Iterable<T> iterable) {
    for (final element in iterable.toList()) {
      add(element);
    }
  }

  @override
  void insert(int index, T element) {
    RangeError.checkValueInInterval(index, 0, _values.length, 'index');
    final stored = _adoptAt(element, index);
    _values.insert(index, stored);
    _reindexFrom(index + 1);
    _emitChange(FancyCollectionEventType.add, index, value: stored);
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    RangeError.checkValueInInterval(index, 0, _values.length, 'index');
    final elements = iterable.toList();
    for (var i = 0; i < elements.length; i++) {
      insert(index + i, elements[i]);
    }
  }

  @override
  bool remove(Object? element) {
    for (var i = 0; i < _values.length; i++) {
      if (_values[i] == element) {
        removeAt(i);
        return true;
      }
    }
    return false;
  }

  @override
  T removeAt(int index) {
    final removed = _values.removeAt(index);
    _release(removed);
    _reindexFrom(index);
    _emitChange(
      FancyCollectionEventType.remove,
      index,
      value: removed,
      oldValue: removed,
    );
    return removed;
  }

  @override
  T removeLast() => removeAt(_values.length - 1);

  @override
  void removeWhere(bool Function(T element) test) => _removeMatching(test);

  @override
  void retainWhere(bool Function(T element) test) =>
      _removeMatching((element) => !test(element));

  void _removeMatching(bool Function(T element) test) {
    final kept = <T>[];
    final removed = <T>[];
    for (final element in _values) {
      (test(element) ? removed : kept).add(element);
    }
    if (removed.isEmpty) return;

    _values
      ..clear()
      ..addAll(kept);
    _removedAll(removed, reindexFrom: 0);
  }

  @override
  void removeRange(int start, int end) {
    RangeError.checkValidRange(start, end, _values.length);
    final removed = _values.sublist(start, end);
    _values.removeRange(start, end);
    _removedAll(removed, reindexFrom: start);
  }

  @override
  void clear() {
    final removed = List<T>.of(_values);
    _values.clear();
    _removedAll(removed, reindexFrom: 0);
  }

  @override
  void replaceRange(int start, int end, Iterable<T> newContents) {
    RangeError.checkValidRange(start, end, _values.length);
    final elements = newContents.toList();
    removeRange(start, end);
    insertAll(start, elements);
  }

  @override
  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, _values.length);
    RangeError.checkNotNegative(skipCount, 'skipCount');
    final elements = iterable.skip(skipCount).take(end - start).toList();
    if (elements.length < end - start) {
      throw StateError('Too few elements');
    }
    for (var i = 0; i < elements.length; i++) {
      this[start + i] = elements[i];
    }
  }

  @override
  void sort([int Function(T a, T b)? compare]) {
    if (_values.length < 2) return;
    _values.sort(compare);
    _reindexFrom(0);
    _emitChange(FancyCollectionEventType.update, null);
  }

  @override
  void shuffle([Random? random]) {
    if (_values.length < 2) return;
    _values.shuffle(random);
    _reindexFrom(0);
    _emitChange(FancyCollectionEventType.update, null);
  }
}
