part of 'fancy_collection_core.dart';

/// A callback registered on a collection with
/// [FancyCollectionMixin.addListener].
class FancyCollectionValueChangeListener {
  /// The event type this listener reacts to. Defaults to every type.
  final FancyCollectionEventType listensFor;

  /// Called after a matching change has been applied to the collection.
  final void Function(FancyCollectionEvent event) onCollectionEvent;

  /// Creates a listener that calls [onCollectionEvent] for events of type
  /// [listensFor].
  FancyCollectionValueChangeListener({
    this.listensFor = FancyCollectionEventType.all,
    required this.onCollectionEvent,
  });
}
