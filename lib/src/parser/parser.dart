import 'dart:collection';

import 'package:form_test/column_descriptor.dart';
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
      newStep = nameIndice ;
    }

    //print("parse $index $newStep $step");

    // empty line
    if (newStep == -1) {
      index =  index + 1;
    }

    // Return to previous level and preserve index
    if( newStep <= step) {
      //print("return to previous name=$name value=$value");
      return ParserContext(newStep, index);
    }

    // property
    if (name.isNotEmpty && value.isNotEmpty) {
      //print("addElement name=$name value=$value");
      elements.add( ParserProperty(name, value));
      return ParserContext(newStep, index + 1);
    }

    // level
    if (newStep > step) {
      List<dynamic> childElements = [];
      ParserLevel level = ParserLevel(name, childElements);
      elements.add(level);
      //print("addChild name=$name value=$value");

      index = index +1;
      bool endChild = false;

      while( index < rows.length && endChild == false) {
        //print("parseChild $name $index ");
        ParserContext ctx = parse(childElements, rows, index, newStep);
        //print("returnedChild $name  "+ ctx.step.toString());
        if( ctx.step <= newStep) {
          endChild = true;
        }
        index = ctx.index;
      }
    }

    return ParserContext(newStep, index);
  }





  LinkedHashMap<String, ColumnDescriptor>? parseDescriptor(String sheetName, List<dynamic> rows) {

    LinkedHashMap<String, ColumnDescriptor> desc = LinkedHashMap();
    List<dynamic> elements = [];

    ParserContext ctx = const ParserContext(-1, 0);

    // Loop over rows
    while ( ctx.index < rows.length) {
      int index = ctx.index;
      ctx =  parse(elements, rows, index, -1);
    }

    bool found = false;

    // parse results
    for ( var element in elements){
      if( element is ParserLevel) {
        if(element.name == "SHEET")  {
          for ( var subStep in element.children)  {
            if( subStep is ParserProperty)  {
              if (subStep.name == "NAME" && subStep.value == sheetName) {
                found = true;
                //('foundsheet');
              }
            }
          }
          // Sheet found
          if( found)  {

            for ( var subStep in element.children)  {
              if( subStep is ParserLevel)  {
                if (subStep.name == "COLUMN") {
                  //print('foudn coulmn');
                  String? name;
                  String type = "STRING";
                  String label = "";

                  for( var propertySheet in subStep.children)  {
                    if( propertySheet is ParserProperty)  {
                      if(propertySheet.name == "NAME") {
                        name = propertySheet.value;
                      }
                      if(propertySheet.name == "TYPE") {
                        type = propertySheet.value;
                      }
                      if(propertySheet.name == "LABEL") {
                        label = propertySheet.value;
                      }
                    }
                  }

                  if(name != null) {
                    desc.putIfAbsent(
                        name, () => ColumnDescriptor(name!,type, label));
                    //print('add column$name $type');
                  }
                }
              }
            }
          }
        }

      }
    }
    if( found) {
      return desc;
    } else {
      return null;
    }
  }

}