/// Observable [List] and [Map] implementations that notify listeners about
/// changes, including changes inside nested collections.
library;

export 'src/fancy_collection_core.dart'
    show
        FancyCollectionEvent,
        FancyCollectionEventType,
        FancyCollectionMixin,
        FancyCollectionValueChangeListener,
        FancyList,
        FancyMap;
