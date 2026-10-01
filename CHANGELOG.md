## 0.1.0

Initial public release.

* `FancyList` and `FancyMap`: observable `List` and `Map` implementations.
  Every mutating operation emits exactly one event per affected entry;
  bulk list changes (`removeWhere`, `clear`, `sort`, ...) emit a single
  `[*]` event.
* Path-based listeners (`addListener`) with `*` and `[*]` wildcards,
  backslash escaping for arbitrary keys, and per-event-type filtering.
  Malformed paths throw an `ArgumentError`.
* `getValueNotifier` for use with `ValueListenableBuilder`.
* Nested maps and lists — in both `FancyMap` and `FancyList` — bubble their
  events up to the root, with paths relative to the listening collection.
  Removed or replaced children are detached from their parent.
* Typed collections such as `FancyMap<String, Map<String, dynamic>>` and
  `FancyList<List<int>>` are supported; values that cannot be made
  observable for the declared type are stored unchanged.
