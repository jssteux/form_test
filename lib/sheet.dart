import 'dart:collection';

import 'package:form_test/column_descriptor.dart';
import 'package:form_test/form_descriptor.dart';


class FilteredLine  {
  final Map<String,String> datas;
  final int originalIndex;

  FilteredLine(this.datas, this.originalIndex);
}

class FormDatas {
  final  List<FilteredLine> lines;
  final  LinkedHashMap<String,ColumnDescriptor> columns;
  final FormDescriptor form;

  FormDatas(this.lines, this.columns, this.form);
}


class SheetDatas {
  final  List<Map<String,String>> datas;
  final  LinkedHashMap<String,ColumnDescriptor> columns;

  SheetDatas(this.datas, this.columns);
}