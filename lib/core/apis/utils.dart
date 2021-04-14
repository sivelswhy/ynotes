import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ynotes/core/apis/EcoleDirecte.dart';
import 'package:ynotes/core/apis/Pronote.dart';
import 'package:ynotes/core/apis/Pronote/PronoteCas.dart';
import 'package:ynotes/core/offline/offline.dart';
import 'package:ynotes/core/services/shared_preferences.dart';

import 'package:stack/stack.dart' as sta;
import 'package:ynotes/globals.dart';
import 'package:ynotes/usefulMethods.dart';

//Return the good API (will be extended to Pronote)
APIManager(Offline? _offline) {
  //The parser list index corresponding to the user choice
  switch (appSys.settings!["system"]["chosenParser"]) {
    case 0:
      return APIEcoleDirecte(_offline);

    case 1:
      return APIPronote(_offline);
  }
}

setChosenParser(int? chosen) async {
  appSys.updateSetting(appSys.settings!["system"], "chosenParser", chosen);
}

testIfPronoteCas(String url) async {
  //auto forward
  if (url.contains("?")) {
    url += "&fd=1";
  } else {
    url += "?fd=1";
  }
  var response = await http.get(Uri.parse(url));
  printWrapped(response.body);
  if (response.body.contains('id="id_body"')) {
    return false;
  } else {
    return true;
  }
}

getRootAddress(addr) {
  return [
    (addr.split('/').sublist(0, addr.split('/').length - 1).join("/")),
    (addr.split('/').sublist(addr.split('/').length - 1, addr.split('/').length).join("/"))
  ];
}

get_week(DateTime date) async {
  final storage = new FlutterSecureStorage();
  return (1 +
          (date.difference(DateTime.parse(await (storage.read(key: "startday") as Future<String>))).inDays / 7).floor())
      .round();
}

checkPronoteURL(String url) async {
  var response = await http
      .get(Uri.parse(getRootAddress(url)[0] +
          (url[url.length - 1] == "/" ? "" : "/") +
          "InfoMobileApp.json?id=0D264427-EEFC-4810-A9E9-346942A862A4"))
      .catchError((e) {});
  if (response != null && response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}

///Generate lesson ID using, the next scheme : week parity (1 or 2), day of week (1-7) and an hashcode
///composed of the lesson start datetime, the lesson end datetime and the discipline name
Future<int> getLessonID(DateTime start, DateTime end, String disciplineName) async {
  String _disciplineName = "";
  if (disciplineName != null) {
    _disciplineName = disciplineName;
  }
  int parity = ((await get_week(start)).isEven) ? 1 : 2;
  int weekDay = start.weekday;
  TimeOfDay startTimeOfDay = TimeOfDay.fromDateTime(start);
  TimeOfDay endTimeOfDay = TimeOfDay.fromDateTime(end);
  String parsedStartAndEnd = startTimeOfDay.hour.toString() +
      startTimeOfDay.minute.toString() +
      endTimeOfDay.hour.toString() +
      endTimeOfDay.minute.toString();
  int endHash = (parsedStartAndEnd + disciplineName).hashCode;

  int finalID = int.parse(parity.toString() + weekDay.toString() + endHash.toString());

  return finalID;
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

sta.Stack<String> Colorstack = sta.Stack();
List<String> colorList = [
  "#f07aa0",
  "#17d0c9",
  "#a3f7bf",
  "#cecece",
  "#ffa41b",
  "#ff5151",
  "#b967e1",
  "#8a7ca7",
  "#f18867",
  "#ffc0da",
  "#739832",
  "#8ac6d1"
];

void createStack() {
  colorList.forEach((color) {
    Colorstack.push(color);
  });
}

Future<int> getColor(String? disciplineName) async {
  SharedPreferences prefs = await (SharedPreferences.getInstance() as Future<SharedPreferences>);
  if (prefs.containsKey(disciplineName)) {
    String color = prefs.getString(disciplineName)!;
    return HexColor(color).value;
  } else {
    if (Colorstack.isEmpty) {
      createStack();
    }
    await prefs.setString(disciplineName, Colorstack.pop());
    String color = prefs.getString(disciplineName)!;
    return HexColor(color).value;
  }
}
