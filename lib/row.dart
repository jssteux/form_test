import 'dart:collection';

import 'package:form_test/column_descriptor.dart';
import 'package:form_test/custom_image_state.dart';

class DatasRow {
  final  Map<String,String> datas;
  final  LinkedHashMap<String,ColumnDescriptor> columns;
  final  Map<String,CustomImageState> files;

  DatasRow(this.datas, this.columns, this.files);
}