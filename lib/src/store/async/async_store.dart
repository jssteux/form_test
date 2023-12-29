import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:form_test/logger.dart';
import 'package:form_test/src/parser/parser.dart';
import 'package:form_test/src/store/back/back_store.dart';
import 'package:form_test/src/store/front/form_descriptor.dart';
import 'package:form_test/src/store/front/sheet.dart';

class SheetAsyncCache {

  final DateTime last;
  final List<Map<String, String>> rows;

  SheetAsyncCache(this.last, this.rows) ;
}



class AsyncStore {
  final Logger logger;
  final BackStore backStore;
  final Parser parser;
  final Map<String,SheetAsyncCache> sheetCaches = {};
  MetaDatasCache? metatDatasCaches;

  AsyncStore(this.backStore, this.logger , { this.parser = const Parser()}) { start();}


  Future<SheetAsyncCache> getDatas (String sheetName) async {
    if( sheetCaches[sheetName] == null) {
      DateTime last = await backStore.getSheetInformation();
      await loadDatas(last, sheetName);
    }
    return sheetCaches[sheetName]!;
  }

  loadDatas (DateTime last, String sheetName) async {
    MetaDatas metaDatas = await getMetadatas();
    List<Map<String, String>> datas = await backStore.loadDatas(metaDatas, sheetName);
    sheetCaches[sheetName] = SheetAsyncCache( last, datas);
  }


  Future<MetaDatas> getMetadatas() async {
    if (metatDatasCaches == null) {
      DateTime last = await backStore.getSheetInformation();
      await loadMetadatas(last);
    }
    return metatDatasCaches!.metaDatas;
  }

  loadMetadatas (DateTime last) async {
    //print('load metadats internal');
    List<dynamic> rows = await backStore.getMetadatasDatasRows();


    List<FormDescriptor> forms = parser.parseForms(rows);
    LinkedHashMap<String, SheetDescriptor> sheets =
    parser.parseDescriptors(rows);
    MetaDatas metaDatas =  MetaDatas(sheets, forms);

    //print('return metadats');
    metatDatasCaches = MetaDatasCache(metaDatas, last);
  }




  start() {
    Future.delayed(Duration.zero, refreshTread);
  }


  refreshTread() async {

    while(true) {
      try {
        await Future.delayed(const Duration(seconds: 30));

        DateTime last = await backStore.getSheetInformation();

        bool reloadMetadatas = true;
        if( metatDatasCaches != null) {
          if (last.isAtSameMomentAs(metatDatasCaches!.modifiedTime)) {
            reloadMetadatas = false;
          }
        }
        if (reloadMetadatas) {
          loadMetadatas(last);
        }

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