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

  saveSheetFile( String name, var object) async {
    debugPrint( "saveFile $name" );
    final path = await _localPath;
    File file = File('$path/$name');
    file.writeAsString(jsonEncode(object));
  }

  dynamic loadSheetFile( String name) async {
    debugPrint( "loadFile $name" );
    final path = await _localPath;
    File file = File('$path/$name');
    String savedString = await file.readAsString();
    return jsonDecode(savedString);
  }



}