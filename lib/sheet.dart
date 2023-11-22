import 'dart:collection';

import 'package:form_test/column_descriptor.dart';
import 'package:form_test/form_descriptor.dart';

class DatasSheet {
  final  List<Map<String,String>> datas;
  final  LinkedHashMap<String,ColumnDescriptor> columns;
  final FormDescriptor form;

  DatasSheet(this.datas, this.columns, this.form);
}