import 'package:fancy_collection/fancy_collection_event.dart';
import 'package:fancy_collection/fancy_collection_value_change_listener.dart';
import 'package:flutter/foundation.dart';

/// Listener bookkeeping and event dispatch shared by [FancyList] and
/// [FancyMap].
///
/// Listeners are registered against an attribute path such as `name`,
/// `items[0]`, `user.address.city` or `*`. A listener receives an event when
/// its path and the event's path agree segment by segment until one of them
/// ends, so a listener on `user` is notified about `user.address.city`, and a
/// listener on `user.address.city` is notified when `user` is replaced. A `*`
/// segment matches anything from that point on; a listener on `*` receives
/// every event. An `[*]` index matches any list index, and bulk removals
/// (reported at `[*]`) match listeners on any index.
///
/// Events bubble up to the [parent] collection, so listeners only need to be
/// registered on the root.
mixin FancyCollectionMixin {
  /// The collection that contains this one, if it is nested.
  FancyCollectionMixin? parent;

  /// Path of this collection inside its [parent], or `null` for the root.
  String? attributePath;

  static final RegExp _pathSegmentsRegExp = RegExp(
    r"\*|\w*|\[[0-9,*]*[0-9*]+\]",
  );

  final Map<String, List<FancyCollectionValueChangeListener>> _listeners = {};
  final Map<String, ValueNotifier<FancyCollectionEvent>> _valueNotifiers = {};

  /// Returns a [ValueNotifier] that is updated with the latest event matching
  /// [attributePath].
  ///
  /// The same notifier is returned for repeated calls with the same path, so
  /// it can be used directly with a `ValueListenableBuilder`.
  ValueNotifier<FancyCollectionEvent> getValueNotifier(String attributePath) {
    return _valueNotifiers.putIfAbsent(
      attributePath,
      () => ValueNotifier<FancyCollectionEvent>(FancyCollectionEvent()),
    );
  }

  /// Registers [listener] for changes matching [attributePath].
  void addListener(
    String attributePath,
    FancyCollectionValueChangeListener listener,
  ) {
    _listeners.putIfAbsent(attributePath, () => []).add(listener);
  }

  /// Unregisters a [listener] previously added for [attributePath].
  void removeListener(
    String attributePath,
    FancyCollectionValueChangeListener listener,
  ) {
    _listeners[attributePath]?.remove(listener);
  }

  /// Unregisters every listener added for [attributePath].
  void removeAllListeners(String attributePath) {
    _listeners.remove(attributePath);
  }

  /// Delivers [event] to matching listeners and value notifiers, then
  /// forwards it to the [parent] collection.
  ///
  /// Called by the collection implementations after each modification; it is
  /// not normally called directly.
  void processEvent(FancyCollectionEvent event) {
    final eventSegments = _segments(event.attributePath);

    _listeners.forEach((listenerPath, listeners) {
      if (!_pathMatches(eventSegments, _segments(listenerPath))) return;

      for (final listener in List.of(listeners)) {
        if (listener.listensFor == FancyCollectionEventType.all ||
            listener.listensFor == event.type) {
          listener.onCollectionEvent(event);
        }
      }
    });

    _valueNotifiers.forEach((listenerPath, valueNotifier) {
      if (_pathMatches(eventSegments, _segments(listenerPath))) {
        valueNotifier.value = event;
      }
    });

    parent?.processEvent(event);
  }

  static List<String> _segments(String path) =>
      _pathSegmentsRegExp.allMatches(path).map((m) => m[0]!).toList();

  static bool _pathMatches(List<String> event, List<String> listener) {
    final common =
        event.length < listener.length ? event.length : listener.length;

    for (int i = 0; i < common; i++) {
      if (listener[i] == '*' || event[i] == '*') return true;
      if (event[i] != listener[i]) return false;
    }

    return true;
  }
}
