## 0.1.0

Initial public release.

* `FancyList` and `FancyMap`: observable `List` and `Map` implementations.
* Path-based listeners (`addListener`) with `*` wildcards and per-event-type
  filtering.
* `getValueNotifier` for use with `ValueListenableBuilder`.
* Nested maps and lists bubble their events up to the root collection.
