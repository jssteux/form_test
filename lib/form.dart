import 'dart:io';

import 'package:flutter/material.dart';
import 'package:form_test/form_store.dart';
import 'package:intl/intl.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';
import 'package:google_sign_in/google_sign_in.dart' as sign_in;
import 'custom_image_widget.dart';
import 'image_widget.dart';



// Define a custom Form widget.
class MyCustomForm extends StatefulWidget {
  const MyCustomForm( sign_in.GoogleSignInAccount this.account,{super.key}) ;
  final sign_in.GoogleSignInAccount? account;


  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

// Define a corresponding State class.
// This class holds data related to the form.
class MyCustomFormState extends State<MyCustomForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.



  final _formKey = GlobalKey<FormState>();
  Map files = {};

  final ScrollController _scrollController = ScrollController();

  TextEditingController dateInputController = TextEditingController();

  _row(int index) {
    return Row(
      children: [
        Text('ID: $index'),
        const SizedBox(width: 30),
        Expanded(
          child: _comp(index),
        ),
      ],
    );
  }

  Widget _comp(int index) {
    if (index == 0) {
      return TextFormField(
        // The validator receives the text that the user has entered.
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter some text';
          }
          return null;
        },
      );
    } else if (index == 1) {
      return TextField(
          controller: dateInputController,
          decoration: const InputDecoration(
              icon: Icon(Icons.calendar_today), //icon of text field
              labelText: "Enter Date" //label text of field
              ),
          readOnly: true, // when true user cannot edit text
          onTap: () async {

            DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                //get today's date
                firstDate: DateTime(2000),
                //DateTime.now() - not to allow to choose before today.
                lastDate: DateTime(2102));

            if(pickedDate != null ){
              String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
              //you can implement different kind of Date Format here according to your requirement

              dateInputController.text = formattedDate;
            }

          });
    }

    else {
      return CustomImageFormField (
          (value) => {files[index] = value },
          files[ index]

      );

    }



  }

  List<Widget> buildWidgets() {
    List<Widget> widgets = [];
    for(int i=0; i<20;i++){
      widgets.add(_comp(i));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
        key: _formKey,
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
                controller: _scrollController,

                child:  Column(
                    children: buildWidgets(),

              ),
              ),
            ),
            bottomNavigationBar:
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                onPressed: () {
                  // Validate returns true if the form is valid, or false otherwise.
                  if (_formKey.currentState!.validate()) {
                    // If the form is valid, display a snackbar. In the real world,
                    // you'd often call a server or save the information in a database.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Processing Data')),
                    );

                    _formKey.currentState!.save();
                    FormStore store = FormStore(widget.account!);

                    files.forEach((key, file) { store.save(file);});


                  }


                },
                child: const Text('Submit2'),
              )
            ])));
  }
}
