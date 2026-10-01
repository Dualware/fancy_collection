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

## How path matching works

Event paths join map keys with `.` and wrap list indexes in brackets, e.g.
`orders[2].items[0].price`. A listener path is compared to an event path
segment by segment:

| Listener path | Receives events for                                          |
| ------------- | ------------------------------------------------------------ |
| `*`           | everything                                                   |
| `address`     | `address` and anything below it, e.g. `address.city`         |
| `address.city`| `address.city`, and `address` when the whole map is replaced |
| `items[*]`    | any element of `items`                                       |
| `items[2]`    | `items[2]`, and bulk removals from `items` (reported as `items[*]`) |

## Event fields

| Field           | List events                                      | Map events                     |
| --------------- | ------------------------------------------------ | ------------------------------ |
| `type`          | `add`, `update`, `remove`                        | `add`, `update`, `remove`      |
| `attributePath` | e.g. `[3]`, or `[*]` for bulk removals           | e.g. `address.city`            |
| `index`         | element index, `-1` for bulk removals            | `null`                         |
| `key`           | `null`                                           | entry key                      |
| `value`         | new element, or the removed element on `remove`  | new value, `null` on `remove`  |
| `oldValue`      | `null`                                           | previous value on `update`     |

## Limitations

- Nested maps and lists are stored as `FancyMap<dynamic, dynamic>` /
  `FancyList<dynamic>`. When a `FancyMap` holds maps or lists, declare its
  value type as `dynamic` or `Object?`; a narrower type such as
  `FancyMap<String, Map<String, dynamic>>` throws a `TypeError` on
  assignment.
- `clear()` does not emit events.
- Operations inherited from `ListBase` that shift elements (`insert`,
  `removeAt`, `removeWhere`, `sort`, ...) emit an `update` event for every
  element they move, in addition to the `add` / `remove` event.
- Maps and lists added to a `FancyList` with `add` are stored as-is.
  `FancyList.from` converts them, but changes inside elements of a
  `FancyList` are not propagated to the list's listeners.

## Related packages

`fancy_collection` is the foundation of
[fancy_model](https://pub.dev/packages/fancy_model), which generates
observable model classes, and
[fancy_ui](https://pub.dev/packages/fancy_ui), which binds those models to
form widgets. It has no dependency on either and can be used on its own.

## Contributing

Issues and pull requests are welcome at
[github.com/Dualware/fancy_collection](https://github.com/Dualware/fancy_collection/issues).
