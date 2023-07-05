import 'dart:io';
import 'dart:typed_data';
import 'dart:convert' ;
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart' as sign_in;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'google_auth_client.dart';

const _sheetsEndpoint = 'https://sheets.googleapis.com/v4/spreadsheets/';
const spreadsheetId = '1j6l3kbHjlsn23T9CbNuo6jmhytNIv0eVsjUgkFFbsQA';

class FormStore {
  final sign_in.GoogleSignInAccount account;
  const FormStore(this.account);

  save(File? file) async {
    if (file == null) {
      return;
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
      await driveApi.files
          .create(supportsAllDrives: true, driveFile, uploadMedia: media);
    }
  }

  saveImage(Uint8List? bytes) async {
    if (bytes == null) {
      return;
    }
    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    drive.Drive? current = await getFolder(driveApi);

    if (current != null) {
      var stream = http.ByteStream.fromBytes( bytes);

      var media = drive.Media(stream, bytes.length);

      var driveFile = drive.File();
      driveFile.name = "image";

      String? id = current.id!;
      driveFile.parents = [id];
      await driveApi.files
          .create(supportsAllDrives: true, driveFile, uploadMedia: media);
    }
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


  saveData1() async {
    const String URL = "https://script.google.com/macros/s/AKfycbwH2fMTRyDKSZv2z3Z1mrjFNJwCnB0ZGqmRNIVJqUejsKcqNPSPq5Ap1yRArVLJ_KHG5Q/exec";
    var obj = {
      "action": "add",
      "type":"CLIENT",
      "value" : {
        "NOM": "TABANI"
      }
    };
    String str = json.encode(obj);

    try {
      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);


      await authenticateClient.post(Uri.parse(URL), body: str).then((response) async {
        if (response.statusCode == 302) {
          String? url = response.headers['location'];
          await http.get(Uri.parse(url!)).then((response) {
            print(json.decode(response.body)['status']);
          });
        } else {
          print(json.decode(response.body)['status']);
        }
      });
    } catch (e) {
      print(e);
    }

  }



  saveData() async {
    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    //search main
    drive.Drive? current = await getFolder(driveApi);
    String? id = current!.id!;


    drive.File? sheetFile;
    var drives = await driveApi.files.list(corpora: 'drive', driveId: id, includeItemsFromAllDrives: true, supportsAllDrives: true);
    if (drives.files != null) {
      var items = drives.files;
      if (items != null) {
        for (var item in items) {
          if (item.name == "main") {
            if( item.mimeType == 'application/vnd.google-apps.spreadsheet') {
                sheetFile = item;
            }
          }
        }
      }
    }



    final encodedRange = Uri.encodeComponent("CLIENT!A1:D1");
    final sheetFileId = sheetFile!.id;

    String uri = '$_sheetsEndpoint$sheetFileId/values/$encodedRange:append?valueInputOption=RAW';

    final response = await authenticateClient.post(
        Uri.parse(uri ),
      body: jsonEncode(
        {
          "range": "CLIENT!A1:D1",
          "majorDimension": "ROWS",
          'values': [ ['4','TABANI']],
        },
      ),
    );
    print(response.body.toString());

  }



}
