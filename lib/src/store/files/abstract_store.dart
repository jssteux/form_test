import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:form_test/src/store/files/file_update.dart';


abstract class AbstractFilesStore {

  saveSheetFile(String name, var object) ;

  dynamic loadSheetFile(String name)  ;

  saveSheetUpdate(FileUpdate update)  ;

  Future<List<FileUpdate>> loadSheetUpdates()  ;

  removeSheetUpdate()  ;



}
