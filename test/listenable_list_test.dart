// import 'dart:io';

import 'package:fancy_collection/fancy_collection_event.dart';
import 'package:fancy_collection/fancy_list.dart';
import 'package:fancy_collection/fancy_collection_value_change_listener.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // String jsonFileContent = "";

  setUp(() {
    // String dir = Directory.current.path;
    // final file = File('$dir/test/test_resources/weather_data.json').readAsStringSync();
    // jsonFileContent = file;
  });

  test('Set size', () {
    FancyList list = FancyList();
    list.length = 10;

    expect(list.length, 10);

    list.add("new element");
    expect(list.length, 11);

    list[10] = "some new value";
    expect(list[10], "some new value");
  });

  test('Shrink size', () {
    FancyList list = FancyList();
    list.add("value");
    list.add("value two");
    list.add("value three");
    list.add("value four");

    list.length = 3;

    expect(list.last, "value three");
  });

  test('Add Listener To List for All the Events', () {
    List attributePathsThatTheEventCalled = [];

    FancyList list = FancyList();
    list.addListener(
      "[*]",
      FancyCollectionValueChangeListener(
        onCollectionEvent: (FancyCollectionEvent event) async {
          attributePathsThatTheEventCalled.add(event.attributePath);
          await Future.delayed(const Duration(milliseconds: 10));
          return;
        },
      ),
    );

    list.add("value");
    list.add("value two");
    list.add("value three");
    list.add("value four");

    expect(attributePathsThatTheEventCalled.length, 4);
  });

  test('Add Listener To List for removing certain items', () {
    List<FancyCollectionEvent> attributePathsThatTheEventCalled = [];

    FancyList list = FancyList();
    list.addListener(
      "[0]",
      FancyCollectionValueChangeListener(
        onCollectionEvent: (FancyCollectionEvent event) async {
          attributePathsThatTheEventCalled.add(event);
          await Future.delayed(const Duration(milliseconds: 10));
          return;
        },
      ),
    );

    list.add("value");
    list.add("value 2");
    list[0] = "new value";

    expect(
      attributePathsThatTheEventCalled[0].type,
      FancyCollectionEventType.add,
    );
    expect(attributePathsThatTheEventCalled[0].value, "value");
    expect(
      attributePathsThatTheEventCalled[1].type,
      FancyCollectionEventType.update,
    );
    expect(attributePathsThatTheEventCalled[1].value, "new value");
  });

  test('Add Listener To List for different items', () {
    List<FancyCollectionEvent> attributePathsThatTheEventCalled = [];

    FancyList list = FancyList();
    list.addListener(
      "[0]",
      FancyCollectionValueChangeListener(
        onCollectionEvent: (FancyCollectionEvent event) async {
          attributePathsThatTheEventCalled.add(event);
          await Future.delayed(const Duration(milliseconds: 10));
          return;
        },
      ),
    );

    list.add("value");
    list.add("value 2");
    list[0] = "new value";

    expect(
      attributePathsThatTheEventCalled[0].type,
      FancyCollectionEventType.add,
    );
    expect(attributePathsThatTheEventCalled[0].value, "value");
    expect(
      attributePathsThatTheEventCalled[1].type,
      FancyCollectionEventType.update,
    );
    expect(attributePathsThatTheEventCalled[1].value, "new value");
  });

  test('Test value notifiers', () {
    List<FancyCollectionEvent> attributePathsThatTheEventCalled = [];

    FancyList list = FancyList();
    ValueNotifier valueNotifier = list.getValueNotifier("[0]");

    valueNotifier.addListener(() {
      attributePathsThatTheEventCalled.add(valueNotifier.value);
    });
    list.add("value");
    list.add("value 2");
    list[0] = "new value";

    expect(
      attributePathsThatTheEventCalled[0].type,
      FancyCollectionEventType.add,
    );
    expect(
      attributePathsThatTheEventCalled[1].type,
      FancyCollectionEventType.update,
    );
  });
}
