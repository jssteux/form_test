import 'package:flutter/cupertino.dart';

/// An abstract expression that can be evaluated.
abstract class Expression {
  /// Evaluates the expression with the provided [variables].
  dynamic eval(Map<String, dynamic> variables);
}

/// A value expression.
class Value extends Expression {
  Value(this.value);

  final dynamic value;

  @override
  dynamic eval(Map<String, dynamic> variables) {
    if( value is String)  {
      String sValue = value.toString();
      // remove quotes
      if( sValue.startsWith("'")) {
        sValue = sValue.substring(1, sValue.length - 1);
      }
      return sValue;
    }

    return value;
  }

  @override
  String toString() => 'Value{$value}';
}

/// A variable expression.
class Variable extends Expression {
  Variable(this.name);

  final String name;

  @override
  dynamic eval(Map<String, dynamic> variables) => variables.containsKey(name)
      ? variables[name]!
      : throw ArgumentError.value(name, 'Unknown variable');

  @override
  String toString() => 'Variable{$name}';
}

/// An function expression.
class SimpleFunction extends Expression {
  SimpleFunction(this.name, this.function);

  final String name;

  final dynamic Function(Map<String,dynamic>) function;

  @override
  dynamic eval(Map<String, dynamic> variables) => function(variables);

  @override
  String toString() => 'Unary{$name}';
}



/// An unary expression.
class Unary extends Expression {
  Unary(this.name, this.value, this.function);

  final String name;
  final Expression value;
  final dynamic Function(dynamic value) function;

  @override
  dynamic eval(Map<String, dynamic> variables) => function(value.eval(variables));

  @override
  String toString() => 'Unary{$name}';
}


/// An unary expression.
class Current extends Expression {
  Current(this.value);

  final Expression value;


  @override
  dynamic eval(Map<String, dynamic> variables) {

    dynamic valueE = value.eval(variables);

      if( variables["_SHEET_NAME"] == valueE) {

            String itemId =  variables["_SHEET_ITEM_ID"];
            debugPrint("evalcurrent $valueE $itemId");
            return itemId;
     }


    return null;
  }

  @override
  String toString() => 'Content{$value}';
}







/// A binary expression.
class Binary extends Expression {
  Binary(this.name, this.left, this.right, this.function);

  final String name;
  final Expression left;
  final Expression right;
  final dynamic Function(dynamic left, dynamic right) function;

  @override
  dynamic eval(Map<String, dynamic> variables) =>
      function(left.eval(variables), right.eval(variables));

  @override
  String toString() => 'Binary{$name}';
}


/// A binary expression.
class SupBinary extends Expression {
  SupBinary(this.left, this.right);
  final Expression left;
  final Expression right;


  @override
  String toString() => 'SupBinary';

  @override
  dynamic eval(Map<String, dynamic> variables) {
    dynamic leftE = left.eval(variables);
    dynamic righE = right.eval(variables);

    if( leftE is String && righE is String) {
      //print('eval $leftE $righE');
      return leftE.toUpperCase().compareTo(righE.toUpperCase()) > 0;
    } else  {
      return false;
    }
  }
}

/// A binary expression.
class EqualsBinary extends Expression {
  EqualsBinary(this.left, this.right);
  final Expression left;
  final Expression right;


  @override
  String toString() => 'EqualsBinary';

  @override
  dynamic eval(Map<String, dynamic> variables) {
    dynamic leftE = left.eval(variables);
    dynamic righE = right.eval(variables);

    if( leftE is String && righE is String) {
      //print('eval equals $leftE $righE');
      return (leftE.toUpperCase().compareTo(righE.toUpperCase()) == 0);
    } else  {
      return false;
    }
  }
}



/// A binary expression.
class LikeBinary extends Expression {
  LikeBinary(this.left, this.right);
  final Expression left;
  final Expression right;


  @override
  String toString() => 'Like Binary';

  @override
  dynamic eval(Map<String, dynamic> variables) {
    dynamic leftE = left.eval(variables);
    dynamic righE = right.eval(variables);

    if( leftE is String && righE is String) {
      return leftE.toUpperCase().contains(righE.toUpperCase());
    } else  {
      return false;
    }
  }
}
