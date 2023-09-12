import 'dart:collection';

import 'package:form_test/column_descriptor.dart';

class DatasSheet {
  final  List<Map<String,String>> datas;
  final LinkedHashMap<String,ColumnDescriptor> columns;

  DatasSheet(this.datas, this.columns);
}