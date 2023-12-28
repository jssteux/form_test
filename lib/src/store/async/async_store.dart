import 'package:flutter/cupertino.dart';
import 'package:form_test/logger.dart';
import 'package:form_test/src/store/back/back_store.dart';

class SheetAsyncCache {

  final DateTime last;
  final List<Map<String, String>> rows;

  SheetAsyncCache(this.last, this.rows) ;
}



class AsyncStore {
  final Logger logger;
  final BackStore backStore;
  final Map<String,SheetAsyncCache> sheetCaches = {};


  AsyncStore(this.backStore, this.logger) { start();}


  Future<SheetAsyncCache> getDatas (String sheetName) async {
    if( sheetCaches[sheetName] == null) {
      DateTime last = await backStore.getSheetInformation();
      await loadDatas(last, sheetName);
    }
    return sheetCaches[sheetName]!;
  }

  loadDatas (DateTime last, String sheetName) async {
    List<Map<String, String>> datas = await backStore.loadDatas(sheetName);
    sheetCaches[sheetName] = SheetAsyncCache( last, datas);
  }


  start() {
    Future.delayed(Duration.zero, refreshTread);
  }


  refreshTread() async {

    while(true) {
      try {
        await Future.delayed(const Duration(seconds: 30));

        DateTime last = await backStore.getSheetInformation();

        for (String sheetName in sheetCaches.keys) {
          bool reloadSheet = true;
          var cache = sheetCaches[ sheetName];
          if (last.isAtSameMomentAs(cache!.last)) {
            reloadSheet = false;
          }

          if (reloadSheet) {
            loadDatas(last, sheetName);
          }
        }


      } catch(e)  {
        debugPrint( "AsyncStore ERROR $e" );

      }
    }
  }

}