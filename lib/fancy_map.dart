library listenable_map;

import 'dart:collection';

import 'package:fancy_collection/fancy_collection_event.dart';
import 'package:fancy_collection/fancy_list.dart';
import 'package:fancy_collection/fancy_collection_mixin.dart';

class FancyMap<K, V> extends MapBase<K, V> with FancyCollectionMixin {
  final Map<K, V> _values = {};

  static FancyMap initWithMap(Map other) {
    FancyMap listenableMap = FancyMap();

    other.forEach((key, value) {
      // // if (value is Map) {
      // //   listenableMap[key] = ListenableMap.initWithMap(value);
      // // }
      // if (value is List) {
      //   listenableMap[key] = ListenableList.initWithList(value);
      // } else {
      listenableMap[key] = value;
      // }
    });

    return listenableMap;
  }

  @override
  V? operator [](Object? key) {
    V? returnValue = _values[key];
    return returnValue;
  }

  @override
  void operator []=(key, value) {
    FancyCollectionEvent listenableContainerEvent = FancyCollectionEvent();

    if (_values.containsKey(key)) {
      listenableContainerEvent.type = FancyCollectionEventType.update;
      listenableContainerEvent.oldValue = _values[key];
    } else {
      listenableContainerEvent.type = FancyCollectionEventType.add;
    }

    listenableContainerEvent.value = value;
    listenableContainerEvent.key = key;

    if (value is Map) {
      FancyMap nestedMap = FancyMap.initWithMap(value);
      nestedMap.parent = this;
      nestedMap.attributePath = "${(attributePath != null) ? "$attributePath." : ""}$key";
      _values[key] = nestedMap as V;
    } else if (value is List) {
      FancyList nestedList = FancyList.initWithList(value);
      nestedList.parent = this;
      nestedList.attributePath = "${(attributePath != null) ? "$attributePath." : ""}$key";
      _values[key] = nestedList as V;
    } else {
      _values[key] = value;
    }

    listenableContainerEvent.attributePath = "${(attributePath != null) ? "$attributePath." : ""}$key";
    processEvent(listenableContainerEvent);
  }

  @override
  void clear() {
    _values.clear();
  }

  @override
  Iterable<K> get keys => _values.keys;

  @override
  V? remove(Object? key) {
    V returnValue = _values[key] as V;
    _values.remove(key);

    FancyCollectionEvent listenableContainerEvent = FancyCollectionEvent();
    listenableContainerEvent.attributePath = "${(attributePath != null) ? "$attributePath." : ""}$key";
    listenableContainerEvent.key = key;
    listenableContainerEvent.type = FancyCollectionEventType.remove;

    processEvent(listenableContainerEvent);
    return returnValue;
  }
}
