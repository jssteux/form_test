import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:form_test/column_descriptor.dart';
import 'package:form_test/logger.dart';
import 'package:form_test/src/parser/parser.dart';
import 'package:form_test/src/store/back/back_store.dart';
import 'package:form_test/src/store/back/back_store_api.dart';
import 'package:form_test/src/store/files/abstract_store.dart';
import 'package:form_test/src/store/files/file_update.dart';
import 'package:form_test/src/store/files/files_store.dart';
import 'package:form_test/src/store/files/web_files_store.dart';
import 'package:form_test/src/store/front/form_descriptor.dart';
import 'package:form_test/src/store/front/sheet.dart';

class SheetAsyncCache {
  final DateTime? last;
  final List<Map<String, String>> rows;

  SheetAsyncCache(this.last, this.rows);
}

class MediaCache {
  final Uint8List datas;

  MediaCache(this.datas);
}

class AsyncStore {
  final Logger logger;
  BackStore? backStore;
  final Parser parser;
  late final AbstractFilesStore filesStore;
  final Map<String, SheetAsyncCache> sheetCaches = {};
  final Map<String, MediaCache> mediaCaches = {};
  MetaDatasCache? metatDatasCaches;

  bool continueThread = true;

  AsyncStore(this.backStore, this.logger, {this.parser = const Parser()}) {
    filesStore = (!kIsWeb) ? FileStore() : WebFilesStore();
    start();
  }

  Future<SheetAsyncCache> getDatas(String sheetName) async {
    while (sheetCaches[sheetName] == null) {
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

  Future<Uint8List?> getMedia(String url) async {
    if (mediaCaches[url] == null) {
      var datas = await backStore!.readMedia(url);
      if (datas != null) {
        MediaCache mediaCache = MediaCache(datas);
        mediaCaches[url] = mediaCache;
      }
    }

    if (mediaCaches[url] != null) {
      return mediaCaches[url]!.datas;
    } else {
      return null;
    }
  }

  /* Reload datas (without applying updates) */
  Future<List<Map<String, String>>> getLastSheetData(MetaDatas metaDatas, String sheetName, bool forceUpdate) async {

    MetaDatas metaDatas = await getMetadatas();
    List<dynamic>? rows;

    bool reload = true;
    if( forceUpdate == false)  {
      if ((await filesStore.loadSheetFile(sheetName)) != null)  {
        reload = false;
      }
    }

    if (backStore != null && reload) {
      rows = await backStore!.loadDatas(metaDatas, sheetName);
      await filesStore.saveSheetFile(sheetName, rows);
    } else {
      rows = (await filesStore.loadSheetFile(sheetName)) as List;
    }

      return transformSheetRowsToMap(rows, metaDatas, sheetName);
  }



  List<Map<String, String>> transformSheetRowsToMap(
      List<dynamic> rows, MetaDatas metaDatas, String sheetName) {
    // Transform datas to map
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

    return res;
  }

  /* Reload datas (applying updates) */



  loadDatas(DateTime? last, String sheetName, bool forceReload) async {


    debugPrint("loadDatas  $sheetName forceReload $forceReload");

    MetaDatas metaDatas = await getMetadatas();

    var sheetDescriptor = metaDatas.sheetDescriptors[sheetName]!;

    List<Map<String, String>> res = await getLastSheetData(metaDatas,sheetName, forceReload);

    // Add updates

    debugPrint("loadDatas  $sheetName beforeUpdate");

    List<FileUpdate> updates = await filesStore.loadSheetUpdates();
    for (var update in updates) {

      if (update.action == "modify") {
        if (update.sheetName == sheetName) {
          for (Map<String, String> initialValues in res) {
            String? initialKey = initialValues[sheetDescriptor.primaryKey];
            String? updateKey = update.datas[sheetDescriptor.primaryKey];
            if (initialKey != null &&
                updateKey != null &&
                initialKey == updateKey) {
              for (var copyKey in update.datas.keys) {
                initialValues.update(
                    copyKey, (value) => update.datas[copyKey]!);
              }
            }
          }
        }
      }

      if (update.action == "create") {
        if (update.sheetName == sheetName) {
          res.add(update.datas);
        }
      }

     if (update.action == "removeFromCache") {
       if (update.sheetName == sheetName) {
         res.removeWhere((element) =>
          element[sheetDescriptor.primaryKey] == update.datas[sheetDescriptor.primaryKey]);
       }
      }
    }

    debugPrint("loadDatas  $sheetName after Update");

 //   if(  sheetName == "CLIENT")  {

    if( sheetName == "PURCHASE" )  {
      debugPrint("**********loadData internal return $sheetName ***************");
      for( var line in res) {
          debugPrint("------------");
          for(String key in line.keys)  {
            String? value = line[ key];
            debugPrint( '$key = $value');
          }
      }

    }

   sheetCaches[sheetName] = SheetAsyncCache(last, res);
   return res;
  }

  loadMetadatas(DateTime? last) async {
    //print('load metadats internal');
    List<dynamic> rows;
    if (backStore != null) {
      rows = await backStore!.getMetadatasDatasRows();
      await filesStore.saveSheetFile("META_DATAS", rows);
    } else {
      rows = (await filesStore.loadSheetFile("META_DATAS")) as List;
    }

    List<FormDescriptor> forms = parser.parseForms(rows);
    LinkedHashMap<String, SheetDescriptor> sheets =
        parser.parseDescriptors(rows);
    MetaDatas metaDatas = MetaDatas(sheets, forms);

    //print('return metadats');
    metatDatasCaches = MetaDatasCache(metaDatas, last);
  }

  modifyDatas(String sheetName, Map<String, String> formValues) async {
    await filesStore
        .saveSheetUpdate(FileUpdate("modify", sheetName, formValues));

    // Update caches
    await loadDatas(null, sheetName, false);
  }

  createDatas(String sheetName, Map<String, String> formValues) async {

    SheetDescriptor desc =  metatDatasCaches!.metaDatas.sheetDescriptors[sheetName]!;

    String primaryKey = desc.primaryKey;


    if( formValues[primaryKey] == null || formValues[primaryKey] == "") {
      var ts = DateTime.now().millisecondsSinceEpoch;
      formValues[primaryKey] = ts.toString();
    }
    await filesStore
        .saveSheetUpdate(FileUpdate("create", sheetName, formValues));

    // Update caches
    await loadDatas(null, sheetName, false);
  }

  prepareCascadeRemove(List<ItemToRemove> items, MetaDatas metaDatas,
      String sheetName, String id, bool cache) async {


    debugPrint("prepareCascadeRemove $sheetName $id");


    List<Map<String, String>> datas;
    // Refresh datas

    if( cache) {
      datas = await loadDatas(null, sheetName, false);
    } else {
      List<dynamic> rows = await backStore!.loadDatas(metaDatas, sheetName);
      datas = transformSheetRowsToMap(rows, metaDatas, sheetName);
    }

    // Search current item
    String primaryKey = metaDatas.sheetDescriptors[sheetName]!.primaryKey;

    var index = -1;

    for (int i = 0; i < datas.length; i++) {
      if (datas.elementAt(i)[metaDatas.sheetDescriptors[sheetName]!.primaryKey] == id) {
        index = i;
      }
    }

    debugPrint("prepareCascadeRemove $sheetName index=$index");

    if (index != -1) {
      int indexRemove = index + 1;

      var item = ItemToRemove(sheetName, datas.elementAt(index)[primaryKey]!,
          indexRemove, indexRemove + 1);

      items.add(item);

      // get references
      for (String childSheet in metaDatas.sheetDescriptors.keys) {
        String childPrimaryKey = metaDatas.sheetDescriptors[childSheet]!.primaryKey;
        if (childSheet != sheetName) {
          var columns = metaDatas.sheetDescriptors[childSheet]!.columns;
          for (ColumnDescriptor desc in columns.values) {
            if (desc.reference == sheetName && desc.cascadeDelete) {
              List<Map<String, String>> childDatas;
              if( cache) {
                childDatas = await loadDatas(null, childSheet, false);
              } else {
                List<dynamic> rows = await backStore!.loadDatas(metaDatas, childSheet);
                childDatas = transformSheetRowsToMap(rows, metaDatas, childSheet);
              }

              for (int i = 0; i < childDatas.length; i++) {
                String? idRef= childDatas[i][ desc.name];
                if( idRef != null && idRef == id) {
                  String? childId = childDatas[i][childPrimaryKey];
                  if (childId != null ) {

                    debugPrint("prepareCascadeRemove call child sheet $childSheet");

                    await prepareCascadeRemove(
                        items, metaDatas, childSheet, childId, cache);
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  removeData(String sheetName, String id) async {
    //test();

    if( metatDatasCaches!.metaDatas.sheetDescriptors[sheetName] != null)  {

    String primaryKey = metatDatasCaches!.metaDatas.sheetDescriptors[sheetName]!.primaryKey;

    debugPrint("----- removeData $sheetName $id");

    Map<String, String> formValues = {};
    formValues[primaryKey] = id;
    await filesStore
        .saveSheetUpdate(FileUpdate("remove", sheetName, formValues));



      List<ItemToRemove> removedItems = [];

      await prepareCascadeRemove(
          removedItems, metatDatasCaches!.metaDatas, sheetName,
          id, true);

      for (var itemToRemove in removedItems) {
        Map<String, String> formValues = {};
        formValues[primaryKey] = itemToRemove.id;
        debugPrint("add removeFromCache ${itemToRemove
            .sheetName} ${formValues[primaryKey]}");
        await filesStore
            .saveSheetUpdate(
            FileUpdate("removeFromCache", itemToRemove.sheetName, formValues));
      }


    }



    MetaDatas metaDatas = await getMetadatas();
    for(String sheetName in metaDatas.sheetDescriptors.keys) {
      // Update caches
      await loadDatas(null, sheetName, false);
    }

    /*
    if( backStore != null) {
      await backStore!.removeData(items);
    }

     */
  }

  start() {
    debugPrint("start");
    Future.delayed(Duration.zero, refreshTread);
  }

  refreshTread() async {

    while (continueThread == true) {
      try {
        DateTime? last;
        if (backStore != null) {
          int nbTries = 0;
          while ((backStore!.spreadSheet == null && nbTries < 5)) {
            await Future.delayed(const Duration(seconds: 1));
          }

          last = await backStore!.getSheetInformation();
        }

        bool reloadMetadatas = true;
        if (metatDatasCaches != null) {
          if (backStore == null) {
            reloadMetadatas = false;
          } else {
            if (last != null &&
                metatDatasCaches!.modifiedTime != null &&
                last.isAtSameMomentAs(metatDatasCaches!.modifiedTime!)) {
              reloadMetadatas = false;
            }
          }
        }
        if (reloadMetadatas) {
          await loadMetadatas(last);
        }

        if (metatDatasCaches != null) {
          for (String sheetName
              in metatDatasCaches!.metaDatas.sheetDescriptors.keys) {
            bool reloadSheet = true;
            var cache = sheetCaches[sheetName];
            if (cache != null) {
              if (backStore == null) {
                reloadSheet = false;
              } else {
                if (cache.last != null &&
                    last != null &&
                    last.isAtSameMomentAs(cache.last!)) {
                  reloadSheet = false;
                }
              }
            }

            if (reloadSheet == true) {
              await loadDatas(last, sheetName, true);
            }
          }
        }

        // UPDATES

        if (backStore != null) {

         debugPrint("apply updates");

          for( FileUpdate update in await filesStore.loadSheetUpdates()) {
            Set<String> sheetsToReload={};

            if( update.action == "modify") {

              await backStore!.saveData(
                  metatDatasCaches!.metaDatas, update.sheetName, update.datas);
              sheetsToReload.add(update.sheetName);
            }

            if( update.action == "create") {
             await backStore!.saveData(
                 metatDatasCaches!.metaDatas, update.sheetName, update.datas);
             sheetsToReload.add(update.sheetName);
            }

            if( update.action == "remove") {
              String? id = update.datas[metatDatasCaches!.metaDatas.sheetDescriptors[update.sheetName]!.primaryKey];
              if (id != null) {
                List<ItemToRemove> removedItems = [];
                await prepareCascadeRemove(
                    removedItems, metatDatasCaches!.metaDatas, update.sheetName,
                    id, false);
                await backStore!.removeData(removedItems);
                for(var itemToRemove in removedItems) {
                  sheetsToReload.add(itemToRemove.sheetName);
                }
              }
           }

            await filesStore.removeSheetUpdate();

            for(String reloadSheet in sheetsToReload) {
              await loadDatas(last, reloadSheet, true);
            }



          }
        }
      } catch (e, stacktrace) {
        // if( connection) {
        debugPrintStack(label: "AsyncStore ERROR  ${e.toString()}", stackTrace: stacktrace);

        // }
      }

      await Future.delayed(const Duration(seconds: 10));
    }
  }








  stop() {
    debugPrint("stop");
    continueThread = false;
  }
}
