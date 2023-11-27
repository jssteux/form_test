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
      print('eval $leftE $righE');
      return leftE.compareTo(righE) > 0;
    } else  {
      return false;
    }
  }
}



