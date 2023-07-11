import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:form_test/form_store.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';
import 'package:google_sign_in/google_sign_in.dart' as sign_in;



// Define a custom Form widget.
class MyCustomList extends StatefulWidget {
  const MyCustomList( this.store,{super.key}) ;
  final FormStore store;

  @override
  MyCustomListState createState() {
    return MyCustomListState();
  }
}

// Define a corresponding State class.
// This class holds data related to the form.
class MyCustomListState extends State<MyCustomList> {

  final ScrollController _scrollController = ScrollController();

  late List<Map<String,String>> _items ;

  Widget _comp(int index) {


    return ListTile(
      title: Row(
          children: <Widget>[
            Expanded(child: Text(_items.elementAt(index)['NOM']!)),
            Expanded(child: Text(_items.elementAt(index)['PRENOM']!)),
          ]
      ));
/*
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => setState(() {
          _items.removeAt(index);
        }),
      ),
    );
 */
  }


  List<Widget> buildWidgets() {
    List<Widget> widgets = [];


    for(int i=0; i<_items.length;i++){
      widgets.add(_comp(i));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.

   return FutureBuilder<List<Map<String,String>>>(
       future: widget.store.loadData(),
       builder: (context, AsyncSnapshot<List<Map<String,String>>> snapshot) {
         if (snapshot.hasData) {
           _items = snapshot.data!;
           return Form(

               child: Scaffold(
                 body: VsScrollbar(
                   controller: _scrollController,
                   showTrackOnHover: true,
                   // default false
                   isAlwaysShown: true,
                   // default false
                   scrollbarFadeDuration: const Duration(milliseconds: 500),
                   // default : Duration(milliseconds: 300)
                   scrollbarTimeToFade: const Duration(milliseconds: 800),
                   // default : Duration(milliseconds: 600)
                   style: VsScrollbarStyle(
                     hoverThickness: 10.0, // default 12.0
                     radius: const Radius.circular(12), // default Radius.circular(8.0)
                     thickness: 10.0, // [ default 8.0 ]
                     color: Colors.purple.shade900, // default ColorScheme Theme
                   ),

                   child: SingleChildScrollView(
                     key: Key(_items.length.toString()),
                     controller: _scrollController,

                     child:  Column(
                       children: buildWidgets(),

                     ),
                   ),
                 ),));
         } else {
           return const CircularProgressIndicator();

         }
       }
   );

  }
}
