import 'package:flutter/material.dart';
import 'google_auth_client.dart';
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
              final account = await googleSignIn.signIn();
              if( account != null) {
                final authHeaders = await account.authHeaders;
                final authenticateClient = GoogleAuthClient(authHeaders);
                final driveApi = drive.DriveApi(authenticateClient);


                final Stream<List<int>> mediaStream =
                Future.value([104, 105]).asStream().asBroadcastStream();
                var media = drive.Media(mediaStream, 2);
                var driveFile = drive.File();
                driveFile.name = "hello_world.txt";
                await driveApi.files.create(driveFile, uploadMedia: media);

              }
            },
          ),

        ElevatedButton(
          child: const Text('Open form'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SecondRoute()),
            );
          },
        )]
      ),
    ),
    );
  }
}

class SecondRoute extends StatelessWidget {
  const SecondRoute({super.key});

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
          child: const MyCustomForm()
        ),
      ),
    );
  }
}