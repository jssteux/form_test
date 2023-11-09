import 'package:flutter/material.dart';
import 'package:form_test/list.dart';
import 'package:form_test/logger.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'form_store.dart';
import 'form.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'src/sign_in_button.dart';
//import 'package:ensemble_ts_interpreter/parser/newjs_interpreter.dart';


/// The type of the onClick callback for the (mobile) Sign In Button.
typedef HandleSignInFn = Future<void> Function();


void main() {


  runApp(const MaterialApp(
    title: 'Navigation Basics',
    home: FirstRoute(),
  ));
}





test()  {
  /*
Map<String, dynamic> context = {
  'age': 9,
};

String code = """
      age = age + 1;
    """;
*/
//JSInterpreter.fromCode(code, context).evaluate();
//print ("calcul age");
//print (context['age']);
}


/// The scopes required by this application.
const List<String> scopes = <String>[
  'email',
  'https://www.googleapis.com/auth/contacts.readonly',
  drive.DriveApi.driveScope,
  'https://www.googleapis.com/auth/spreadsheets'
];

GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: scopes,
);


class FirstRoute extends StatefulWidget {

  const FirstRoute({super.key});

  @override
  State<FirstRoute> createState() => _FirstRouteState();
}






class _FirstRouteState extends State<FirstRoute> {
  GoogleSignInAccount? _account;
  late FormStore store;
  bool _isAuthorized = false; // has granted permissions?
  Logger logger = Logger();


  @override
  void initState() {
    super.initState();

    if( kIsWeb) {
      _googleSignIn = GoogleSignIn(
        // Optional clientId
        clientId: '114273143423-v83roghb06tj7c9tkjpap51b141s1mlq.apps.googleusercontent.com',
        scopes: scopes,
      );
    }

    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      // In mobile, being authenticated means being authorized...
      bool isAuthorized = account != null;
      // However, in the web...
      if (kIsWeb && account != null) {
        isAuthorized = await _googleSignIn.canAccessScopes(scopes);
      }

      setState(() {
        _account = account;
        _isAuthorized = isAuthorized;
      });

      // Now that we know that the user can access the required scopes, the app
      // can call the REST API.
      if (isAuthorized) {
        store = FormStore(account!, logger);
      }
    });

    // In the web, _googleSignIn.signInSilently() triggers the One Tap UX.
    //
    // It is recommended by Google Identity Services to render both the One Tap UX
    // and the Google Sign In button together to "reduce friction and improve
    // sign-in rates" ([docs](https://developers.google.com/identity/gsi/web/guides/display-button#html)).
    _googleSignIn.signInSilently();



  }




  // This is the on-click handler for the Sign In button that is rendered by Flutter.
  //
  // On the web, the on-click handler of the Sign In button is owned by the JS
  // SDK, so this method can be considered mobile only.

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      //print(error);
    }
  }

  // Prompts the user to authorize `scopes`.
  //
  // This action is **required** in platforms that don't perform Authentication
  // and Authorization at the same time (like the web).
  //
  // On the web, this must be called from an user interaction (button click).
  Future<void> _handleAuthorizeScopes() async {
    final bool isAuthorized = await _googleSignIn.requestScopes(scopes);
    setState(() {
      _isAuthorized = isAuthorized;
    });
    if (isAuthorized) {
      store = FormStore(_account!, logger);
    }
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  Widget _buildBody() {
    final GoogleSignInAccount? user = _account;
    if (user != null) {
      // The user is Authenticated
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ListTile(
            leading: GoogleUserCircleAvatar(
              identity: user,
            ),
            title: Text(user.displayName ?? ''),
            subtitle: Text(user.email),
          ),
          const Text('Signed in successfully.'),
          if (_isAuthorized) ...<Widget>[
              ElevatedButton(
              child: const Text('Mon formulaire'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FormRoute(store, -1)),
                );
              },
            ),ElevatedButton(
              child: const Text('Liste'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListRoute(store)),
                );
              },
            )
          ],
          if (!_isAuthorized) ...<Widget>[
            // The user has NOT Authorized all required scopes.
            // (Mobile users may never see this button!)
            const Text('Additional permissions needed to read your contacts.'),
            ElevatedButton(
              onPressed: _handleAuthorizeScopes,
              child: const Text('REQUEST PERMISSIONS'),
            ),
          ],
          ElevatedButton(
            onPressed: _handleSignOut,
            child: const Text('SIGN OUT'),
          ),
        ],
      );
    } else {
      // The user is NOT Authenticated
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text('You are not currently signed in.'),
          // This method is used to separate mobile from web code with conditional exports.
          // See: src/sign_in_button.dart
          if( kIsWeb) ...<Widget>[
            buildSignInButton(
              onPressed: _handleSignIn,
            ),],

          if( !kIsWeb) ...<Widget>[
          ElevatedButton(
          onPressed: _handleSignIn,
          child: const Text('Auth'),
          ),]
        ],
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Google Sign In'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }

}

class FormRoute extends StatelessWidget {
  final FormStore store;
  final int index;

   const FormRoute(  this.store, this.index, {super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulaire saisie'),
      ),
      body: Center(
          child:  MyCustomForm( store, index)
        ),

    );
  }
}


class ListRoute extends StatelessWidget {
  final FormStore store;

  const ListRoute(  this.store, {super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste'),
      ),
      body: Center(
            child:  MyCustomList( store)

      ),
    );
  }
}
