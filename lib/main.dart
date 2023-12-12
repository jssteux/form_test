import 'package:flutter/material.dart';
import 'package:form_test/form_descriptor.dart';
import 'package:form_test/list.dart';
import 'package:form_test/logger.dart';
import 'package:form_test/src/files/choose_file_dialog.dart';
import 'package:form_test/src/files/file_item.dart';

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

test() {
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
  FormStore? store;
  bool _isAuthorized = false; // has granted permissions?
  Logger logger = Logger();
  late List<FormDescriptor>? forms;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _googleSignIn = GoogleSignIn(
        // Optional clientId
        clientId:
            '114273143423-v83roghb06tj7c9tkjpap51b141s1mlq.apps.googleusercontent.com',
        scopes: scopes,
      );
    }

    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
/*
      await Future.delayed(Duration(seconds: 5));
      print('delay');
*/
      // In mobile, being authenticated means being authorized...
      bool isAuthorized = account != null;
      // However, in the web...
      if (kIsWeb && account != null) {
        isAuthorized = await _googleSignIn.canAccessScopes(scopes);
      }

      // Now that we know that the user can access the required scopes, the app
      // can call the REST API.

      if (isAuthorized) {
        store = FormStore(account!, logger);
        _account = account;
        _isAuthorized = isAuthorized;
      }

      setState(() {

      });
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

      if (isAuthorized) {
        store = FormStore(_account!, logger);
      }


    });
  }

  _handleSignOut() {
    _googleSignIn.disconnect();
    setState(() {
      _account = null;
      _isAuthorized = false;
      store = null;
    });
  }

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
          if (_isAuthorized && store!.spreadSheet == null) ...<Widget>[
            IconButton(
                onPressed: () async {
                  await showDialog(
                      context: context,
                      builder: (BuildContext context) =>
                          ChooseFileDialog(store!, (file) async {
                            // Init store
                            store = FormStore(_account!, logger);
                            store!.spreadSheet = file;
                            forms = await store!.getForms();

                            setState(() {});
                          }));
                },
                icon: const Icon(Icons.search)),
          ],
          if (_isAuthorized && store!.spreadSheet != null) ...<Widget>[
            Row(
              children: [

                Expanded(child: Align(alignment: Alignment.centerRight   ,child:Padding(
    padding: const EdgeInsets.all(8.0), child: Text("Active Google Sheet")))),

                Expanded(child: Align(alignment: Alignment.centerLeft   ,child:Padding(
                    padding: const EdgeInsets.all(8.0), child: Row(children:[Text(
                  store!.spreadSheet!.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
                  ,
                  IconButton(
                      onPressed: () async {
                        setState(() {
                          store!.spreadSheet = null;
                          forms = null;
                        });
                      },
                      icon: const Icon(Icons.grid_off_sharp))],)))),
              ],
            ),
            Row(children: [Expanded(child:Column(children: getForms()))])
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
          if (kIsWeb) ...<Widget>[
            buildSignInButton(
              onPressed: _handleSignIn,
            ),
          ],

          if (!kIsWeb) ...<Widget>[
            ElevatedButton(
              onPressed: _handleSignIn,
              child: const Text('Auth'),
            ),
          ]
        ],
      );
    }
  }

  List<Widget> getForms() {
    List<Widget> widgets = [];

    List<Widget> inners=[];

    if (forms != null) {
      for (int formIndex = 0; formIndex < forms!.length; formIndex++) {

        FormDescriptor form = forms![formIndex];


        int indice = formIndex % 2;
        Alignment? align;
        if( indice == 0)  {
          align = Alignment.centerRight;
        } else  {
          align = Alignment.centerLeft;
        }

        Widget inner = Expanded(child:Align(
            alignment: align, child:Column(children: [SizedBox(width: 180, child: Card(
            elevation: 2,
            margin:
                const EdgeInsets.only(top: 15, bottom: 15, left: 8, right: 8),
            child: TextButton(
              child: Text(form.label),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ListRoute(store!, null, formIndex,
                          const Context(null, null), form.label)),
                );
              },
            )))])));



        // reinit
        if( indice == 0)  {
          if( inners.isNotEmpty) {

            widgets.add(Row (children: inners,));

          }
          inners = [];
        }

        inners.add(inner);
        }
       }


    if( inners.isNotEmpty) {
      widgets.add(Row (children: inners,));
    }


    return widgets;
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
        ),
        bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          if (_account != null) ...<Widget>[
            ElevatedButton(

              onPressed: _handleSignOut,
              child: const Text('Signout'),
            ),
          ],


        ]),

    );
  }
}

class FormRoute extends StatelessWidget {
  final FormStore store;
  final Context context;
  final String sheetName;
  final int rowIndex;

  const FormRoute(this.store, this.sheetName, this.rowIndex, this.context,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulaire saisie'),
      ),
      body:
          Center(child: MyCustomForm(store, sheetName, rowIndex, this.context)),
    );
  }
}

class Context {
  final String? sheetName;
  final String? sheetItemID;

  const Context(this.sheetName, this.sheetItemID);
}

class ListRoute extends StatelessWidget {
  final FormStore store;
  final String label;
  final String? sheetName;
  final int formIndex;
  final Context context;

  const ListRoute(
      this.store, this.sheetName, this.formIndex, this.context, this.label,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(label),
        ),
        body: Center(
            child: MyCustomList(store, sheetName, formIndex, this.context)));
  }
}
