
import 'dart:convert';

class FileUpdate  {

  final String action;
  final String sheetName;
  final Map<String,String> datas;

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'sheetName': sheetName,
      'datas': json.encode(datas)
    };
  }
  factory FileUpdate.fromJson(Map<String, dynamic> jsonDatas) {
    Map<String, dynamic> dynamicDatas = json.decode(jsonDatas["datas"]);
    Map<String, String> datas = {};
    for( String key in dynamicDatas.keys)  {
      datas.putIfAbsent(key, () => dynamicDatas[key]);
    }
    return( FileUpdate(jsonDatas["action"],jsonDatas["sheetName"],  datas));
  }

  FileUpdate(this.action, this.sheetName, this.datas);
}