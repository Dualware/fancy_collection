part of 'fancy_collection_core.dart';

/// Listener bookkeeping and event dispatch shared by [FancyList] and
/// [FancyMap].
///
/// Listeners are registered against an attribute path relative to the
/// collection, such as `name`, `items[0]`, `user.address.city` or `*`. A
/// listener receives an event when its path and the event's path agree
/// segment by segment until one of them ends, so a listener on `user` is
/// notified about `user.address.city`, and a listener on `user.address.city`
/// is notified when `user` is replaced.
///
/// * `*` matches anything from that segment on; a listener on `*` receives
///   every event.
/// * `[*]` matches any list index, and bulk list changes (reported at `[*]`)
///   match listeners on any index.
/// * Keys are compared with the key's `toString()`. Escape `.`, `[`, `]`
///   and `\` inside keys, or a key that is exactly `*`, with `\`.
///
/// Events bubble up from nested collections, so listeners usually only need
/// to be registered on the root.
///
/// Listeners are held strongly and indefinitely; there is no `dispose()`.
/// This matches [ChangeNotifier.addListener]: whoever calls [addListener]
/// is responsible for calling [removeListener] once they no longer need
/// the callback, typically from their own `dispose()`. This matters most
/// when a listener closure captures something shorter-lived than the
/// collection it's registered on — a widget's `State`, for example — since
/// the collection will keep that closure, and whatever it captures, alive
/// for as long as the collection itself lives.
mixin FancyCollectionMixin {
  FancyCollectionMixin? _parent;
  Object? _segment;

  final Map<String, List<FancyCollectionValueChangeListener>> _listeners = {};
  final Map<String, ValueNotifier<FancyCollectionEvent>> _valueNotifiers = {};
  final Map<String, List<_Pattern>> _patterns = {};

  List<_Pattern> _patternFor(String path) =>
      _patterns[path] ??= _parsePath(path);

  /// Returns a [ValueNotifier] that is updated with the latest event matching
  /// [attributePath].
  ///
  /// The same notifier is returned for repeated calls with the same path, so
  /// it can be used directly with a `ValueListenableBuilder`.
  ///
  /// Throws an [ArgumentError] if [attributePath] is malformed.
  ValueNotifier<FancyCollectionEvent> getValueNotifier(String attributePath) {
    _patternFor(attributePath);
    return _valueNotifiers.putIfAbsent(
      attributePath,
      () => ValueNotifier<FancyCollectionEvent>(FancyCollectionEvent()),
    );
  }

  /// Registers [listener] for changes matching [attributePath].
  ///
  /// [listener] is held strongly until [removeListener] or
  /// [removeAllListeners] is called; see the class documentation.
  ///
  /// Throws an [ArgumentError] if [attributePath] is malformed.
  void addListener(
    String attributePath,
    FancyCollectionValueChangeListener listener,
  ) {
    _patternFor(attributePath);
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

  void _emit(FancyCollectionEvent event) {
    for (final entry in _listeners.entries.toList()) {
      if (!_matches(_patternFor(entry.key), event._segments)) continue;

      for (final listener in List.of(entry.value)) {
        if (listener.listensFor == FancyCollectionEventType.all ||
            listener.listensFor == event.type) {
          listener.onCollectionEvent(event);
        }
      }
    }

    for (final entry in _valueNotifiers.entries.toList()) {
      if (_matches(_patternFor(entry.key), event._segments)) {
        entry.value.value = event;
      }
    }

    final parent = _parent;
    if (parent != null) {
      parent._emit(event._withParentSegment(_segment));
    }
  }

  /// Returns a detached copy of this collection with the same type
  /// arguments.
  FancyCollectionMixin _copy();

  /// Prepares [value] to be stored at [segment] in a collection whose element
  /// type is [E].
  ///
  /// Root [FancyMap]s and [FancyList]s are adopted as children; ones that
  /// already have a parent are copied. Plain maps and lists are converted
  /// when an observable collection is assignable to [E]. Anything else is
  /// returned unchanged.
  Object? _adopt<E>(Object? value, Object? segment) {
    final FancyCollectionMixin? child;
    if (value is FancyCollectionMixin) {
      for (FancyCollectionMixin? c = this; c != null; c = c._parent) {
        if (identical(c, value)) {
          throw ArgumentError.value(
            value,
            'value',
            'A collection cannot contain itself',
          );
        }
      }
      if (value is! E) return value;
      child = value._parent == null ? value : value._copy();
    } else if (value is Map) {
      child = _observableMap<E>(value);
    } else if (value is List) {
      child = _observableList<E>(value);
    } else {
      child = null;
    }

    if (child == null) return value;
    child._parent = this;
    child._segment = segment;
    return child;
  }

  /// Detaches [value] if it is a child of this collection.
  void _release(Object? value) {
    if (value is FancyCollectionMixin && identical(value._parent, this)) {
      value._parent = null;
      value._segment = null;
    }
  }
}

bool _isSubtype<S, T>() => <S>[] is List<T>;

FancyMap? _observableMap<E>(Map value) {
  if (_isSubtype<FancyMap<dynamic, dynamic>, E>()) {
    return FancyMap<dynamic, dynamic>()..addAll(value);
  }
  if (_isSubtype<FancyMap<String, dynamic>, E>() &&
      value.keys.every((key) => key is String)) {
    final map = FancyMap<String, dynamic>();
    value.forEach((key, v) => map[key as String] = v);
    return map;
  }
  return null;
}

FancyList? _observableList<E>(List value) {
  if (_isSubtype<FancyList<dynamic>, E>()) {
    return FancyList<dynamic>()..addAll(value);
  }
  return null;
}
