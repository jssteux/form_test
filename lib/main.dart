import 'package:flutter/material.dart';
import 'form.dart';
import 'package:google_sign_in/google_sign_in.dart' as sign_in;
import 'package:googleapis/drive/v3.dart' as drive;

void main() {
  runApp(const MaterialApp(
    title: 'Navigation Basics',
    home: FirstRoute(),
  ));
}

class FirstRoute extends StatefulWidget {
  const FirstRoute({super.key});

  @override
  State<FirstRoute> createState() => _FirstRouteState();
}

class _FirstRouteState extends State<FirstRoute> {
  sign_in.GoogleSignInAccount? account;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Route'),
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(
            child: const Text('Auth'),
            onPressed: () async {
              final googleSignIn = sign_in.GoogleSignIn.standard(scopes: [drive.DriveApi.driveScope]);
              account = await googleSignIn.signIn();
              if( account != null) {

                /*
                final driveApi = drive.DriveApi(authenticateClient);


                drive.Drive? current;

                var drives = await driveApi.drives.list();
                if( drives.drives != null) {
                  var items = drives.drives;
                  if( items != null)  {
                  for (var item in items) {
                    if(item.name == "Forms")  {
                      current = item;
                    }
                  }
                  }
                }

                if( current != null) {

                  final Stream<List<int>> mediaStream =
                  Future.value([104, 105]).asStream().asBroadcastStream();
                  var media = drive.Media(mediaStream, 2);
                  var driveFile = drive.File();
                  driveFile.name = "hello_world.txt";

                    String? id = current.id!;
                    driveFile.parents = [id] ;
                    await driveApi.files.create(supportsAllDrives: true, driveFile, uploadMedia: media);
                    }
*/



              }
            },
          ),

        ElevatedButton(
          child: const Text('Open form'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SecondRoute(account!)),
            );
          },
        )]
      ),
    ),
    );
  }
}

class SecondRoute extends StatelessWidget {
  final sign_in.GoogleSignInAccount? account;

   const SecondRoute(  sign_in.GoogleSignInAccount this.account, {super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Route'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child:  MyCustomForm( account!)
        ),
      ),
    );
  }
}