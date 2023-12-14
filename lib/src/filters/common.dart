

/// Common mathematical constants.
final constants = {

};

dynamic current(dynamic exp){

  return "1";
}


dynamic today(Map<String, dynamic> variables){
  return variables['_SHEET_ITEM_ID'];
}

/// Common mathematical functions.
final functions = {
  'TODAY': today,
};

final unaryFunctions = {
  'CURRENT': current,
};

