import 'dart:collection';

import 'package:fancy_collection/fancy_collection_event.dart';
import 'package:fancy_collection/fancy_map.dart';
import 'package:fancy_collection/fancy_collection_mixin.dart';

class FancyList<T> extends ListBase<T> with FancyCollectionMixin {
  final List<T> _values = [];

  FancyList();

  static FancyList initWithList(List other, {Type? listType}) {
    FancyList listenableList = FancyList();

    for (var element in other) {
      if (element is Map) {
        listenableList.add(FancyMap.initWithMap(element));
      } else if (element is List) {
        listenableList.add(FancyList.initWithList(element));
      } else {
        listenableList.add(element);
      }
    }

    return listenableList;
  }

  factory FancyList.from(List other) {
    FancyList<T> listenableList = FancyList<T>();
    for (var element in other) {
      if (element is Map) {
        listenableList.add(FancyMap.initWithMap(element) as T);
      } else if (element is List) {
        listenableList.add(FancyList.initWithList(element) as T);
      } else {
        listenableList.add(element as T);
      }
    }
    return listenableList;
  }

  @override
  int get length => _values.length;

  @override
  set length(int newLength) {
    _values.length = newLength;
  }

  @override
  void add(T element) {
    FancyCollectionEvent listenableContainerEvent = FancyCollectionEvent();
    listenableContainerEvent.type = FancyCollectionEventType.add;
    listenableContainerEvent.index = this.length;
    listenableContainerEvent.value = element;
    listenableContainerEvent.attributePath =
        "${(attributePath != null) ? "$attributePath" : ""}[${listenableContainerEvent.index}]";

    _values.add(element);
    processEvent(listenableContainerEvent);
  }

  @override
  T operator [](int index) {
    return _values[index];
  }

  @override
  void operator []=(int index, T value) {
    FancyCollectionEvent listenableContainerEvent = FancyCollectionEvent();
    listenableContainerEvent.type = FancyCollectionEventType.update;
    listenableContainerEvent.index = index;
    listenableContainerEvent.value = value;
    listenableContainerEvent.attributePath =
        "${(attributePath != null) ? "$attributePath" : ""}[${listenableContainerEvent.index}]";

    _values[index] = value;
    processEvent(listenableContainerEvent);
  }

  @override
  bool remove(Object? element) {
    FancyCollectionEvent listenableContainerEvent = FancyCollectionEvent();
    listenableContainerEvent.type = FancyCollectionEventType.update;

    listenableContainerEvent.value = element;

    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) {
        listenableContainerEvent.index = i;
        listenableContainerEvent.attributePath =
            "${(attributePath != null) ? "$attributePath" : ""}[${listenableContainerEvent.index}]";
        this._closeGap(i, i + 1);
        processEvent(listenableContainerEvent);
        return true;
      }
    }
    return false;
  }

  @override
  void removeWhere(bool Function(T element) test) {
    FancyCollectionEvent listenableContainerEvent = FancyCollectionEvent();
    listenableContainerEvent.type = FancyCollectionEventType.remove;
    listenableContainerEvent.value = null;
    listenableContainerEvent.index = -1;
    listenableContainerEvent.attributePath =
        "${(attributePath != null) ? "$attributePath" : ""}[*]";

    super.removeWhere(test);
    processEvent(listenableContainerEvent);
  }

  @override
  T removeAt(int index) {
    FancyCollectionEvent listenableContainerEvent = FancyCollectionEvent();
    listenableContainerEvent.type = FancyCollectionEventType.remove;
    listenableContainerEvent.value = this[index];
    listenableContainerEvent.index = index;
    listenableContainerEvent.attributePath =
        "${(attributePath != null) ? "$attributePath" : ""}[${listenableContainerEvent.index}]";

    T returnValue = super.removeAt(index);
    processEvent(listenableContainerEvent);
    return returnValue;
  }

  @override
  T removeLast() {
    FancyCollectionEvent listenableContainerEvent = FancyCollectionEvent();
    listenableContainerEvent.type = FancyCollectionEventType.remove;
    listenableContainerEvent.value = last;
    listenableContainerEvent.index = length - 1;
    listenableContainerEvent.attributePath =
        "${(attributePath != null) ? "$attributePath" : ""}[${listenableContainerEvent.index}]";

    T returnValue = super.removeLast();
    processEvent(listenableContainerEvent);
    return returnValue;
  }

  @override
  void removeRange(int start, int end) {
    FancyCollectionEvent listenableContainerEvent = FancyCollectionEvent();
    listenableContainerEvent.type = FancyCollectionEventType.remove;
    listenableContainerEvent.value = null;
    listenableContainerEvent.index - 1;
    listenableContainerEvent.attributePath =
        "${(attributePath != null) ? "$attributePath" : ""}[*]";

    super.removeRange(start, end);
    processEvent(listenableContainerEvent);
  }

  void _closeGap(int start, int end) {
    int length = this.length;
    assert(0 <= start);
    assert(start < end);
    assert(end <= length);
    int size = end - start;
    for (int i = end; i < length; i++) {
      this[i - size] = this[i];
    }
    this.length = length - size;
  }
}
