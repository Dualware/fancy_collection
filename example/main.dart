// ignore_for_file: avoid_print

import 'package:fancy_collection/fancy_collection.dart';

void main() {
  final cart = FancyMap<String, dynamic>();

  cart.addListener(
    '*',
    FancyCollectionValueChangeListener(
      onCollectionEvent:
          (event) =>
              print('${event.type?.name.padRight(6)} ${event.attributePath}'),
    ),
  );

  cart['customer'] = {'name': 'Ada'};
  cart['items'] = <dynamic>[];

  cart.addListener(
    'items[*]',
    FancyCollectionValueChangeListener(
      listensFor: FancyCollectionEventType.add,
      onCollectionEvent: (event) => print('  -> new item: ${event.value}'),
    ),
  );

  final items = cart['items'] as FancyList;
  items.add('Keyboard');
  items.add('Mouse');
  items.removeLast();

  (cart['customer'] as FancyMap)['name'] = 'Grace';
  cart.remove('customer');
}
