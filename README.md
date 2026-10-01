# fancy_collection

[![pub package](https://img.shields.io/pub/v/fancy_collection.svg)](https://pub.dev/packages/fancy_collection)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Published by [Dualware Software Service Inc.](https://www.dualware.com)

Observable `List` and `Map` implementations for Flutter. `FancyList` and
`FancyMap` behave like regular collections, but notify listeners whenever an
entry is added, updated or removed — including changes made deep inside
nested maps and lists.

## Why fancy_collection?

Rebuilding a widget when *some* data inside a list or map changes usually
means one of:

- wrapping the whole thing in a `ChangeNotifier` and calling `notifyListeners()`
  by hand after every mutation (easy to forget one), or
- rebuilding the entire widget whenever *anything* in the structure
  changes, even a field three levels deep that this particular widget
  doesn't care about.

`fancy_collection` lets you subscribe to a specific path — `cart.items[2].price`,
`user.address.city` — and only hear about changes to that path, while still
using plain `List`/`Map` APIs (`add`, `[]=`, `remove`, `for`-loops, ...) to
read and write the data. No manual `notifyListeners()` calls, no rebuilding
more than you need to.

## Contents

- [Features](#features)
- [Getting started](#getting-started)
- [Usage](#usage)
- [Which events are emitted](#which-events-are-emitted)
- [How path matching works](#how-path-matching-works)
- [Nested collections](#nested-collections)
- [Event fields](#event-fields)
- [Listener lifecycle](#listener-lifecycle)
- [FAQ](#faq)
- [Related packages](#related-packages)

## Features

- Drop-in `List` / `Map` replacements (`FancyList<T>` extends `ListBase<T>`,
  `FancyMap<K, V>` extends `MapBase<K, V>`) — use them anywhere you'd use a
  `List` or `Map`.
- Listen to the whole collection or to a specific path such as
  `user.addresses[0].city`, with `*` wildcards.
- Filter listeners by event type: `add`, `update`, `remove` or `all`.
- Nested `Map`s and `List`s are converted automatically and bubble their
  events up to the root, so one listener on the root hears about changes
  anywhere underneath it.
- `getValueNotifier` exposes any path as a `ValueNotifier` for use with
  `ValueListenableBuilder`, with no extra wiring.

## Getting started

```sh
flutter pub add fancy_collection
```

```dart
import 'package:fancy_collection/fancy_collection.dart';
```

This package depends on Flutter (for `ValueNotifier`) — it doesn't work in
a plain Dart (non-Flutter) project.

## Usage

### Listening to a list

```dart
final todos = FancyList<String>();

todos.addListener(
  '*',
  FancyCollectionValueChangeListener(
    onCollectionEvent: (event) {
      print('${event.type} ${event.attributePath}: ${event.value}');
    },
  ),
);

todos.add('Write docs');   // FancyCollectionEventType.add [0]: Write docs
todos[0] = 'Publish';      // FancyCollectionEventType.update [0]: Publish
todos.removeAt(0);         // FancyCollectionEventType.remove [0]: Publish
```

### Listening to a path in a nested map

```dart
final user = FancyMap<String, dynamic>();
user['address'] = {'city': 'Berlin', 'zip': '10115'};

user.addListener(
  'address.city',
  FancyCollectionValueChangeListener(
    listensFor: FancyCollectionEventType.update,
    onCollectionEvent: (event) {
      print('City changed from ${event.oldValue} to ${event.value}');
    },
  ),
);

(user['address'] as Map)['city'] = 'Paris'; // City changed from Berlin to Paris
(user['address'] as Map)['zip'] = '75001';  // not delivered: different path
```

### Rebuilding widgets

No `StatefulWidget`, no manual `setState` — read the collection straight
from the builder:

```dart
ValueListenableBuilder<FancyCollectionEvent>(
  valueListenable: todos.getValueNotifier('*'),
  builder: (context, event, _) => Text('${todos.length} todos'),
);
```

Narrow the path to avoid rebuilding on unrelated changes, e.g.
`cart.getValueNotifier('items[*].price')` rebuilds only when an item's
price changes, not when its name does.

## Which events are emitted

Every mutating operation emits exactly one event per affected entry, after
the change has been applied:

| Operation                                                   | Events                                         |
| ----------------------------------------------------------- | ---------------------------------------------- |
| `add`, `addAll`, `insert`, `insertAll`, growing `length`    | `add` per new element, at its final index      |
| `list[i] = v`, `setAll`, `setRange`, `fillRange`            | `update` per element                           |
| `remove`, `removeAt`, `removeLast`                          | `remove` at the element's former index         |
| `removeWhere`, `retainWhere`, `removeRange`, `clear`, shrinking `length` | one bulk `remove` at `[*]`, if anything was removed |
| `sort`, `shuffle`                                           | one bulk `update` at `[*]`                     |
| `replaceRange`                                              | bulk `remove`, then `add` per new element      |
| `map[k] = v`, `addAll`, `putIfAbsent`, `update`, `updateAll` | `add` or `update` per entry                   |
| `remove`, `removeWhere`, `clear` (map)                      | `remove` per entry                             |

## How path matching works

Event paths join map keys with `.` and wrap list indexes in brackets, e.g.
`orders[2].items[0].price`. Paths are relative to the collection the
listener is registered on. A listener path is compared to an event path
segment by segment until one of them ends:

| Listener path   | Receives events for                                                  |
| --------------- | -------------------------------------------------------------------- |
| `*`             | everything                                                           |
| `address`       | `address` and anything below it, e.g. `address.city`                 |
| `address.city`  | `address.city`, and `address` when the whole map is replaced         |
| `items[*]`      | any element of `items`                                               |
| `items[2]`      | `items[2]` and below, and bulk changes to `items` (`items[*]`)       |

Keys are matched exactly against the key's `toString()`, so any key can be
used — including ones with spaces, dashes or non-ASCII characters. Escape
`.`, `[`, `]` and `\` inside a key, or a key that is exactly `*`, with a
backslash: `r'file\.txt'`, `r'\*'`. Event paths use the same escaping, so
`event.attributePath` can be passed straight back to `addListener`.
`items.1` (map key `"1"`) and `items[1]` (list index 1) are different paths.
A malformed path throws an `ArgumentError` when the listener is added —
typically a typo you'll catch the first time that line runs.

## Nested collections

`Map` and `List` values stored in a `FancyMap` or `FancyList` become nested
observable collections and report their changes to the parent:

- A plain `Map` / `List` is converted (copied) into a `FancyMap` /
  `FancyList` when that fits the declared element type — e.g. `dynamic`,
  `Object?`, `Map<String, dynamic>` or `List<dynamic>`. Other values, such
  as a `List<int>` stored in a `FancyMap<String, List<int>>`, are stored
  unchanged and are not observed.
- A `FancyMap` / `FancyList` that is not part of another collection is
  stored as-is (not copied), so listeners already registered on it keep
  working. One that already belongs to another collection is copied,
  keeping its type arguments.
- A collection removed from its parent, or replaced by another value, stops
  reporting to that parent.
- A collection cannot contain itself; that throws an `ArgumentError`.

## Event fields

| Field           | List events                                        | Map events                          |
| --------------- | -------------------------------------------------- | ----------------------------------- |
| `type`          | `add`, `update`, `remove`                          | `add`, `update`, `remove`           |
| `attributePath` | e.g. `[3]`, or `[*]` for bulk changes              | e.g. `address.city`                 |
| `index`         | element index, `-1` for bulk changes               | `null`                              |
| `key`           | `null`                                             | entry key                           |
| `value`         | stored element; the removed element on `remove`    | stored value; `null` on `remove`    |
| `oldValue`      | previous element on `update`; removed element on `remove` | previous value on `update` and `remove` |

## Listener lifecycle

`addListener` holds the listener strongly and indefinitely — there is no
`dispose()`. This matches `ChangeNotifier.addListener`: whoever registers a
listener is responsible for calling `removeListener` (or
`removeAllListeners`) once it's no longer needed, typically from their own
`dispose()`.

This matters most when a listener closure captures something shorter-lived
than the collection it's registered on, such as a widget's `State`:

```dart
class _MyWidgetState extends State<MyWidget> {
  late final _listener = FancyCollectionValueChangeListener(
    onCollectionEvent: (e) => setState(() {}), // captures `this`
  );

  @override
  void initState() {
    super.initState();
    widget.model.items.addListener('*', _listener);
  }

  @override
  void dispose() {
    widget.model.items.removeListener('*', _listener);
    super.dispose();
  }
}
```

If `widget.model` outlives the widget (e.g. it's cached or app-wide) and the
listener in `initState` is never removed, the collection keeps that closure
— and the `State` it captures — alive for as long as the collection lives.
A collection whose lifetime matches its listeners' (the common case: a
request/response model scoped to one screen) doesn't need this care, since
everything is collected together once nothing external references it.

If you use `getValueNotifier` with a `ValueListenableBuilder` instead of
`addListener` directly, there's nothing to clean up: the builder manages
its own subscription to the returned `ValueNotifier` and removes it when
the builder is disposed.

## FAQ

**Do I need to call `dispose()` on a `FancyList` or `FancyMap`?**
No — there is no `dispose()` method, and none is needed. See
[Listener lifecycle](#listener-lifecycle) for the one case that does need
cleanup: a listener registered with `addListener` directly, on a
collection that outlives it.

**Can I use this outside of Flutter, in a plain Dart package?**
No. `getValueNotifier` returns a Flutter `ValueNotifier`, so this package
depends on Flutter. If you only need the add/update/remove notifications
and not the `ValueNotifier` integration, that's still the dependency that's
pulled in.

**Does this replace Provider / Riverpod / Bloc?**
No — it solves a narrower problem: knowing *what* changed inside a list or
map, and where. It composes fine with any of them; for example, expose a
`FancyList` field on a `ChangeNotifier`-based model and call
`notifyListeners()` from a `FancyCollectionValueChangeListener`, or use
`getValueNotifier` directly in a widget without any state-management
library at all.

**Is there a performance cost?**
Every mutation does one path-matching pass per registered listener path,
which is proportional to the number of distinct paths you've subscribed
to, not to the size of the collection. For typical UI-sized collections
(dozens to low hundreds of items) this is not something you'll notice.
Bulk operations (`clear`, `removeWhere`, `sort`, ...) emit a single event
regardless of how many elements they touch, rather than one per element.

**Why does `FancyMap<String, List<int>>()['a'] = [1]` not give me a
`FancyList`?**
Only values whose declared type can hold an observable collection are
converted — see [Nested collections](#nested-collections). `List<int>`
isn't a supertype of `FancyList<dynamic>`, so the plain list is kept as-is
and its own mutations aren't observed. Declare the field as `dynamic`,
`Object?` or `List<dynamic>` if you want it converted.

## Related packages

`fancy_collection` is the foundation of
[fancy_model](https://pub.dev/packages/fancy_model), which generates
observable model classes, and
[fancy_ui](https://pub.dev/packages/fancy_ui), which binds those models to
form widgets. It has no dependency on either and can be used on its own.

## Contributing

Issues and pull requests are welcome at
[github.com/Dualware/fancy_collection](https://github.com/Dualware/fancy_collection/issues).

## Publisher

Maintained by [Dualware Software Service Inc.](https://www.dualware.com).
