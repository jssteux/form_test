import 'dart:io';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart' as sign_in;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart';

import 'google_auth_client.dart';

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
      var stream = ByteStream.fromBytes( bytes);

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




}
