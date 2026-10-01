import 'dart:collection';

import 'package:fancy_collection/fancy_collection_event.dart';
import 'package:fancy_collection/fancy_collection_mixin.dart';
import 'package:fancy_collection/fancy_map.dart';

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
/// Events are emitted for [add], `[]=`, [removeAt], [removeLast],
/// [removeWhere] and [removeRange]. Other [List] operations are implemented
/// by [ListBase] in terms of these, so they emit the corresponding events
/// for each element they touch.
class FancyList<T> extends ListBase<T> with FancyCollectionMixin {
  final List<T> _values = [];

  /// Creates an empty list.
  FancyList();

  /// Creates an untyped list from [other], converting nested [Map]s and
  /// [List]s into [FancyMap]s and [FancyList]s.
  static FancyList initWithList(List other) {
    FancyList fancyList = FancyList();

    for (var element in other) {
      if (element is Map) {
        fancyList.add(FancyMap.initWithMap(element));
      } else if (element is List) {
        fancyList.add(FancyList.initWithList(element));
      } else {
        fancyList.add(element);
      }
    }

    return fancyList;
  }

  /// Creates a list containing the elements of [other], converting nested
  /// [Map]s and [List]s into [FancyMap]s and [FancyList]s.
  factory FancyList.from(List other) {
    FancyList<T> fancyList = FancyList<T>();
    for (var element in other) {
      if (element is Map) {
        fancyList.add(FancyMap.initWithMap(element) as T);
      } else if (element is List) {
        fancyList.add(FancyList.initWithList(element) as T);
      } else {
        fancyList.add(element as T);
      }
    }
    return fancyList;
  }

  @override
  int get length => _values.length;

  @override
  set length(int newLength) {
    _values.length = newLength;
  }

  String _pathFor(Object index) => "${attributePath ?? ""}[$index]";

  @override
  void add(T element) {
    final event =
        FancyCollectionEvent()
          ..type = FancyCollectionEventType.add
          ..index = length
          ..value = element;
    event.attributePath = _pathFor(event.index!);

    _values.add(element);
    processEvent(event);
  }

  @override
  T operator [](int index) {
    return _values[index];
  }

  @override
  void operator []=(int index, T value) {
    final event =
        FancyCollectionEvent()
          ..type = FancyCollectionEventType.update
          ..index = index
          ..value = value
          ..attributePath = _pathFor(index);

    _values[index] = value;
    processEvent(event);
  }

  @override
  void removeWhere(bool Function(T element) test) {
    final event =
        FancyCollectionEvent()
          ..type = FancyCollectionEventType.remove
          ..index = -1
          ..attributePath = _pathFor('*');

    super.removeWhere(test);
    processEvent(event);
  }

  @override
  T removeAt(int index) {
    final event =
        FancyCollectionEvent()
          ..type = FancyCollectionEventType.remove
          ..value = this[index]
          ..index = index
          ..attributePath = _pathFor(index);

    T returnValue = super.removeAt(index);
    processEvent(event);
    return returnValue;
  }

  @override
  T removeLast() {
    final event =
        FancyCollectionEvent()
          ..type = FancyCollectionEventType.remove
          ..value = last
          ..index = length - 1
          ..attributePath = _pathFor(length - 1);

    T returnValue = super.removeLast();
    processEvent(event);
    return returnValue;
  }

  @override
  void removeRange(int start, int end) {
    final event =
        FancyCollectionEvent()
          ..type = FancyCollectionEventType.remove
          ..index = -1
          ..attributePath = _pathFor('*');

    super.removeRange(start, end);
    processEvent(event);
  }
}
