import 'dart:math' as math;

import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'common.dart';

var filter_parser = () {
  final builder = ExpressionBuilder<Expression>();
  builder
    ..primitive((digit().plus() &
    (char('.') & digit().plus()).optional() &
    (pattern('eE') & pattern('+-').optional() & digit().plus())
        .optional())
        .flatten('number expected')
        .trim()
        .map(_createValue))
    ..primitive((char("'") & letter().plus() & char("'")
        .optional())
        .flatten('string expected')
        .trim()
        .map(_createValue))
    ..primitive((letter() & word().star() & noneOf("("))
        .flatten('variable expected')
        .trim()
        .map(_createVariable))
    // function without arguments
    ..primitive(( letter().plus() & char("(") & whitespace().star() & char(")"))
      .flatten('function with no argement expected')
      .trim()
      .map(_createFunction))




    ;

  builder.group()

    ..wrapper(
        seq2(
          word().plusString('function expected 2').trim(),
          char('(').trim(),
        ),
        char(')').trim(),
            (left, value, right) => _createUnaryFunction(left.$1, value))

    ..wrapper(
        char('(').trim(), char(')').trim(), (left, value, right) => value);


  builder.group()
    ..left(string('>').trim(), (a, op, b) => SupBinary(a,b))
    ..left(string('=').trim(), (a, op, b) => EqualsBinary(a,b))
    ..left(string('OR').trim(), (a, op, b) => Binary('OR', a, b, (x, y) => x || y));
  return resolve(builder.build()).end();
}();

Expression _createValue(String value) => Value(value);

Expression _createVariable(String name) {
  String variableName = name.replaceAll(" ", "");
  return constants.containsKey(variableName) ? Value(constants[variableName]!) : Variable(variableName);
}

Expression _createFunction(String name)
    {

    String functionName = name.replaceAll(" ", "");
    functionName = functionName.substring(0,functionName.length -2);

    print("create function $functionName");
    return SimpleFunction(functionName, functions[functionName]!);
}
Expression _createUnaryFunction(String name, Expression expression) =>
    Unary(name, expression, unaryFunctions[name]!);