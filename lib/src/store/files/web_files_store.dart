
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:form_test/src/store/files/abstract_store.dart';
import 'package:form_test/src/store/files/file_update.dart';



class WebFilesStore extends AbstractFilesStore {
   WebFilesStore();

  final Map<String,String> files= {};

  @override
  saveSheetFile(String sheetName, var object) async {
    debugPrint("save sheet $sheetName");
    files["_SHEET_$sheetName"] = jsonEncode(object);
  }

  @override
  dynamic loadSheetFile(String sheetName) async {
    debugPrint("load sheet $sheetName");
    String savedString = files["_SHEET_$sheetName"]!;
    return jsonDecode(savedString);
  }

  @override
  saveSheetUpdate(FileUpdate update) async {

    debugPrint("saveUpdate");

    List<FileUpdate> rows = await loadSheetUpdates();
    rows.add(update);

    files["_UPDATES"] = jsonEncode(rows);
  }

  @override
  Future<List<FileUpdate>> loadSheetUpdates() async {

    debugPrint("loadUpdate");

    List<dynamic> rows;
    List<FileUpdate> updates=[];
    if( files["_UPDATES"] != null) {
      String savedString = files["_UPDATES"]!;

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


    files["_UPDATES"] = jsonEncode(rows);
  }


}
