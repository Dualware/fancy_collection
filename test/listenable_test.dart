import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fancy_collection/fancy_map.dart';

void main() {
  String jsonFileContent = "";

  setUp(() {
    String dir = Directory.current.path;
    final file = File('$dir/test/test_resources/weather_data.json').readAsStringSync();
    jsonFileContent = file;
  });

  test('Test initialization of collection', () {
    dynamic jsonMap = jsonDecode(jsonFileContent);
    FancyMap listenableMap = FancyMap.initWithMap(jsonMap);

    expect(listenableMap.length, 6); // There are six objects at the root level

    expect(listenableMap["location"].length, 6); // There are six objects at the "location" key
    expect(listenableMap["location"]["name"], "New York"); // There are six objects at the "location" key
    expect(listenableMap["location"]["lat"], 40.71);
    expect(listenableMap["location"]["localtime"], "2022-07-22 16:49");

    expect(listenableMap["current"].length, 5); // There are five objects at the "current" key
    expect(listenableMap["current"]["condition"].length, 3); // current.condition is a map object
    expect(listenableMap["current"]["condition"]["text"], "Partly cloudy"); // current.condition is a map object

    expect(listenableMap["forecast"]["forecastday"] is List, true); // forecast.forecastday is a list
    expect(
      listenableMap["forecast"]["forecastday"].length,
      1,
      reason: "forecast.forecastday length is 1",
    ); // forecast.forecastday length is 1
    expect(listenableMap["forecast"]["forecastday"][0] is Map, true);
    expect(listenableMap["forecast"]["forecastday"][0]["day"] is Map, true);
    expect(listenableMap["forecast"]["forecastday"][0]["day"]["maxtemp_c"], 35.9);
    expect(listenableMap["forecast"]["forecastday"][0]["hour"] is List, true);
    expect(listenableMap["forecast"]["forecastday"][0]["hour"][0]["condition"] is Map, true);
    expect(listenableMap["forecast"]["forecastday"][0]["hour"][0]["condition"]["text"], "Clear");

    expect(listenableMap["indexes"] is List, true);
    expect(listenableMap["indexes"].length, 4);

    expect(listenableMap["complexIndex"] is List, true);
    expect(listenableMap["complexIndex"][0], "a");
    expect(listenableMap["complexIndex"][2] is Map, true);
    expect(listenableMap["complexIndex"][2]["name"], "c");
  });
}
