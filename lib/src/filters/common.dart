import 'dart:math';

/// Common mathematical constants.
final constants = {

};

dynamic unaryExemple(dynamic exp){
  return "1";
}

dynamic current(Map<String, dynamic> variables){
  return variables['_SHEET_ITEM_ID'];
}

/// Common mathematical functions.
final functions = {
  'CURRENT': current,
};

final unaryFunctions = {
  'unaryExemple': unaryExemple,
};

