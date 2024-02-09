import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:form_test/column_descriptor.dart';
import 'package:form_test/custom_image_state.dart';
import 'package:form_test/src/store/async/async_store.dart';
import 'package:form_test/src/store/back/back_store_api.dart';
import 'package:form_test/src/store/back/back_store.dart';
import 'package:form_test/src/store/front/form_descriptor.dart';
import 'package:form_test/logger.dart';
import 'package:form_test/main.dart';
import 'package:form_test/src/files/file_item.dart';
import 'package:form_test/src/filters/ast.dart';
import 'package:form_test/src/filters/filter_parser.dart';
import 'package:form_test/src/parser/parser.dart';
import 'package:form_test/row.dart';
import 'package:form_test/src/store/front/sheet.dart';



class FrontStore {
  final Logger logger;
  final Parser parser;
  BackStore? backStore;
  final AsyncStore asyncStore;

  DateTime? lastCheck;
  Map<String, dynamic> sheetCaches = {};
  MetaDatasCache? metatDatasCaches;

  FrontStore(this.backStore, this.asyncStore, this.logger , {this.parser = const Parser()});

  set spreadSheet(FileItem? spreadSheet) {
    backStore!.spreadSheet = spreadSheet;

  }
  FileItem? get spreadSheet { return backStore!.spreadSheet;}

  updateBackstore( BackStore? newBackStore) {
    backStore = newBackStore;
    asyncStore.backStore = backStore;
  }

  stop( ) {
    asyncStore.stop();

  }



  Future<String?> save(File? file) async {
    if( backStore != null) {
      return await backStore!.save(file);
    }
  }

  Future<String?> saveImage(Uint8List? bytes) async {
    if( backStore != null) {
      return backStore!.saveImage(bytes);
    }
  }

  Future<Directory> getTemporaryDirectory() async {
    bool exists = await Directory("/files").exists();
    if (exists == false) {
      Directory.fromUri(Uri.directory("/files")).createSync();
    }

    return Directory("/files");
  }

  Future<Uint8List?> read(String url) async {
    return await asyncStore.getMedia(url);

  }


  createDatas(
      BuildContext context,
      String sheetName,
      Map<String, String> formValues,
      LinkedHashMap<String, ColumnDescriptor> columns,
      Map<String, CustomImageState> files) async {

    /*
      if( backStore != null) {
        int index = await backStore!.saveDataOld(
            context, await getMetadatas(), sheetName, formValues, columns,
            files);


        // update cache
        SheetDatasCache cache = sheetCaches[sheetName];

        if (index != -1) {
          cache.sheetContent.datas[index] = formValues;
        } else {
          cache.sheetContent.datas.add(formValues);
        }
      }
    else  {

     */
    await asyncStore.createDatas(sheetName, formValues);
    //}


    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }


  modifyDatas(
      BuildContext context,
      String sheetName,
      Map<String, String> formValues,
      LinkedHashMap<String, ColumnDescriptor> columns,
      Map<String, CustomImageState> files) async {

    /*
      if( backStore != null) {
        int index = await backStore!.saveDataOld(
            context, await getMetadatas(), sheetName, formValues, columns,
            files);


        // update cache
        SheetDatasCache cache = sheetCaches[sheetName];

        if (index != -1) {
          cache.sheetContent.datas[index] = formValues;
        } else {
          cache.sheetContent.datas.add(formValues);
        }
      }
    else  {

     */
      await asyncStore.modifyDatas(sheetName, formValues);
    //}


    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }





  removeData(
      BuildContext context,
      String sheetName,
      String id) async {
    await asyncStore.removeData(sheetName, id);
  }



  Future<SheetDescriptor?> loadDescriptor(String sheetName) async {
    MetaDatas metadatas = await getMetadatas();
    return metadatas.sheetDescriptors[sheetName];
  }

  Future<List<FormDescriptor>> getForms() async {
    MetaDatas metadatas = await getMetadatas();
    return metadatas.formDescriptors;
  }

  Future<MetaDatas> getMetadatas() async {

    return await asyncStore.getMetadatas();
  }




  Future<SheetDatas> getDatas(String sheetName) async {

    SheetAsyncCache asyncCache = await asyncStore.getDatas(sheetName);

    print('front get datas');

    List<Map<String, String>> datas  = asyncCache.rows;

    var sheetDescriptor = await loadDescriptor(sheetName);

    SheetDatas sheetDatas = SheetDatas( datas, sheetDescriptor!.columns, sheetDescriptor.refDisplayName);

    return sheetDatas;


  }






  Future<FormDatas> loadForm(
      String? formSheetName, int formIndex, String pattern, Context ctx) async {
    List<FormDescriptor> forms;

    debugPrint("front load forms");

    if (formSheetName != null) {
      var metadatas = await getMetadatas();
      forms = metadatas.sheetDescriptors[formSheetName]!.formDescriptors;
    } else {
      forms = await getForms();
    }

    FormDescriptor form = forms[formIndex];

    String sheetName = form.sheetName;



    SheetDatas datas = await getDatas(sheetName);


    // Apply pattern to condition
    String fullCondition;
    String patternCondition;
    if(pattern.isNotEmpty) {
      patternCondition = "FULLTEXT LIKE '$pattern'";
      if( form.condition.isNotEmpty)  {
        String condition = form.condition;
        fullCondition =  "( ($condition) AND ($patternCondition) )";
      } else  {
        fullCondition = patternCondition;
      }
    }
    else {
      fullCondition = form.condition;
    }



    List<FilteredLine> filteredLines = [];
    for (int i = 0; i < datas.datas.length; i++) {
      Map<String, String> referenceLabels = {};
      bool insert = false;


      if (fullCondition.isNotEmpty) {
        //String condition = fullCondition;

        Map<String, String?> variables = await prepareVariables(datas, i);

        //print('before $fullCondition');
        var res = evalExpression(fullCondition, variables, ctx);
        //print('after $fullCondition');
        insert = res;
      } else {
        insert = true;
      }

      if (insert) {
        LinkedHashMap<String, ColumnDescriptor> columns = datas.columns;
        for (int j = 0; j < columns.length; j++) {
          ColumnDescriptor desc = columns.values.elementAt(j);
          String columnName = columns.keys.elementAt(j);
          if (desc.reference.isNotEmpty) {
            String refLabel = await getReferenceLabel(
                desc.reference, datas.datas[i][columnName]!);
            referenceLabels.putIfAbsent(columnName, () => refLabel);
          }
        }

        filteredLines.add(FilteredLine(datas.datas[i], referenceLabels, i));
      }
    }

    return FormDatas(filteredLines, datas.columns, form);

  }

  Future<Map<String, String?>> prepareVariables(SheetDatas datas, int i) async {

    Map<String, String?> variables = {};

    String fullText = "";

    debugPrint("********* variables *********");


    for (String variable in datas.columns.keys) {

      debugPrint("variable $variable=" + datas.datas[i][variable].toString());

      variables[variable] = datas.datas[i][variable];

      ColumnDescriptor? desc = datas.columns[variable];

      if( desc != null && desc.reference.isNotEmpty) {
        String refLabel = await getReferenceLabel(
            desc.reference, datas.datas[i][variable]!);
        fullText = "$fullText $refLabel";
      } else  {

      if( variables[variable] != null) {
        fullText = "$fullText ${variables[variable]!}";
      }

      }
    }

    variables["FULLTEXT"] = fullText;
    return variables;
  }

  Future<List<FormSuggestionItem>> getSuggestions(
      String sheetName, String pattern) async {
    List<FormSuggestionItem> items = [];
    SheetDatas datas = await getDatas(sheetName);
    for (int i = 0; i < datas.datas.length; i++) {
      bool insert = false;

      var dataLine = datas.datas[i];

      for (int j = 0; j < datas.columns.keys.length; j++) {
        var columnName = datas.columns.keys.elementAt(j);
        if (dataLine[columnName]!.startsWith(pattern)) {
          insert = true;
        }
      }

      if (insert) {
        String? ref = datas.datas[i]["ID"];
        String? label = getLabelInternal(datas, i);
        if (ref != null && label != null) {
          items.add(FormSuggestionItem(ref, label));
        }
      }
    }
    return items;
  }

  String? getLabelInternal(SheetDatas datas, int i) {
    String? value;
    for (String columnLabel in datas.referenceLabels) {
      if (datas.datas[i][columnLabel] != null) {
        if (value != null) {
          value += " ";
        } else {
          value = "";
        }
        value = value + datas.datas[i][columnLabel]!;
      }
    }
    return value;
  }

  String getReferenceLabelInternal(SheetDatas datas, String ref) {
    for (int i = 0; i < datas.datas.length; i++) {
      String? currentRef = datas.datas[i]["ID"];
      if (currentRef != null) {
        if (currentRef == ref) {
          String? ref = datas.datas[i]["ID"];
          String? currentLabel = getLabelInternal(datas, i);
          if (ref != null && currentLabel != null) {
            return currentLabel;
          }
        }
      }
    }
    return "-";
  }

  Future<String> getReferenceLabel(String sheetName, String ref) async {
    SheetDatas datas = await getDatas(sheetName);
    return getReferenceLabelInternal(datas, ref);
  }

  Future<DatasRow> loadRow(
      String sheetName, int index, Context ctx) async {
    SheetDatas sheet = await getDatas(sheetName);
    Map<String, String> rowDatas = {};
    if (index != -1) {
      rowDatas = sheet.datas[index];
    }
    LinkedHashMap<String, ColumnDescriptor> columns = sheet.columns;
    Map<String, String> referenceLabels = {};
    Map<String, CustomImageState> rowFiles = {};

    for (int j = 0; j < columns.length; j++) {
      ColumnDescriptor desc = columns.values.elementAt(j);
      String columnName = columns.keys.elementAt(j);

      // initialization
      if (index == -1) {
        String initExp = desc.defaultValue;
        if (initExp.isNotEmpty) {
          Map<String, String?> variables = {};



          var res = evalExpression(initExp, variables, ctx);
          if (res != null) {
            rowDatas[columnName] = res;
          }
        }
      }

      // Reference label
      if (desc.reference.isNotEmpty) {
        if (rowDatas[columnName] != null) {
          String refLabel =
              await getReferenceLabel(desc.reference, rowDatas[columnName]!);
          referenceLabels.putIfAbsent(columnName, () => refLabel);
        }
      }
      /*
      if (desc.type == "GOOGLE_IMAGE") {
        String? url = rowDatas[columnName];
        if (url != null && url.isNotEmpty) {
          Uint8List? content = await read(url);
          rowFiles.putIfAbsent(
              j.toString(), () => CustomImageState(false, content));
        }
      }
      */

    }






    var metadatas = await getMetadatas();
    List<FormDescriptor> forms =
        metadatas.sheetDescriptors[sheetName]!.formDescriptors;

    return DatasRow(rowDatas, columns, rowFiles, referenceLabels, forms);
  }


  Future<Uint8List?> loadImage(String? url) async {
    if (url != null && url.isNotEmpty) {
      Uint8List? content = await read(url);
      return  content;
    }
    return null;

  }








  dynamic evalExpression(String initExp, Map<String, String?> variables, Context ctx) {
    Expression ast;

    try {
      //print("parse exp " + initExp);
      ast = filterParser.parse(initExp).value;
    } catch (err) {
      //print('parsing error' + err.toString());
      rethrow;
    }
    //print("eval condition $initExp");

    dynamic res;

    //{'NOM': datas.datas[i]['NOM'], 'CLIENT': datas.datas[i]['CLIENT'], "_CTX": '1'}

    try {
      if( ctx.sheetItemID != null) {
        variables["_SHEET_ITEM_ID"] = ctx.sheetItemID;
      }

      if( ctx.sheetName != null) {
        variables["_SHEET_NAME"] = ctx.sheetName;
      }



      res = ast.eval(variables);
    } catch (err) {
      //print('eval error' + err.toString());
      rethrow;
    }

    return res;
  }




  Future<List<FileItem>> allFileList( String? id, String? pattern) async {
    if( backStore != null) {
      return await backStore!.allFileList(id, pattern);
    } else  {
      return [];
    }
  }




}
