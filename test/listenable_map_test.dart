import 'dart:convert';
import 'dart:io';

import 'package:fancy_collection/fancy_collection_event.dart';
import 'package:fancy_collection/fancy_map.dart';
import 'package:fancy_collection/fancy_collection_value_change_listener.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String jsonFileContent = "";

  setUp(() {
    String dir = Directory.current.path;
    final file =
        File('$dir/test/test_resources/weather_data.json').readAsStringSync();
    jsonFileContent = file;
  });

  test('Add String into listenable_map', () {
    FancyMap map = FancyMap();
    map["key"] = "value";
    expect(map["key"], "value");
  });

  test('Add int into listenable_map', () {
    FancyMap map = FancyMap();
    map["key"] = 12;
    expect(map["key"], 12);
  });

  test('Add Object into listenable_map', () {
    Map something = {"test": "value test"};

    FancyMap map = FancyMap();
    map["key"] = something;
    expect(map["key"]["test"], "value test");
  });

  test('Add nested map into listenable_map', () {
    Map something = {
      "test": {"test": "value test"},
    };

    FancyMap map = FancyMap();
    map["key"] = something;
    expect(map["key"]["test"]["test"], "value test");
  });

  test('Add all', () {
    Map something = {"test": "value test", "number": 12};

    FancyMap map = FancyMap();
    map["name"] = "john";
    map.addAll(something);

    expect(map["name"], "john");
    expect(map["test"], "value test");
    expect(map["number"], 12);
  });

  test('Add entries', () {
    Map something = {"test": "value test", "number": 12};

    FancyMap map = FancyMap();
    map["name"] = "john";

    map.addEntries(something.entries);

    expect(map["name"], "john");
    expect(map["test"], "value test");
    expect(map["number"], 12);
  });

  test('Cast', () {
    FancyMap map = FancyMap();
    map["map"] = {"name": "john"};

    Map<String, Map> newMap = map.cast<String, Map>();

    expect(newMap["map"]?["name"], "john");
  });

  test('Clear', () {
    FancyMap map = FancyMap();
    map["map"] = {"name": "john"};
    expect(map.length, 1);
    map.clear();
    expect(map.length, 0);
  });

  test('Contains Key', () {
    FancyMap map = FancyMap();
    map["name"] = "john";
    map["lastname"] = "doe";
    map["age"] = 43;

    expect(map.containsKey("name"), true);
    expect(map.containsKey("age"), true);
    expect(map.containsKey("address"), false);
  });

  test('Values', () {
    FancyMap map = FancyMap();
    map["name"] = "john";
    map["lastname"] = "doe";
    map["age"] = 43;

    expect(map.values.first, "john");
  });

  test('Contains Value', () {
    FancyMap map = FancyMap();
    map["name"] = "john";
    map["lastname"] = "doe";
    map["age"] = 43;

    expect(map.containsValue("john"), true);
    expect(map.containsValue("doe"), true);
    expect(map.containsValue("Toronto"), false);
  });

  test('For each', () {
    FancyMap map = FancyMap();
    map["name"] = "john";
    map["lastname"] = "doe";
    map["age"] = 43;

    FancyMap mapTwo = FancyMap();
    map.forEach((key, value) {
      mapTwo[key] = value;
    });

    expect(mapTwo["name"], "john");
    expect(mapTwo["lastname"], "doe");
    expect(mapTwo["age"], 43);
  });

  test('Is Empty', () {
    FancyMap map = FancyMap();
    map["name"] = "john";
    map["lastname"] = "doe";
    map["age"] = 43;

    expect(map.isEmpty, false);
  });

  test('Is Not Empty', () {
    FancyMap map = FancyMap();
    map["name"] = "john";
    map["lastname"] = "doe";
    map["age"] = 43;

    expect(map.isNotEmpty, true);
  });

  test('Keys', () {
    FancyMap map = FancyMap();
    map["name"] = "john";
    map["lastname"] = "doe";
    map["age"] = 43;

    expect(map.keys.contains("name"), true);
    expect(map.keys.contains("lastname"), true);
    expect(map.keys.contains("age"), true);
    expect(map.keys.contains("address"), false);
  });

  test('Length', () {
    FancyMap map = FancyMap();
    map["name"] = "john";
    map["lastname"] = "doe";
    map["age"] = 43;

    expect(map.length, 3);
  });

  test('Map', () {
    FancyMap<String, int> map = FancyMap();
    map["1"] = 1;
    map["2"] = 2;
    map["3"] = 3;

    Map mapTwo = map.map((key, value) {
      return MapEntry(key, value * 2);
    });

    expect(mapTwo["1"], 2);
    expect(mapTwo["2"], 4);
    expect(mapTwo["3"], 6);
  });

  test('PutIfAbsent', () {
    FancyMap<String, String> map = FancyMap();
    map["name"] = "john";

    expect(map.putIfAbsent("name", () => "jane"), "john");
    expect(map.putIfAbsent("lastname", () => "doe"), "doe");
  });

  test('Remove', () {
    FancyMap<String, int> map = FancyMap();
    map["1"] = 1;
    map["2"] = 2;
    map["3"] = 3;

    map.remove("1");

    expect(map.length, 2);
    expect(map.containsKey("1"), false);
    expect(map.containsKey("2"), true);
    expect(map.containsKey("3"), true);
  });

  test('Remove Where', () {
    FancyMap<String, int> map = FancyMap();
    map["1"] = 1;
    map["2"] = 2;
    map["3"] = 3;

    map.removeWhere((key, value) => value == 1);

    expect(map.length, 2);
    expect(map.containsKey("1"), false);
    expect(map.containsKey("2"), true);
    expect(map.containsKey("3"), true);
  });

  test('Update', () {
    FancyMap<String, int> map = FancyMap();
    map["1"] = 1;
    map["2"] = 2;
    map["3"] = 3;

    map.update("1", (value) => value * 3);

    expect(map["1"], 3);
    expect(map["2"], 2);
    expect(map["3"], 3);

    map.update("5", (value) => value * 3, ifAbsent: () => 6);
    expect(map.containsKey("5"), true);
    expect(map["5"], 6);

    // fail test if argment error is not thrown for non existing keys
    try {
      map.update("4", (value) => value * 3);
    } catch (e2) {
      if (e2 is! ArgumentError) {
        rethrow;
      }
    }
  });

  test('Update All', () {
    FancyMap<String, int> map = FancyMap();
    map["1"] = 1;
    map["2"] = 2;
    map["3"] = 3;

    map.updateAll((key, value) => value * 2);

    expect(map["1"], 2);
    expect(map["2"], 4);
    expect(map["3"], 6);
  });

  test('Add Listener To everything', () {
    dynamic jsonMap = jsonDecode(jsonFileContent);
    FancyMap listenableMap = FancyMap.initWithMap(jsonMap);

    List attributePathsThatTheEventCalled = [];

    FancyCollectionValueChangeListener listener =
        FancyCollectionValueChangeListener(
          listensFor: FancyCollectionEventType.update,
          onCollectionEvent: (FancyCollectionEvent event) async {
            attributePathsThatTheEventCalled.add(event.attributePath);

            await Future.delayed(const Duration(milliseconds: 10));
            return;
          },
        );

    listenableMap.addListener("*", listener);
    listenableMap["location"]["name"] = "Chicago";
    listenableMap["current"]["last_updated_epoch"] = "Chicago";
    listenableMap["location"]["city"] =
        "Istanbul"; // This line shouldn't be triggering any event as listener ignores 'add' events.

    expect(attributePathsThatTheEventCalled.length, 2);
    expect(attributePathsThatTheEventCalled[0], "location.name");
    expect(attributePathsThatTheEventCalled[1], "current.last_updated_epoch");

    expect(listenableMap["location"]["name"], "Chicago");
    expect(listenableMap["location"]["city"], "Istanbul");
  });

  test('Add Listener To everything', () {
    dynamic jsonMap = jsonDecode(jsonFileContent);
    FancyMap listenableMap = FancyMap.initWithMap(jsonMap);

    List attributePathsThatTheEventCalled = [];

    FancyCollectionValueChangeListener listener =
        FancyCollectionValueChangeListener(
          onCollectionEvent: (FancyCollectionEvent event) async {
            attributePathsThatTheEventCalled.add(event.attributePath);

            await Future.delayed(const Duration(milliseconds: 10));
            return;
          },
        );

    listenableMap.addListener("*", listener);
    listenableMap["location"]["name"] = "Chicago";
    listenableMap["current"]["last_updated_epoch"] = "Chicago";
    listenableMap["location"]["city"] =
        "Istanbul"; // This line shouldn't be triggering any event as listener ignores 'add' events.

    expect(attributePathsThatTheEventCalled.length, 3);
    expect(attributePathsThatTheEventCalled[0], "location.name");
    expect(attributePathsThatTheEventCalled[1], "current.last_updated_epoch");
    expect(attributePathsThatTheEventCalled[2], "location.city");

    expect(listenableMap["location"]["name"], "Chicago");
    expect(listenableMap["location"]["city"], "Istanbul");
  });

  test('Add Listeners for Add event', () {
    dynamic jsonMap = jsonDecode(jsonFileContent);
    FancyMap listenableMap = FancyMap.initWithMap(jsonMap);

    List attributesAdded = [];

    FancyCollectionValueChangeListener addListener =
        FancyCollectionValueChangeListener(
          listensFor: FancyCollectionEventType.add,
          onCollectionEvent: (FancyCollectionEvent event) async {
            attributesAdded.add(event.attributePath);

            await Future.delayed(const Duration(milliseconds: 10));
            return;
          },
        );

    listenableMap.addListener("*", addListener);

    listenableMap["location"]["name"] = "Chicago"; // Update
    listenableMap["current"]["last_updated_epoch"] = "Chicago"; //Update
    listenableMap["location"]["city"] = "Istanbul"; // Add
    listenableMap.remove("alerts");

    expect(attributesAdded.length, 1);
    expect(attributesAdded[0], "location.city");
  });

  test('Add Multiple Listeners for Specific Event Types', () {
    dynamic jsonMap = jsonDecode(jsonFileContent);
    FancyMap listenableMap = FancyMap.initWithMap(jsonMap);

    List attributesAdded = [];
    List attributesRemoved = [];
    List attributesUpdated = [];

    FancyCollectionValueChangeListener addListener =
        FancyCollectionValueChangeListener(
          listensFor: FancyCollectionEventType.add,
          onCollectionEvent: (FancyCollectionEvent event) async {
            attributesAdded.add(event.attributePath);

            await Future.delayed(const Duration(milliseconds: 10));
            return;
          },
        );

    FancyCollectionValueChangeListener removeListener =
        FancyCollectionValueChangeListener(
          listensFor: FancyCollectionEventType.remove,
          onCollectionEvent: (FancyCollectionEvent event) async {
            attributesRemoved.add(event.attributePath);
            await Future.delayed(const Duration(milliseconds: 10));
            return;
          },
        );

    FancyCollectionValueChangeListener updateListener =
        FancyCollectionValueChangeListener(
          listensFor: FancyCollectionEventType.update,
          onCollectionEvent: (FancyCollectionEvent event) async {
            attributesUpdated.add(event.attributePath);
            await Future.delayed(const Duration(milliseconds: 10));
            return;
          },
        );

    listenableMap.addListener("*", addListener);
    listenableMap.addListener("*", removeListener);
    listenableMap.addListener("*", updateListener);

    listenableMap["location"]["name"] = "Chicago"; // Update
    listenableMap["current"]["last_updated_epoch"] = "Chicago"; //Update
    listenableMap["location"]["city"] = "Istanbul"; // Add
    listenableMap.remove("alerts");

    expect(attributesUpdated.length, 2);
    expect(attributesUpdated[0], "location.name");
    expect(attributesUpdated[1], "current.last_updated_epoch");

    expect(attributesAdded.length, 1);
    expect(attributesAdded[0], "location.city");

    expect(attributesRemoved.length, 1);
    expect(attributesRemoved[0], "alerts");
  });

  test('Add Listener To Nested Map', () {
    dynamic jsonMap = jsonDecode(jsonFileContent);
    FancyMap listenableMap = FancyMap.initWithMap(jsonMap);

    List attributePathsThatTheEventCalled = [];

    FancyCollectionValueChangeListener listener =
        FancyCollectionValueChangeListener(
          listensFor: FancyCollectionEventType.update,
          onCollectionEvent: (FancyCollectionEvent event) async {
            attributePathsThatTheEventCalled.add(event.attributePath);

            await Future.delayed(const Duration(milliseconds: 10));
            return;
          },
        );

    listenableMap.addListener("current.*", listener);
    listenableMap["location"]["name"] = "Chicago";
    listenableMap["current"]["last_updated_epoch"] = "Chicago";
    listenableMap["location"]["city"] = "Istanbul";

    expect(attributePathsThatTheEventCalled.length, 1);
    expect(attributePathsThatTheEventCalled[0], "current.last_updated_epoch");

    expect(listenableMap["location"]["name"], "Chicago");
    expect(listenableMap["location"]["city"], "Istanbul");
  });

  test('Add Listener To Map For All the Event Types', () {
    dynamic jsonMap = jsonDecode(jsonFileContent);
    FancyMap listenableMap = FancyMap.initWithMap(jsonMap);

    List attributePathsThatTheEventCalled = [];

    FancyCollectionValueChangeListener listener =
        FancyCollectionValueChangeListener(
          listensFor: FancyCollectionEventType.update,
          onCollectionEvent: (FancyCollectionEvent event) async {
            attributePathsThatTheEventCalled.add(event.attributePath);

            await Future.delayed(const Duration(milliseconds: 10));
            return;
          },
        );

    listenableMap.addListener("location.name", listener);
    listenableMap["location"]["name"] = "Chicago";

    expect(attributePathsThatTheEventCalled.length, 1);
    expect(attributePathsThatTheEventCalled[0], "location.name");
    expect(listenableMap["location"]["name"], "Chicago");
  });

  test('Add Listener To Map', () {
    dynamic jsonMap = jsonDecode(jsonFileContent);
    FancyMap listenableMap = FancyMap.initWithMap(jsonMap);

    List attributePathsThatTheEventCalled = [];

    FancyCollectionValueChangeListener listener =
        FancyCollectionValueChangeListener(
          listensFor: FancyCollectionEventType.update,
          onCollectionEvent: (FancyCollectionEvent event) async {
            attributePathsThatTheEventCalled.add(event.attributePath);

            await Future.delayed(const Duration(milliseconds: 10));
            return;
          },
        );

    listenableMap.addListener("location.*", listener);
    listenableMap["location"]["name"] = "Chicago";

    expect(attributePathsThatTheEventCalled.length, 1);
    expect(attributePathsThatTheEventCalled[0], "location.name");
    expect(listenableMap["location"]["name"], "Chicago");
  });

  test('Remove Listener To Map', () {
    dynamic jsonMap = jsonDecode(jsonFileContent);
    FancyMap listenableMap = FancyMap.initWithMap(jsonMap);

    List attributePathsThatTheEventCalled = [];

    FancyCollectionValueChangeListener listener =
        FancyCollectionValueChangeListener(
          listensFor: FancyCollectionEventType.update,
          onCollectionEvent: (FancyCollectionEvent event) async {
            attributePathsThatTheEventCalled.add(event.attributePath);

            await Future.delayed(const Duration(milliseconds: 10));
            return;
          },
        );

    listenableMap.addListener("location.*", listener);
    listenableMap["location"]["name"] = "Chicago";

    expect(attributePathsThatTheEventCalled.length, 1);
    expect(attributePathsThatTheEventCalled[0], "location.name");
    expect(listenableMap["location"]["name"], "Chicago");
  });

  // test('Add listener to map', () {
  //   dynamic jsonMap = jsonDecode(jsonFileContent);
  //   ListenableMap listenableMap = ListenableMap.initWithMap(jsonMap);

  //   int testValue = 0;
  //   ListenableValueChangeListener listener = ListenableValueChangeListener(
  //     onValueChanged: () async {
  //       testValue++;
  //       await Future.delayed(const Duration(milliseconds: 10));

  //       return;
  //     },
  //   );

  //   listenableMap.addListener("location", listener);
  //   listenableMap["location"]["name"] = "Chicago";
  //   listenableMap["location"]["lat"] = 40.71;

  //   expect(testValue, 2);
  // });

  // test('Add listener to map attribute', () {
  //   dynamic jsonMap = jsonDecode(jsonFileContent);
  //   ListenableMap listenableMap = ListenableMap.initWithMap(jsonMap);

  //   int testValue = 0;
  //   ListenableValueChangeListener listener = ListenableValueChangeListener(
  //     onValueChanged: () async {
  //       testValue++;
  //       await Future.delayed(const Duration(milliseconds: 10));

  //       return;
  //     },
  //   );

  //   listenableMap.addListener("location.name", listener);
  //   listenableMap["location"]["name"] = "Chicago";
  //   listenableMap["location"]["lat"] = 40.71;

  //   expect(testValue, 1); // Listener must be called only for name
  // });
}
