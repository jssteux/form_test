import 'dart:io';
import 'dart:typed_data';
import 'dart:convert' ;
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart' as sign_in;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import "package:googleapis_auth/auth_io.dart";
import 'google_auth_client.dart';

const _sheetsEndpoint = 'https://sheets.googleapis.com/v4/spreadsheets/';
const spreadsheetId = '1MBNPE_XOPGy-x_UjVOI81eKbFCQOVq-4vvuxhwnsQ1s';

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



  // Use service account credentials to obtain oauth credentials.
  Future<AuthClient> obtainServiceCredentials() async {
    var accountCredentials = ServiceAccountCredentials.fromJson({
      "private_key_id": "f34baf3b4c021c4068573ade1050508319382b43",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDjHuJoSlxaePB4\noocep1Hhqy4DiXesLFtrNW7e751dc3vnPbD1aDuaoEr32obpqCsGfcNNweS+jEUV\nOy3eidjb1ZuzYs3/2Op7HVdw/CIvp7PvLOckjRdu6StbmuwcqJrNHki5/F38OMOC\nsMtGqAB4sHZQaXApLylNV54G+6EkpYDmM6keBrWw6RiQ4s6LJqnpVETJqyH95rlB\n4/Hti5lV6KFz1ts5MnYqGW0RXHAttCpENHvYCq2d4Ti2HWA+gSAGFWJFY9pVEz03\nMT1yXam0QxCkymYg95HbE0mdP/HjWIt3zFYYIyO2AWFhKyLeERjPhN7ac9SodB9z\nrc7gTx3DAgMBAAECggEAN+vsUkJw7+PUTdeyzlTjX92+pCdOXInFbqXG6UR1akOb\nj+nMLvidqGpsWw+m5VQ/V8dSdcxWbqZqAhrCpgcp6qLzRd1/nE3EGlE0rQCfyD0S\nHENhnEnTKb9mqhUAquPGzdd1j7m4SHiPhxfRzVFjYFQOpaj4cWOH11/J7K07VaKl\n0L5S0ZXLAwFBA7chBjn+VE1BCiUatvKYyBHwoRPDu8Bo0fZR7UyEJex/yh5oWGAu\np8Czgc26ot4FAYYOKMfQXJv6x1r3O7nDh4zE3tl9nHpozOk7BLdozhPWxPjwgqVk\nuYAV9+TX8Ek5JwuQk46CYc+iA3ssV6nJB4Kz/B+u2QKBgQD16FAdW6vLj9kupR4p\ndOzlk+1bZeC/Kcwc9eAARlR9MHTilx1RntySuMZibOcmTBioxh5SvezYkFdCKjLQ\n+S3dhPpxY80VsRdxCXWH23SSqoMVJAwq6KrTvolYy/YWP/dxSWSmQ56akhbpQDOW\nxd7gqrmhU9FlLWDhtjNfL+TBuQKBgQDscS7avipDmeAOxmmcE/bzuX2j64rJcLcC\nM2366vmS7sGn3lEiTFyThHqGeuO/MB8F+KrGyeauAilXZkrQx1ANiJBrpP95M3q8\nDBhue3N0RnCZZhL5N0MEani+7yJxR7sQmcevMiVdxa9p/z5DE1URJriiRcjm8beK\nWIssbwTJWwKBgQCQn+D+YzvWrPN+i34Bw9LP8wBWEMTtqRdysOjdQH/QYP9dhKKp\nrlTrteB3YrVPwNF/8YVEBI+XjszDDS512RcwgVUJ+zhS2aR/xqBpFpio6b/OXzUI\nx24wuo7suogw7c4JwrB/WKWfIux2olu1AQrj94TVbQZqCxY/qXjtMq3HgQKBgQCD\nLahZI/g+2Tg9+kbNmSYBwn+6Wgv+BtMCHZZ/B66/nkdC400QQl16Wp2/zp5cjE4p\n+fSFpa6eDATzwITxoCMB3yqBDmHO1Ijbm7pSUZuUfyApe0A7lDVSVd/3zqTFRI68\nfxUSVjf09qCDpmDcxfUENv9oyF7WAnVaBBXy6QU20QKBgAy9c1vNFHoNOaQXzjt8\n5HXZktOCqNsHKO//CIMYYTE5sDmcbIDKiU94ZHH23WEO9UyVLdTpUGrDhRHrxnQD\niBgDJLEXwww/GZ42ixxYlCA2KmVT1pVs7a8/5V/qP/wCn8Eq0v/u/G9Tw1HG7TI6\neUo3EA69hlWmEo0T0YRv0TYI\n-----END PRIVATE KEY-----\n",
      "client_email": "data-access@oauth2-demo-334509.iam.gserviceaccount.com",
      "client_id": "114481516406465407526",
      "type": "service_account"
    });
    var scopes = [  drive.DriveApi.driveScope,
      'https://www.googleapis.com/auth/spreadsheets'];

    AuthClient client = await clientViaServiceAccount(accountCredentials, scopes);

    return client;
  }



  saveData() async {
    final authHeaders = await account.authHeaders;

    //final authenticateClient = GoogleAuthClient(authHeaders);
    final authenticateClient = await obtainServiceCredentials();
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

    String uri;
    /*
    if( account.email == 'jssteux@gmail.com') {
     uri = '$_sheetsEndpoint$spreadsheetId/values/$encodedRange:append?valueInputOption=RAW';
    }
    else {
      */
       uri = '$_sheetsEndpoint$sheetFileId/values/$encodedRange:append?valueInputOption=RAW';
  /*
  }
  */

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
