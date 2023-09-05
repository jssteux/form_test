import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:form_test/form_store.dart';
import 'package:intl/intl.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';
import 'package:google_sign_in/google_sign_in.dart' as sign_in;
import 'custom_image_widget.dart';
import 'custom_image_widget_web.dart';
import 'image_widget.dart';


// Define a custom Form widget.
class MyCustomForm extends StatefulWidget {
  const MyCustomForm(this.store,this.index, {super.key}) ;
  final FormStore store;
  final int index;

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

  Map<String, String> initialValues= {};

  final _formKey = GlobalKey<FormState>();
  Map files = {};
  Map<String, TextEditingController> controllers = {};


  final ScrollController _scrollController = ScrollController();

  TextEditingController dateInputController = TextEditingController();

  _row(int formIndex) {
    return Row(
      children: [
        Text('ID: $formIndex'),
        const SizedBox(width: 30),
        Expanded(
          child: _comp(formIndex),
        ),
      ],
    );
  }

  Widget _comp(int formIndex) {
    if (formIndex == 0) {
      var myController = TextEditingController(text : initialValues["NOM"]);
      controllers.putIfAbsent("NOM", () => myController);
      var textField = TextFormField(
        controller: myController,
        // The validator receives the text that the user has entered.
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter some text';
          }
          return null;
        },

      );
      return textField;
    } else if (formIndex == 1) {
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
      if( kIsWeb) {
      return CustomImageFormFieldWeb (
          (value) => {files[formIndex] = value },
          files[ formIndex]
      );} else  {
        return CustomImageFormField (
                (value) => {files[formIndex] = value },
            files[ formIndex]
        );
      }

    }



  }

  List<Widget> buildWidgets() {
    List<Widget> widgets = [];
    for(int i=0; i<5;i++){
      widgets.add(_comp(i));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return FutureBuilder<List<Map<String, String>>>(
        future: widget.store.loadData(),
    builder: (context, AsyncSnapshot<List<Map<String, String>>> snapshot) {
    if (snapshot.hasData) {
      if( widget.index!= -1) {
        initialValues = snapshot.data!.elementAt(widget.index);
      }



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
                onPressed: ()  {
                  // Validate returns true if the form is valid, or false otherwise.
                  if (_formKey.currentState!.validate()) {
                    // If the form is valid, display a snackbar. In the real world,
                    // you'd often call a server or save the information in a database.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Processing Data')),
                    );

                    _formKey.currentState!.save();

                    files.forEach((key, file) { if( file is Uint8List) {
                      widget.store.saveImage(file);
                    } else {
                      widget.store.save(file);
                    }
                    }
                    );

                    Map<String, String> formValues = {};
                    if( initialValues["ID"] != null) {
                      formValues.putIfAbsent("ID", () => initialValues["ID"]!);
                    }
                    formValues.putIfAbsent("NOM", () => controllers["NOM"]!.text);


                    widget.store.saveData(widget.index,formValues);

                    Navigator.pop(context, true);
                  }


                },
                child: const Text('Submit2'),
              )
            ])));} else {return const CircularProgressIndicator();} });
  }
}
