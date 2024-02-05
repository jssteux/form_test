import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

class FileStore {
  const FileStore();

  saveSheetFile(String name, var object) async {
    debugPrint("saveFile $name");
    final path = await _localPath;
    File file = File('$path/$name');
    file.writeAsString(jsonEncode(object));
  }

  dynamic loadSheetFile(String name) async {
    debugPrint("loadFile $name");
    final path = await _localPath;
    File file = File('$path/$name');
    String savedString = await file.readAsString();
    return jsonDecode(savedString);
  }

  saveSheetUpdate(String name, var object) async {
    debugPrint("saveFile $name");
    final path = await _localPath;
    File file = File('$path/$name');
    file.writeAsString(jsonEncode(object));
  }

  Future<Map<String, String>> loadSheetUpdate(String path) async {
    File file = File(path);
    String savedString = await file.readAsString();
    Map<String, String> values = <String,String>{};
    Map<String, dynamic> rawMap = jsonDecode(savedString);
    for( String key in rawMap.keys)  {
      values.putIfAbsent(key, () => rawMap[key]);
    }
    return values;
  }

  Future<Iterable<FileSystemEntity>> getSheetUpdates(String name) async {

    final path = await _localPath;
    Directory dir = Directory(path);
    Iterable<FileSystemEntity> files = dir.listSync().where((e) {
      var paths = e.path.split("/");
      if (paths[paths.length - 1].startsWith(name)) {
        return true;
      } else {
        return false;
      }
    });
    return files;
  }

  removeSheetUpdate(String path) {
    File file = File(path);
    file.deleteSync();
  }


}
