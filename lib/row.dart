import 'dart:collection';

import 'package:form_test/column_descriptor.dart';
import 'package:form_test/custom_image_state.dart';
import 'package:form_test/src/store/front/form_descriptor.dart';

class DatasRow {
  final  Map<String,String> datas;
  final  LinkedHashMap<String,ColumnDescriptor> columns;
  final  Map<String,CustomImageState> files;
  final  Map<String,String> initialsReferenceLabels;
  final List<FormDescriptor> formDescriptors;
  DatasRow(this.datas, this.columns, this.files, this.initialsReferenceLabels,this.formDescriptors);
}