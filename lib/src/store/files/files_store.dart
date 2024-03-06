
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';

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
  saveSheetFile(String sheetName, var object) async {
    debugPrint("saveFile $sheetName");
    final path = await _localPath;
    File file = File('$path/_SHEET_$sheetName');
    file.writeAsString(jsonEncode(object));
  }

  @override
  dynamic loadSheetFile(String sheetName) async {
    debugPrint("loadFile $sheetName");
    final path = await _localPath;
    File file = File('$path/_SHEET_$sheetName');
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

  @override
  clear() async {
    debugPrint("clear files");

    final path = await _localPath;

    final dir = Directory(path);

    dir.listSync().forEach((e)  {
      String name = basename(e.path);
      if( name.startsWith("_UPDATES") || name.startsWith("_SHEET_")|| name.startsWith("_FILE_")) {e.deleteSync();}
    });


  }

  @override
  Future<Uint8List?> loadFile(String url) async {
    debugPrint("loadFile $url");
    final path = await _localPath;
    File file = File('$path/_FILE_$url');
    if( await file.exists()) {
      Uint8List content = await file.readAsBytes();
    return content;
    } else  {
    return null;
    }
  }

  @override
  saveFile(String url, Uint8List content) async {
    debugPrint("saveFile");

    final path = await _localPath;
    File file = File('$path/_FILE_$url');

    file.writeAsBytes(content);
  }

  @override
  removeFiles() async {

    debugPrint("removeFiles");

    final path = await _localPath;

    final dir = Directory(path);

    dir.listSync().forEach((e)  {
      String name = basename(e.path);
      if( name.startsWith("_FILE_")) {e.deleteSync();}
    });

  }


}
