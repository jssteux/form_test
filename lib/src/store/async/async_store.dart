import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:form_test/logger.dart';
import 'package:form_test/src/parser/parser.dart';
import 'package:form_test/src/store/back/back_store.dart';
import 'package:form_test/src/store/files/files_store.dart';
import 'package:form_test/src/store/front/form_descriptor.dart';
import 'package:form_test/src/store/front/sheet.dart';


class SheetAsyncCache {

  final DateTime? last;
  final List<Map<String, String>> rows;

  SheetAsyncCache(this.last, this.rows) ;
}

class MediaCache {

  final Uint8List datas;

  MediaCache(this.datas) ;
}


class AsyncStore {
  final Logger logger;
  BackStore? backStore;
  final Parser parser;
  final FileStore filesStore;
  final Map<String,SheetAsyncCache> sheetCaches = {};
  final Map<String,MediaCache> mediaCaches = {};
  MetaDatasCache? metatDatasCaches;

  bool continueThread = true;

  AsyncStore(this.backStore, this.logger , { this.parser = const Parser(), this.filesStore = const FileStore()}) { start();}


  Future<SheetAsyncCache> getDatas (String sheetName) async {
    while( sheetCaches[sheetName] == null) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return sheetCaches[sheetName]!;
  }


  Future<MetaDatas> getMetadatas() async {
    while (metatDatasCaches == null) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return metatDatasCaches!.metaDatas;
  }


  Future<Uint8List?> getMedia(String url) async  {
    if( mediaCaches[url] == null) {
      var datas = await backStore!.readMedia(url);
      if( datas != null) {
        MediaCache mediaCache = MediaCache(datas !);
        mediaCaches[url] = mediaCache;
      }
    }

    if( mediaCaches[url] != null) {
      return mediaCaches[url]!.datas;
    } else {
      return null;
    }

  }

  loadDatas (DateTime? last, String sheetName) async {
   // debugPrint( "async loadDatas $sheetName" );
    MetaDatas metaDatas = await getMetadatas();


    List<dynamic> rows;
    if( backStore != null) {
      rows = await backStore!.loadDatas(metaDatas, sheetName);
      await filesStore.saveSheetFile("SHEET_$sheetName", rows);
    } else {
      rows = (await filesStore.loadSheetFile("SHEET_$sheetName")) as List;
    }



    // Transform datas
    List<Map<String, String>> res = [];
    var cols = metaDatas.sheetDescriptors[sheetName]!.columns;


    for (int i = 0; i < rows.length; i++) {
      Map<String, String> rowMap = {};
      List<dynamic> rowCells = rows.elementAt(i);
      for (int j = 0; j < cols.length; j++) {
        var value = "";
        if (j < rowCells.length) {
          value = rowCells.elementAt(j);
        }
        rowMap.putIfAbsent(cols.keys.elementAt(j), () => value);
      }

      res.add(rowMap);
    }


    sheetCaches[sheetName] = SheetAsyncCache(last, res);


  }




  loadMetadatas (DateTime? last) async {
    //print('load metadats internal');
    List<dynamic> rows;
    if( backStore != null) {
      rows = await backStore!.getMetadatasDatasRows();
      await filesStore.saveSheetFile("META_DATAS", rows);
    } else {
      rows = (await filesStore.loadSheetFile("META_DATAS")) as List;
    }

    List<FormDescriptor> forms = parser.parseForms(rows);
    LinkedHashMap<String, SheetDescriptor> sheets =
    parser.parseDescriptors(rows);
    MetaDatas metaDatas =  MetaDatas(sheets, forms);

    //print('return metadats');
    metatDatasCaches = MetaDatasCache(metaDatas, last);

  }




  start() {
    debugPrint( "start" );
    Future.delayed(Duration.zero, refreshTread);
  }


  refreshTread() async {

    while(continueThread == true) {



      try {


        DateTime? last;
        if( backStore != null) {

          int nbTries = 0;
          while((backStore!.spreadSheet == null && nbTries < 5)) {
             await Future.delayed(const Duration(seconds: 1));
          }

          last = await backStore!.getSheetInformation();
        }


        bool reloadMetadatas = true;
        if( metatDatasCaches != null) {

          if( backStore == null)  {
            reloadMetadatas = false;
          } else  {
            if (last != null && metatDatasCaches!.modifiedTime!= null && last.isAtSameMomentAs(metatDatasCaches!.modifiedTime!)) {
              reloadMetadatas = false;
            }
          }

        }
        if (reloadMetadatas) {
          await loadMetadatas(last);
        }



        if( metatDatasCaches != null) {
          for (String sheetName in metatDatasCaches!.metaDatas.sheetDescriptors
              .keys) {
            bool reloadSheet = true;
            var cache = sheetCaches[ sheetName];
            if (cache != null) {
              if (backStore == null) {
                reloadSheet = false;
              } else {
                if (cache!.last != null && last != null &&
                    last.isAtSameMomentAs(cache!.last!)) {
                  reloadSheet = false;
                }
              }
            }


            if (reloadSheet == true) {
              await loadDatas(last, sheetName);
            }
          }
        }



      } catch(e)  {
       // if( connection) {
          debugPrint("AsyncStore ERROR $e");
       // }
      }

        await Future.delayed(const Duration(seconds: 30));

    }
  }

  stop() {
    debugPrint( "stop" );
    continueThread = false;
  }

}