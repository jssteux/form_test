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
    ..primitive((letter() & word().star())
        .flatten('variable expected')
        .trim()
        .map(_createVariable));
  builder.group()
    ..wrapper(
        seq2(
          word().plusString('function expected').trim(),
          char('(').trim(),
        ),
        char(')').trim(),
            (left, value, right) => _createFunction(left.$1, value))
    ..wrapper(
        char('(').trim(), char(')').trim(), (left, value, right) => value);
  builder.group()
    ..left(string('>').trim(), (a, op, b) => SupBinary(a,b))
    ..left(string('OR').trim(), (a, op, b) => Binary('OR', a, b, (x, y) => x || y));
  return resolve(builder.build()).end();
}();

Expression _createValue(String value) => Value(value);

Expression _createVariable(String name) =>
    constants.containsKey(name) ? Value(constants[name]!) : Variable(name);

Expression _createFunction(String name, Expression expression) =>
    Unary(name, expression, functions[name]!);