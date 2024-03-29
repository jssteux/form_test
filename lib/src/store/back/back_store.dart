import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:form_test/custom_image_state.dart';

import 'package:form_test/logger.dart';
import 'package:form_test/src/store/back/back_store_api.dart';
import 'package:form_test/src/store/front/sheet.dart';
import 'package:google_sign_in/google_sign_in.dart' as sign_in;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import "package:googleapis_auth/auth_io.dart";
import '../../files/file_item.dart';
import '../back/google_auth_client.dart';

const _sheetsEndpoint = 'https://sheets.googleapis.com/v4/spreadsheets/';


class BackStore {
  final sign_in.GoogleSignInAccount account;
  final Logger logger;
  DateTime? lastCheck;
  FileItem? spreadSheet ;
  static RegExp exp = RegExp('https://drive.google.com/file/d/([a-zA-Z0-9_-]*)/view');




  BackStore(this.account, this.logger);

  static String? getIdFromUrl(String url) {

    String? id;

    Iterable<RegExpMatch> matches = exp.allMatches(url);
    for (final m in matches) {
      id = m[1]!;
    }

    return id;
  }

  Future<FileSyncInfos> getModifiedFiles(DateTime? currentLastModified, List<String> urls) async {

    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    List<String> inputIds = [];
    List<String> outputUrls = [];


    DateTime? newLastModified;



    for(String url in urls) {
      String? id = getIdFromUrl( url);
      if( id != null) {
        inputIds.add(id);
      }
    }


    for(String id in inputIds) {

      var file  = await driveApi.files.get(id,
          supportsAllDrives: true,   $fields: 'id, modifiedTime') as drive.File;

      DateTime? fileDate = file.modifiedTime;

      if( file.id != null) {
        if (currentLastModified == null ||
            (fileDate != null && fileDate!.isAfter(currentLastModified))) {
          outputUrls.add('https://drive.google.com/file/d/${file.id!}/view');
        }

        // update last modified
        if (newLastModified == null ||
            (fileDate != null && fileDate!.isAfter(newLastModified))) {
          newLastModified = fileDate;
        }
      }
    }


    return FileSyncInfos(newLastModified, outputUrls);
  }



  Future<String?> save(File? file) async {
    if (file == null) {
      return null;
    }
    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    drive.Drive? current = await getFolder(driveApi);

    if (current != null) {
      var media = drive.Media(file.openRead(), file.lengthSync());
      var driveFile = drive.File();
      driveFile.name = file.path;

      String? id = current.id!;
      driveFile.parents = [id];
      var fileCreated = await driveApi.files
          .create(supportsAllDrives: true, driveFile, uploadMedia: media);
      return fileCreated.id;
    }
    return null;
  }

  Future<String?> saveImage(Uint8List? bytes) async {
    if (bytes == null) {
      return null;
    }
    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    drive.Drive? current = await getFolder(driveApi);

    if (current != null) {
      var stream = http.ByteStream.fromBytes(bytes);

      var media = drive.Media(stream, bytes.length);

      var driveFile = drive.File();
      driveFile.name = "image";

      String? id = current.id!;
      driveFile.parents = [id];
      var fileCreated = await driveApi.files
          .create(supportsAllDrives: true, driveFile, uploadMedia: media);
      return fileCreated.id;
    }

    return null;
  }

  Future<Directory> getTemporaryDirectory() async {
    bool exists = await Directory("/files").exists();
    if (exists == false) {
      Directory.fromUri(Uri.directory("/files")).createSync();
    }

    return Directory("/files");
  }

  Future<Uint8List?> readMedia(String url) async {
    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);


    String? fileId = getIdFromUrl(url);
    if( fileId != null)
     {

      drive.Media readFile = await driveApi.files.get(fileId,
          supportsAllDrives: true,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

//      final Directory tempDir = await getTemporaryDirectory();

      List<int> dataStore = [];
      var stream = readFile.stream;

      await for (final value in stream) {
        dataStore.insertAll(dataStore.length, value);
      }

      return Uint8List.fromList(dataStore);
    }
    return null;
  }

  Future<drive.Drive?> getFolder(drive.DriveApi driveApi) async {
    drive.Drive? current;

    var drives = await driveApi.drives.list();
    if (drives.drives != null) {
      var items = drives.drives;
      if (items != null) {
        for (var item in items) {
          if (item.name == "Forms") {
            current = item;
          }
        }
      }
    }
    return current;
  }

  // Use service account credentials to obtain oauth credentials.
  Future<AuthClient> obtainServiceCredentials() async {
    var accountCredentials = ServiceAccountCredentials.fromJson({
      "private_key_id": "f34baf3b4c021c4068573ade1050508319382b43",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDjHuJoSlxaePB4\noocep1Hhqy4DiXesLFtrNW7e751dc3vnPbD1aDuaoEr32obpqCsGfcNNweS+jEUV\nOy3eidjb1ZuzYs3/2Op7HVdw/CIvp7PvLOckjRdu6StbmuwcqJrNHki5/F38OMOC\nsMtGqAB4sHZQaXApLylNV54G+6EkpYDmM6keBrWw6RiQ4s6LJqnpVETJqyH95rlB\n4/Hti5lV6KFz1ts5MnYqGW0RXHAttCpENHvYCq2d4Ti2HWA+gSAGFWJFY9pVEz03\nMT1yXam0QxCkymYg95HbE0mdP/HjWIt3zFYYIyO2AWFhKyLeERjPhN7ac9SodB9z\nrc7gTx3DAgMBAAECggEAN+vsUkJw7+PUTdeyzlTjX92+pCdOXInFbqXG6UR1akOb\nj+nMLvidqGpsWw+m5VQ/V8dSdcxWbqZqAhrCpgcp6qLzRd1/nE3EGlE0rQCfyD0S\nHENhnEnTKb9mqhUAquPGzdd1j7m4SHiPhxfRzVFjYFQOpaj4cWOH11/J7K07VaKl\n0L5S0ZXLAwFBA7chBjn+VE1BCiUatvKYyBHwoRPDu8Bo0fZR7UyEJex/yh5oWGAu\np8Czgc26ot4FAYYOKMfQXJv6x1r3O7nDh4zE3tl9nHpozOk7BLdozhPWxPjwgqVk\nuYAV9+TX8Ek5JwuQk46CYc+iA3ssV6nJB4Kz/B+u2QKBgQD16FAdW6vLj9kupR4p\ndOzlk+1bZeC/Kcwc9eAARlR9MHTilx1RntySuMZibOcmTBioxh5SvezYkFdCKjLQ\n+S3dhPpxY80VsRdxCXWH23SSqoMVJAwq6KrTvolYy/YWP/dxSWSmQ56akhbpQDOW\nxd7gqrmhU9FlLWDhtjNfL+TBuQKBgQDscS7avipDmeAOxmmcE/bzuX2j64rJcLcC\nM2366vmS7sGn3lEiTFyThHqGeuO/MB8F+KrGyeauAilXZkrQx1ANiJBrpP95M3q8\nDBhue3N0RnCZZhL5N0MEani+7yJxR7sQmcevMiVdxa9p/z5DE1URJriiRcjm8beK\nWIssbwTJWwKBgQCQn+D+YzvWrPN+i34Bw9LP8wBWEMTtqRdysOjdQH/QYP9dhKKp\nrlTrteB3YrVPwNF/8YVEBI+XjszDDS512RcwgVUJ+zhS2aR/xqBpFpio6b/OXzUI\nx24wuo7suogw7c4JwrB/WKWfIux2olu1AQrj94TVbQZqCxY/qXjtMq3HgQKBgQCD\nLahZI/g+2Tg9+kbNmSYBwn+6Wgv+BtMCHZZ/B66/nkdC400QQl16Wp2/zp5cjE4p\n+fSFpa6eDATzwITxoCMB3yqBDmHO1Ijbm7pSUZuUfyApe0A7lDVSVd/3zqTFRI68\nfxUSVjf09qCDpmDcxfUENv9oyF7WAnVaBBXy6QU20QKBgAy9c1vNFHoNOaQXzjt8\n5HXZktOCqNsHKO//CIMYYTE5sDmcbIDKiU94ZHH23WEO9UyVLdTpUGrDhRHrxnQD\niBgDJLEXwww/GZ42ixxYlCA2KmVT1pVs7a8/5V/qP/wCn8Eq0v/u/G9Tw1HG7TI6\neUo3EA69hlWmEo0T0YRv0TYI\n-----END PRIVATE KEY-----\n",
      "client_email": "data-access@oauth2-demo-334509.iam.gserviceaccount.com",
      "client_id": "114481516406465407526",
      "type": "service_account"
    });
    var scopes = [
      drive.DriveApi.driveScope,
      'https://www.googleapis.com/auth/spreadsheets'
    ];

    AuthClient client =
        await clientViaServiceAccount(accountCredentials, scopes);

    return client;
  }



  Future<int> saveData(
      MetaDatas metaDatas,
      String sheetName,
      Map<String, String> formValues,
      Map<String, CustomImageState> files) async {
    //test();

    if( metaDatas.sheetDescriptors[sheetName] == null) {
      throw(Exception("sheet not defined"));
    }

    SheetDescriptor desc =  metaDatas.sheetDescriptors[sheetName]!;

    String primaryKey = metaDatas.sheetDescriptors[sheetName]!.primaryKey;
    var columns = desc.columns;

    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    // Fonctionne avec l'utilisation d'un compte de service
    //final authenticateClient = await obtainServiceCredentials();


    //search main
    String? sheetFileId = getSheetFileId();


    String encodedRange;

    String uri;
    /*
    if( account.email == 'jssteux@gmail.com') {
     uri = '$_sheetsEndpoint$spreadsheetId/values/$encodedRange:append?valueInputOption=RAW';
    }
    else {
      */

    // Reload datas
    List<dynamic> rows = await loadDatas(metaDatas, sheetName);
    List<Map<String, String>> datas = transformSheetRowsToMap(rows, metaDatas, sheetName);



    List<String> keepValues = [];

    /* Upload files */

    for (int i = 0; i < files.length; i++) {
      var key = files.keys.elementAt(i);
      var file = files[key];

      String? id;
      if (file is CustomImageState) {
        if (file.modified) {
          if (file.content != null) {
            id = await saveImage(file.content);
          } else {
            id = "";
          }
        } else  {
          // Keep url
          String? columnName;
          columnName = columns.keys.elementAt(int.parse(key));
          keepValues.add(columnName);
        }
      } else {
        id = await save(file);
      }

      if (id != null) {
        String? columnName;
        columnName = columns.keys.elementAt(int.parse(key));
        if (columnName.isNotEmpty) {
          if (id.isNotEmpty) {
            formValues[columnName] = "https://drive.google.com/file/d/$id/view";
          } else {
            formValues[columnName] = "";
          }
        }
      }
    }







    // Search current item
    var index = -1;
    String? id = formValues[primaryKey];
    if (id != null) {
      for (int i = 0; i < datas.length; i++) {
        if (datas.elementAt(i)[primaryKey] == id) {
          index = i;
        }
      }
    }



    /* Create values */
    int nbColumns = columns.length;
    List<String> values = [];

    for (int i = 0; i < nbColumns; i++) {
      String name = columns.keys.elementAt(i);
      String? value = formValues[name];
      value ??= "";

      if( keepValues.contains(name))  {
        String? oldValue = datas.elementAt(index)[name];
        if( oldValue != null) {
          value = datas.elementAt(index)[name]!;
        }
      }

      values.add(value);
    }




    int firstRow = metaDatas.sheetDescriptors[sheetName]!.firstRow;
    String firstCol =  metaDatas.sheetDescriptors[sheetName]!.firstCol;

    String lastColumn = String.fromCharCode(metaDatas.sheetDescriptors[sheetName]!.firstCol.codeUnitAt(0) + nbColumns - 1);

    if (index == -1) {
      // Select the first empty row
      int row = firstRow + datas.length;


      String range = '$sheetName!$firstCol$row:$lastColumn$row';
      encodedRange = Uri.encodeComponent(range);
      uri =
      '$_sheetsEndpoint$sheetFileId/values/$encodedRange:append?valueInputOption=RAW&insertDataOption=OVERWRITE';

      //final response = await authenticateClient.post(
       await authenticateClient.post(
        Uri.parse(uri),
        body: jsonEncode(
          {
            "majorDimension": "ROWS",
            'values': [values],
          },
        ),
      );


      //print(response.body.toString());
    } else {
      int indexInsertion = index + firstRow;
      String range = "$sheetName!$firstCol$indexInsertion:$lastColumn$indexInsertion";

      encodedRange = Uri.encodeComponent(range);

      uri =
      '$_sheetsEndpoint$sheetFileId/values/$encodedRange?valueInputOption=RAW';
      await authenticateClient.put(
        //final response = await authenticateClient.put(
        Uri.parse(uri),
        body: jsonEncode(
          {
            "range": range,
            "majorDimension": "ROWS",
            'values': [values],
          },
        ),
      );
      //print(response.body.toString());
    }
    /*
  }
  */

    //print(response.body.toString());
    //print('save datas');

    return index;
  }











  removeData(
      MetaDatas metaDatas,
  List<ItemToRemove> items)
  async {
    //test();



    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    // Fonctionne avec l'utilisation d'un compte de service
    //final authenticateClient = await obtainServiceCredentials();


    //search main
    String? sheetFileId = getSheetFileId();
    String uri;



    Map<String,int> sheetIds = await getSheetsId();


    var requests =   [ ];

    for(ItemToRemove item in items) {

      int firstRow = metaDatas.sheetDescriptors[item.sheetName]!.firstRow;

      String sFirstCol = metaDatas.sheetDescriptors[item.sheetName]!.firstCol;
      int startColumnIndex = sFirstCol.codeUnitAt(0) -"A".codeUnitAt(0) ;
      String sLastCol = metaDatas.sheetDescriptors[item.sheetName]!.lastCol;
      int lastColumnIndex = sLastCol.codeUnitAt(0) -"A".codeUnitAt(0) ;



      var request = {
        "deleteRange": {
          "range": {
            "sheetId": sheetIds[item.sheetName],
            "startRowIndex": item.startIndex + firstRow - 2,
            "endRowIndex": item.endIndex + firstRow - 2,
            'startColumnIndex': startColumnIndex,
            'endColumnIndex': lastColumnIndex + 1,
          },
          'shiftDimension': 'ROWS'
        }
      };

      requests.add(request);
    }





      uri =
      '$_sheetsEndpoint$sheetFileId:batchUpdate';

    await authenticateClient.post(
    //  var response = await authenticateClient.post(
        //final response = await authenticateClient.put(
        Uri.parse(uri),
        body: jsonEncode(
            {
              "requests": requests,
            }
        ),
      );
      //print(response.body.toString());

      /*
  }
  */

      //print(response.body.toString());
      //print('remove datas');




  }











  Future<Map<String,int>> getSheetsId() async {

    debugPrint("getSheetsId");

    LinkedHashMap<String, int> sheetIds = LinkedHashMap();
    final authHeaders = await account.authHeaders;

    final authenticateClient = GoogleAuthClient(authHeaders);

    //search main
    String? sheetFileId = getSheetFileId();
    // Get sheet ID
    String getUri = "${_sheetsEndpoint}get";
    getUri = "$getUri?spreadsheetId=$sheetFileId&includeGridData=false";
    var getResponse =  await authenticateClient.get(
      Uri.parse(getUri),
    );


    //debugPrint(getResponse.body.toString());
    final parsed = jsonDecode(getResponse.body.toString());
    List sheets = parsed["sheets"];
    for(Map sheet in sheets)  {
      Map properties = sheet["properties"];
      sheetIds.putIfAbsent(properties["title"], () => properties["sheetId"]);

    }

    return sheetIds;
  }


  Future<List<dynamic>> getMetadatasDatasRows() async {

    debugPrint("getMetadatasDatasRows");

    final authHeaders = await account.authHeaders;

    final authenticateClient = GoogleAuthClient(authHeaders);


    String? sheetFileId = await getSheetFileId();

    final encodedRange = Uri.encodeComponent("_METADATAS!A1:G1000");

    String uri = '$_sheetsEndpoint$sheetFileId/values/$encodedRange';

    final response = await authenticateClient.get(Uri.parse(uri));

    final data = jsonDecode(response.body.toString());
    final List<dynamic> rows = data['values'];
    return rows;
  }

  Future<DateTime> getSheetInformation() async {

    debugPrint("getSheetInformation");


    final authHeaders = await account.authHeaders;

    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    String? sheetFileId = getSheetFileId();
    var file = await driveApi.files
        .get(sheetFileId!, supportsAllDrives: true, $fields: 'modifiedTime');
    if (file is drive.File) {
      return file.modifiedTime!;
    }

    throw Exception("Spreadsheet not found");
  }

  List<Map<String, String>> transformSheetRowsToMap(
      List<dynamic> rows, MetaDatas metaDatas, String sheetName) {
    // Transform datas to map
    List<Map<String, String>> res = [];
    var cols = metaDatas.sheetDescriptors[sheetName]!.columns;

    for (int i = 0; i < rows.length; i++) {
      Map<String, String> rowMap = {};

      List<dynamic> rowCells = rows.elementAt(i);
      for (int j = 0; j < cols.length; j++) {
        var value = "";
        if (j < rowCells.length) {
          value = rowCells.elementAt(j);
        }
        rowMap.putIfAbsent(cols.keys.elementAt(j), () => value);
      }

      res.add(rowMap);
    }

    return res;
  }

  Future<List<dynamic>> loadDatas(MetaDatas metaDatas, String sheetName) async {

    debugPrint("loadDatas $sheetName");

    final authHeaders = await account.authHeaders;

    final authenticateClient = GoogleAuthClient(authHeaders);

    if( metaDatas.sheetDescriptors[sheetName] == null) {
      throw(Exception("sheet not defined"));
    }

    String? sheetFileId = getSheetFileId();

    String range = "${metaDatas.sheetDescriptors[sheetName]!.firstCol}${metaDatas.sheetDescriptors[sheetName]!.firstRow}:${metaDatas.sheetDescriptors[sheetName]!.lastCol}${metaDatas.sheetDescriptors[sheetName]!.lastRow}";


    final encodedRange = Uri.encodeComponent("$sheetName!$range");

    String uri = '$_sheetsEndpoint$sheetFileId/values/$encodedRange';

    final response = await authenticateClient.get(Uri.parse(uri));

    final data = jsonDecode(response.body.toString());



    if( data['values'] == null) {
      // Not values found
      return [];
    }

    final List<dynamic> rows = data['values'];




    return rows;

  }





   getSheetFileId()  {
    return spreadSheet!.id;
  }






  Future<List<FileItem>> allFileList( String? id, String? pattern) async {

    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);
    const  sheetMimeType = "application/vnd.google-apps.spreadsheet";

    List<drive.File> qFiles = [];
    List<FileItem> res = [];


    if( id != null) {
      var file = await driveApi.files
          .get(id, $fields: '*', supportsAllDrives: true);
        if (file is drive.File) {
          qFiles.add(file);
        }

      } else {
      drive.FileList files;
      if (pattern == null || pattern.isEmpty) {
        files = await driveApi.files.list(
            $fields: '*',
            includeItemsFromAllDrives: true,
            supportsAllDrives: true,
            q: "mimeType = '$sheetMimeType'"

        );
      } else {
        files = await driveApi.files.list(
            $fields: '*',
            includeItemsFromAllDrives: true,
            supportsAllDrives: true,
            q: "name contains '*$pattern*' and mimeType = '$sheetMimeType'"
        );
      }

      for( var file in files.files!) {
          qFiles.add(file);
      }

    }

    /*
  static const  _folderType = "application/vnd.google-apps.spreadsheet";
  final isFolder = file.mimeType == _folderType;
 */
    
    for( drive.File file in qFiles) {
        String path = "";

        var parents = file.parents;
        while( parents != null) {

          for (String parentId in parents) {
            var parent = await driveApi.files
                .get(parentId, $fields: '*', supportsAllDrives: true);
            if (parent is drive.File) {
              path = "/${parent.name!}$path" ;
                  parents = parent.parents;
            } else  {
              parents = null;
            }
          }
        }

        res.add(FileItem(file.id!, file.name!, path));

    }

    return res;
  }




}
