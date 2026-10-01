# fancy_collection

Observable `List` and `Map` implementations for Flutter. `FancyList` and
`FancyMap` behave like regular collections, but notify listeners whenever an
entry is added, updated or removed — including changes made deep inside
nested maps and lists.

## Features

- Drop-in `List` / `Map` replacements (`FancyList<T>` extends `ListBase<T>`,
  `FancyMap<K, V>` extends `MapBase<K, V>`).
- Listen to the whole collection or to a specific path such as
  `user.addresses[0].city`, with `*` wildcards.
- Filter listeners by event type: `add`, `update`, `remove` or `all`.
- Nested `Map`s and `List`s are converted automatically and bubble their
  events up to the root.
- `getValueNotifier` exposes any path as a `ValueNotifier` for use with
  `ValueListenableBuilder`.

## Getting started

```sh
flutter pub add fancy_collection
```

```dart
import 'package:fancy_collection/fancy_collection.dart';
```

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

```dart
ValueListenableBuilder<FancyCollectionEvent>(
  valueListenable: todos.getValueNotifier('*'),
  builder: (context, event, _) => Text('${todos.length} todos'),
);
```

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
A malformed path throws an `ArgumentError` when the listener is added.

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

## Related packages

`fancy_collection` is the foundation of
[fancy_model](https://pub.dev/packages/fancy_model), which generates
observable model classes, and
[fancy_ui](https://pub.dev/packages/fancy_ui), which binds those models to
form widgets. It has no dependency on either and can be used on its own.

## Contributing

Issues and pull requests are welcome at
[github.com/Dualware/fancy_collection](https://github.com/Dualware/fancy_collection/issues).
