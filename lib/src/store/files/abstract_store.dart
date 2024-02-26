
import 'package:form_test/src/store/files/file_update.dart';


abstract class AbstractFilesStore {

  saveSheetFile(String sheetName, var object) ;

  dynamic loadSheetFile(String sheetName)  ;

  saveSheetUpdate(FileUpdate update)  ;

  Future<List<FileUpdate>> loadSheetUpdates()  ;

  removeSheetUpdate()  ;



}
