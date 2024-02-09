import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:form_test/src/store/files/abstract_store.dart';
import 'package:form_test/src/store/files/file_update.dart';
import 'package:path_provider/path_provider.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

class FileStore extends AbstractFilesStore {


  @override
  saveSheetFile(String name, var object) async {
    debugPrint("saveFile $name");
    final path = await _localPath;
    File file = File('$path/_SHEET_$name');
    file.writeAsString(jsonEncode(object));
  }

  @override
  dynamic loadSheetFile(String name) async {
    debugPrint("loadFile $name");
    final path = await _localPath;
    File file = File('$path/_SHEET_$name');
    if( await file.exists()) {
      String savedString = await file.readAsString();
      return jsonDecode(savedString);
    } else  {
      return null;
    }
  }

  @override
  saveSheetUpdate(FileUpdate update) async {

    debugPrint("saveUpdate");

    List<FileUpdate> rows = await loadSheetUpdates();
    rows.add(update);

    final path = await _localPath;
    File file = File('$path/_UPDATES');

    file.writeAsString(jsonEncode(rows));
  }

  @override
  Future<List<FileUpdate>> loadSheetUpdates() async {

    debugPrint("loadUpdate");
    final path = await _localPath;
    File file = File('$path/_UPDATES');
    List<dynamic> rows;
    List<FileUpdate> updates=[];
    if( file.existsSync()) {
      String savedString = await file.readAsString();

      rows = jsonDecode(savedString);
      for( var element in rows) {
         FileUpdate update = FileUpdate.fromJson(element);
         updates.add(update);
      }

    } else  {
      updates = [];
    }
    return updates;
  }


  @override
  removeSheetUpdate() async {
    debugPrint("removeUpdate");
    List<FileUpdate> rows = await loadSheetUpdates();
    rows.removeAt(0);

    final path = await _localPath;
    File file = File('$path/_UPDATES');

    file.writeAsString(jsonEncode(rows));
  }



}
