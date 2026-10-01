part of 'fancy_collection_core.dart';

/// Describes a change that happened in a [FancyList] or [FancyMap].
///
/// An event is delivered to listeners after the collection has been
/// modified. Because the same class serves both lists and maps, some fields
/// only apply to one kind of collection and are `null` otherwise.
class FancyCollectionEvent {
  /// The kind of change that happened.
  FancyCollectionEventType? type;

  /// The key of the changed entry. Only set for [FancyMap] events.
  dynamic key;

  /// The previous value of the entry. Set for updates and for removals of a
  /// single entry.
  dynamic oldValue;

  /// The new value of the entry, as stored in the collection (nested maps
  /// and lists may have been converted to [FancyMap] / [FancyList]).
  ///
  /// For [FancyList] removals this is the removed element. It is `null` for
  /// [FancyMap] removals and for bulk changes.
  dynamic value;

  /// The index of the changed element. Only set for [FancyList] events.
  ///
  /// It is `-1` for bulk changes that affect several elements at once, such
  /// as [FancyList.removeWhere], [FancyList.clear] or [FancyList.sort].
  int? index;

  List<Object?> _segments = const [];

  /// Path of the changed entry, relative to the collection whose listener
  /// receives the event.
  ///
  /// Map keys are joined with `.` and list indexes are written in brackets,
  /// e.g. `user.addresses[2].city`. Bulk list changes use `[*]` as the index.
  /// `.`, `[`, `]` and `\` inside keys, and a key that is exactly `*`, are
  /// escaped with `\`, so the path can be passed back to
  /// [FancyCollectionMixin.addListener].
  String get attributePath => _formatPath(_segments);

  FancyCollectionEvent _withParentSegment(Object? segment) =>
      FancyCollectionEvent()
        ..type = type
        ..key = key
        ..oldValue = oldValue
        ..value = value
        ..index = index
        .._segments = [segment, ..._segments];
}

/// The kind of change described by a [FancyCollectionEvent].
enum FancyCollectionEventType {
  /// An entry was added to the collection.
  add,

  /// One or more entries were removed from the collection.
  remove,

  /// An existing entry was replaced, or the order of a list changed.
  update,

  /// Used by listeners to receive every kind of event.
  all,
}
