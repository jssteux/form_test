
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:form_test/src/store/files/abstract_store.dart';
import 'package:form_test/src/store/files/file_update.dart';



class WebFilesStore extends AbstractFilesStore {
   WebFilesStore();

  final Map<String,String> dataFiles= {};
  final Map<String,Uint8List> files= {};

  @override
  saveSheetFile(String sheetName, var object) async {
    debugPrint("save sheet $sheetName");
    dataFiles["_SHEET_$sheetName"] = jsonEncode(object);
  }

  @override
  dynamic loadSheetFile(String sheetName) async {
    debugPrint("load sheet $sheetName");
    String savedString = dataFiles["_SHEET_$sheetName"]!;
    return jsonDecode(savedString);
  }

  @override
  saveSheetUpdate(FileUpdate update) async {

    debugPrint("saveUpdate");

    List<FileUpdate> rows = await loadSheetUpdates();
    rows.add(update);

    dataFiles["_UPDATES"] = jsonEncode(rows);
  }

  @override
  Future<List<FileUpdate>> loadSheetUpdates() async {

    debugPrint("loadUpdate");

    List<dynamic> rows;
    List<FileUpdate> updates=[];
    if( dataFiles["_UPDATES"] != null) {
      String savedString = dataFiles["_UPDATES"]!;

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


    dataFiles["_UPDATES"] = jsonEncode(rows);
  }

  @override
  clear() {
    dataFiles.clear();
    files.clear();
  }

  @override
  Future<Uint8List?> loadFile(String url) async {
    debugPrint("load file $url");
    return files["_FILE_$url"];
   }

  @override
  saveFile(String url, Uint8List content) async {
    debugPrint("save file $url");
    files["_FILE_$url"] = content;
  }

  @override
  removeFiles() {
    for(String file in files.keys.toList())  {
      if( file.startsWith("_FILE_")) {
        files.remove(file);
      }
    }
  }


}
