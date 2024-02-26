import 'dart:collection';

import 'package:form_test/column_descriptor.dart';
import 'package:form_test/src/store/front/form_descriptor.dart';
import 'package:form_test/src/store/front/sheet.dart';
import 'package:form_test/src/parser/parser_context.dart';
import 'package:form_test/src/parser/parser_level.dart';
import 'package:form_test/src/parser/parser_property.dart';

class Parser {
  const Parser();
  ParserContext parse(List elements, List<dynamic> rows, int index, int step) {
    int newStep = -1;
    int nameIndice = -1;
    List<dynamic> rowCells = rows.elementAt(index);
    String name = "";
    String value = "";

    // Parse line
    for (int j = 0; j < rowCells.length; j++) {
      String cellValue = rowCells.elementAt(j);

      if (name.isEmpty) {
        if (cellValue.isNotEmpty) {
          name = cellValue;
          nameIndice = j;
        }
      } else {
        if (cellValue.isNotEmpty) {
          value = cellValue;
        }
      }
    }

    // Get new step
    if (name.isNotEmpty) {
      newStep = nameIndice;
    }

    //print("parse $index $newStep $step");

    // empty line
    if (newStep == -1) {
      index = index + 1;
    }

    // Return to previous level and preserve index
    if (newStep <= step) {
      //print("return to previous name=$name value=$value");
      return ParserContext(newStep, index);
    }

    // property
    if (name.isNotEmpty && value.isNotEmpty) {
      //print("addElement name=$name value=$value");
      elements.add(ParserProperty(name, value));
      return ParserContext(newStep, index + 1);
    }

    // level
    if (newStep > step) {
      List<dynamic> childElements = [];
      ParserLevel level = ParserLevel(name, childElements);
      elements.add(level);
      //print("addChild name=$name value=$value");

      index = index + 1;
      bool endChild = false;

      while (index < rows.length && endChild == false) {
        //print("parseChild $name $index ");
        ParserContext ctx = parse(childElements, rows, index, newStep);
        //print("returnedChild $name  "+ ctx.step.toString());
        if (ctx.step <= newStep) {
          endChild = true;
        }
        index = ctx.index;
      }
    }

    return ParserContext(newStep, index);
  }

  LinkedHashMap<String, SheetDescriptor> parseDescriptors(List<dynamic> rows) {
    LinkedHashMap<String, SheetDescriptor> descriptors = LinkedHashMap();

    List<dynamic> elements = [];

    ParserContext ctx = const ParserContext(-1, 0);

    // Loop over rows
    while (ctx.index < rows.length) {
      int index = ctx.index;
      ctx = parse(elements, rows, index, -1);
    }

    // parse results
    for (var element in elements) {
      if (element is ParserLevel) {
        if (element.name == "SHEET") {
          String? sheetName;
          LinkedHashMap<String, ColumnDescriptor> columnsDescriptor =
              LinkedHashMap();
          List<String> referenceLabels = [];
          String firstCol = 'A';
          int firstRow = 1;
          String lastCol = 'Z';
          int lastRow = 1000;
          String primaryKey="ID";


          for (var subStep in element.children) {
            if (subStep is ParserProperty) {
              if (subStep.name == "NAME") {
                sheetName = subStep.value;
              }
            }
          }

          for (var subStep in element.children) {
            if (subStep is ParserLevel) {
              if (subStep.name == "COLUMN") {
                //print('foudn coulmn');
                String? name;
                String type = "STRING";
                String label = "";
                String reference = "";
                bool mandatory = false;
                String defaultValue = "";
                bool primaryKey = false;
                bool cascadeDelete = false;

                for (var propertySheet in subStep.children) {
                  if (propertySheet is ParserProperty) {
                    if (propertySheet.name == "NAME") {
                      name = propertySheet.value;
                    }
                    if (propertySheet.name == "TYPE") {
                      type = propertySheet.value;
                    }
                    if (propertySheet.name == "LABEL") {
                      label = propertySheet.value;
                    }
                    if (propertySheet.name == "REFERENCE") {
                      reference = propertySheet.value;
                    }
                    if (propertySheet.name == "CASCADE_DELETE") {
                      if ("TRUE" == propertySheet.value) {
                        cascadeDelete = true;
                      }
                    }
                    if (propertySheet.name == "PRIMARY_KEY") {
                      if ("TRUE" == propertySheet.value) {
                        primaryKey = true;
                      }
                    }
                    if (propertySheet.name == "MANDATORY") {
                      if ("TRUE" == propertySheet.value) {
                        mandatory = true;
                      }
                    }
                    if (propertySheet.name == "DEFAULT") {
                      defaultValue = propertySheet.value;
                    }
                  }
                }

                if (name != null) {
                  columnsDescriptor.putIfAbsent(
                      name,
                      () => ColumnDescriptor(name!, type, label, reference,
                          primaryKey, cascadeDelete, mandatory, defaultValue));
                  //print('add column$name $type');
                }
              }
            }

            if (subStep is ParserProperty) {
              if (subStep.name == "REF_COLS") {
                referenceLabels = subStep.value.split(",");
                //print('add column$name $type');
              }
            }

            if (subStep is ParserProperty) {
              if (subStep.name == "RANGE") {

                final rangeRegexp = RegExp(r'^([a-zA-Z]*)([0-9]*):([a-zA-Z]*)(([0-9])*)');


                var match = rangeRegexp.firstMatch(subStep.value);
                if( match != null && match.groupCount == 5)  {
                  // A2:D1000
                  firstCol = match.group(1)!;
                  firstRow = int.parse(match.group(2)!);
                  lastCol = match.group(3)!;
                  lastRow = int.parse(match.group(4)!);
                }
              }
            }

          }

          if (sheetName != null) {



            List<FormDescriptor> sheetForms =
                parseFormsInternal(element.children);



            for(var descriptor in columnsDescriptor.values)  {
              if( descriptor.primaryKey)  {
                primaryKey = descriptor.name;
              }

            }

            descriptors.putIfAbsent(
                sheetName,
                () => SheetDescriptor(
                    columnsDescriptor, sheetForms, firstCol,firstRow, lastCol, lastRow, primaryKey, referenceLabels));
          }
        }
      }
    }

    return descriptors;
  }

  List<FormDescriptor> parseForms(List<dynamic> rows) {
    List<dynamic> elements = [];

    ParserContext ctx = const ParserContext(-1, 0);

    // Loop over rows
    while (ctx.index < rows.length) {
      int index = ctx.index;
      ctx = parse(elements, rows, index, -1);
    }

    return (parseFormsInternal(elements));
  }

  List<FormDescriptor> parseFormsInternal(List<dynamic> elements) {
    List<FormDescriptor> forms = [];

    // parse results
    for (var element in elements) {
      if (element is ParserLevel) {
        if (element.name == "FORM") {
          List<String> columns = [];
          String label = "";
          String sheetName = "";
          String condition = "";

          for (var subStep in element.children) {
            if (subStep is ParserProperty) {
              if (subStep.name == "SHEET") {
                sheetName = subStep.value;
              }
              if (subStep.name == "LABEL") {
                label = subStep.value;
              }
              if (subStep.name == "CONDITION") {
                condition = subStep.value;
              }
            }

            if( subStep is ParserLevel)  {
              if (subStep.name == "COLUMN") {
                String? name;
                for( var propertySheet in subStep.children)  {
                  if( propertySheet is ParserProperty)  {
                    if(propertySheet.name == "NAME") {
                      name = propertySheet.value;
                    }

                  }
                }

                if(name != null) {
                  columns.add(name);
                }
              }
            }
          }

          forms.add(FormDescriptor(sheetName, label, condition, columns));
        }
      }
    }

    return forms;
  }
}
