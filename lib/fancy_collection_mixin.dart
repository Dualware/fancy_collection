import 'package:fancy_collection/fancy_collection_event.dart';
import 'package:fancy_collection/fancy_collection_value_change_listener.dart';
import 'package:flutter/foundation.dart';

mixin FancyCollectionMixin {
  FancyCollectionMixin? parent;
  String? attributePath;

  final RegExp _arrayIndexesRegexp = RegExp(r"\*|\w*|\[[0-9,*]*[0-9*]+\]");

  final Map<String, List<FancyCollectionValueChangeListener>> _listeners = {};
  final Map<String, ValueNotifier<FancyCollectionEvent>> _valueNotifiers = {};

  ValueNotifier<FancyCollectionEvent> getValueNotifier(String attributePath) {
    return _valueNotifiers.putIfAbsent(
      attributePath,
      () => ValueNotifier<FancyCollectionEvent>(FancyCollectionEvent()),
    );
  }

  void addListener(String attributePath, FancyCollectionValueChangeListener listener) {
    if (!_listeners.containsKey(attributePath)) {
      _listeners[attributePath] = [];
    }

    _listeners[attributePath]!.add(listener);
  }

  void removeListener(String attributePath, FancyCollectionValueChangeListener listener) {
    _listeners[attributePath]!.remove(listener);
  }

  void removeAllListeners(String attributePath) {
    _listeners[attributePath] = [];
  }

  void processEvent(FancyCollectionEvent listenableContainerEvent) {
    String eventAttributePath = listenableContainerEvent.attributePath;

    Iterable<RegExpMatch> eventAttributePathMatches = _arrayIndexesRegexp.allMatches(eventAttributePath);

    _listeners.forEach((listenerAttributePath, listeners) {
      bool potentialMatch = false;
      Iterable<RegExpMatch> listenerAttributePathMatches = _arrayIndexesRegexp.allMatches(listenerAttributePath);

      for (int i = 0; i < eventAttributePathMatches.length; i++) {
        Match eventAttributeMatch = eventAttributePathMatches.elementAt(i);
        Match listenerAttributeMatch = listenerAttributePathMatches.elementAt(i);

        String matchedEventAttribute = eventAttributeMatch.input.substring(
          eventAttributeMatch.start,
          eventAttributeMatch.end,
        );
        String matchedEventListenerAttribute = listenerAttributeMatch.input.substring(
          listenerAttributeMatch.start,
          listenerAttributeMatch.end,
        );

        if (matchedEventAttribute == matchedEventListenerAttribute) {
          potentialMatch = true;
        } else if (matchedEventListenerAttribute == "*") {
          // Any match is good with asterix
          potentialMatch = true;
          break;
        } else {
          potentialMatch = false;
          break;
        }
      }

      if (potentialMatch) {
        for (FancyCollectionValueChangeListener listener in listeners) {
          if (listener.listensFor == FancyCollectionEventType.all ||
              listener.listensFor == listenableContainerEvent.type) {
            listener.onCollectionEvent(listenableContainerEvent);
          }
        }
      }
    });

    _valueNotifiers.forEach((listenerAttributePath, valueNotifier) {
      bool potentialMatch = false;
      Iterable<RegExpMatch> listenerAttributePathMatches = _arrayIndexesRegexp.allMatches(listenerAttributePath);

      for (int i = 0; i < eventAttributePathMatches.length; i++) {
        Match eventAttributeMatch = eventAttributePathMatches.elementAt(i);
        Match listenerAttributeMatch = listenerAttributePathMatches.elementAt(i);

        String matchedEventAttribute = eventAttributeMatch.input.substring(
          eventAttributeMatch.start,
          eventAttributeMatch.end,
        );
        String matchedEventListenerAttribute = listenerAttributeMatch.input.substring(
          listenerAttributeMatch.start,
          listenerAttributeMatch.end,
        );

        if (matchedEventAttribute == matchedEventListenerAttribute) {
          potentialMatch = true;
        } else if (matchedEventListenerAttribute == "*") {
          // Any match is good with asterix
          potentialMatch = true;
          break;
        } else {
          potentialMatch = false;
          break;
        }
      }

      if (potentialMatch) {
        valueNotifier.value = listenableContainerEvent;
      }
    });

    // Call parent container listeners too
    parent?.processEvent(listenableContainerEvent);
  }
}
