
import 'dart:convert';



class FileUpdate  {

  final String action;
  final String sheetName;
  final Map<String,String> datas;
  final List<String> uploadFileUrls;

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'sheetName': sheetName,
      'datas': json.encode(datas),
      'modifiedFileUrls': json.encode(uploadFileUrls),
    };
  }

  factory FileUpdate.fromJson(Map<String, dynamic> jsonDatas) {

    Map<String, dynamic> dynamicDatas = json.decode(jsonDatas["datas"]);
    Map<String, String> datas = {};
    for( String key in dynamicDatas.keys)  {
      datas.putIfAbsent(key, () => dynamicDatas[key]);
    }

    List< dynamic> dynamicUploadFileUrls = json.decode(jsonDatas["modifiedFileUrls"]);
    List<String> uploadFileUrls = [];
    for( String url in dynamicUploadFileUrls)  {
      uploadFileUrls.add( url);
    }

    return( FileUpdate(jsonDatas["action"],jsonDatas["sheetName"],  datas, uploadFileUrls));
  }

  FileUpdate(this.action, this.sheetName, this.datas, this.uploadFileUrls);
}