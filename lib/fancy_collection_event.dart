import 'package:fancy_collection/fancy_list.dart';
import 'package:fancy_collection/fancy_map.dart';

/// Describes a change that happened in a [FancyList] or [FancyMap].
///
/// An event is delivered to listeners after the collection has been
/// modified. Because the same class serves both lists and maps, some fields
/// only apply to one kind of collection and are `null` otherwise.
class FancyCollectionEvent {
  /// The kind of change that happened.
  FancyCollectionEventType? type;

  /// Path of the changed entry, relative to the root collection.
  ///
  /// Map keys are joined with `.` and list indexes are written in brackets,
  /// e.g. `user.addresses[2].city`. Bulk list removals use `[*]` as the index.
  String attributePath = '';

  /// The key of the changed entry. Only set for [FancyMap] events.
  dynamic key;

  /// The previous value of the entry. Only set for
  /// [FancyCollectionEventType.update] events on a [FancyMap].
  dynamic oldValue;

  /// The new value of the entry.
  ///
  /// For [FancyList] removals this is the removed element. It is `null` for
  /// [FancyMap] removals and for bulk list removals.
  dynamic value;

  /// The index of the changed element. Only set for [FancyList] events.
  ///
  /// It is `-1` when several elements were removed at once, for example by
  /// [FancyList.removeWhere] or [FancyList.removeRange].
  int? index;
}

/// The kind of change described by a [FancyCollectionEvent].
enum FancyCollectionEventType {
  /// An entry was added to the collection.
  add,

  /// An entry was removed from the collection.
  remove,

  /// An existing entry was replaced with a new value.
  update,

  /// Used by listeners to receive every kind of event.
  all,
}
