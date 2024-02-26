import 'dart:collection';

import 'package:form_test/column_descriptor.dart';
import 'package:form_test/src/store/front/form_descriptor.dart';


class FilteredLine  {
  final Map<String,String> datas;
  final Map<String,String> referenceLabels;

  final int originalIndex;

  FilteredLine(this.datas, this.referenceLabels, this.originalIndex);
}

class ListDatas {
  final  List<FilteredLine> lines;
  final  String primaryKey;
  final  LinkedHashMap<String,ColumnDescriptor> columns;
  final FormDescriptor form;

  ListDatas(this.lines, this.primaryKey, this.columns, this.form);
}


class FormSuggestionItem {
  final  String ref;
  final  String displayName;

  FormSuggestionItem(this.ref, this.displayName);
}


class MetaDatas {

  final  LinkedHashMap<String,SheetDescriptor> sheetDescriptors;
 // final  Map<String,int> sheetIds;
  final  List<FormDescriptor> formDescriptors;
  MetaDatas(this.sheetDescriptors, this.formDescriptors);
}

class MetaDatasCache {
  final DateTime? modifiedTime;
  final MetaDatas metaDatas;
  MetaDatasCache( this.metaDatas, this.modifiedTime);
}


class SheetDescriptor {
  final  LinkedHashMap<String,ColumnDescriptor> columns;
  final  List<String> refDisplayName;
  final List<FormDescriptor> formDescriptors;
  final String firstCol;
  final int firstRow;
  final String lastCol;
  final int lastRow;
  final String primaryKey;


  SheetDescriptor(this.columns, this.formDescriptors, this.firstCol, this.firstRow, this.lastCol, this.lastRow, this.primaryKey, this.refDisplayName);
}

class SheetDatas {
  final  List<Map<String,String>> datas;
  final  LinkedHashMap<String,ColumnDescriptor> columns;
  final  List<String> referenceLabels;

  SheetDatas(this.datas, this.columns, this.referenceLabels);
}



class SheetDatasCache {
  final DateTime? modifiedTime;
  final SheetDatas sheetContent;
  SheetDatasCache( this.sheetContent, this.modifiedTime);
}