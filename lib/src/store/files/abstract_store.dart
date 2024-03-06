
import 'dart:typed_data';

import 'package:form_test/src/store/files/file_update.dart';


abstract class AbstractFilesStore {

  saveSheetFile(String sheetName, var object) ;

  dynamic loadSheetFile(String sheetName)  ;

  saveFile(String url, Uint8List content) ;

  Future<Uint8List?> loadFile(String url) ;

  removeFiles();

  saveSheetUpdate(FileUpdate update)  ;

  Future<List<FileUpdate>> loadSheetUpdates()  ;

  removeSheetUpdate()  ;

  clear();

}
