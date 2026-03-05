import 'package:fancy_collection/fancy_collection_event.dart';

class FancyCollectionValueChangeListener {
  final FancyCollectionEventType listensFor;
  final Function(FancyCollectionEvent event) onCollectionEvent;

  FancyCollectionValueChangeListener({this.listensFor = FancyCollectionEventType.all, required this.onCollectionEvent});
}
