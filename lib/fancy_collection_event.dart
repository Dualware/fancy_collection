import 'package:fancy_collection/fancy_list.dart';
import 'package:fancy_collection/fancy_map.dart';

/// ListenableContainerEvent object is passed to listener along with the event type,
/// key, value and the index for the list type containers.
///
/// Not all the attributes are guaranteed to have a value as ListenableContainerEvent class
/// serves both List and Map collections.
///
/// ListenableContainerEvent is always triggered after the collection is maniuplated.
class FancyCollectionEvent {
  /// The type of the event happened in the collection.
  FancyCollectionEventType? type;

  late String attributePath;

  /// For Map collections, it includes the key
  /// of the object where the even happened.
  /// It is only populated for [FancyMap] collections.
  late dynamic key;

  /// It includes the value of the collection item before the event happened.
  /// It is only populated for [FancyCollectionEventType.update] event type.
  late dynamic oldValue;

  /// It includes the new value after the event happened on the collection item.
  /// It is not populated for [FancyCollectionEventType.remove] event type.
  late dynamic value;

  /// It includes the index of the collection item that the event happened.
  /// This value is set to -1 when multiple indexes are removed from collection using one of the range removel functions such as removeWhere()
  /// It is only populated for [FancyList] collections.
  late int index;
}

enum FancyCollectionEventType {
  /// Triggered when a new object added to the collection.
  add,

  /// Triggered when an object is removed from the collection.
  remove,

  /// Triggered when an object is updated in the collection.
  update,

  /// Triggered for all the events happening in the collection.
  all,
}
