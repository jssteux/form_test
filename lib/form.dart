import 'package:flutter/material.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

import 'image_widget.dart';

// Define a custom Form widget.
class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

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
  ScrollController _scrollController = ScrollController();

  _row(int index) {
    return Row(
      children: [
        Text('ID: $index'),
        SizedBox(width: 30),
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
          decoration: const InputDecoration(
              icon: Icon(Icons.calendar_today), //icon of text field
              labelText: "Enter Date" //label text of field
              ),
          readOnly: true, // when true user cannot edit text
          onTap: () async {

          });
    } else {
      return ImageWidget();
    }
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
              scrollbarFadeDuration: Duration(milliseconds: 500),
              // default : Duration(milliseconds: 300)
              scrollbarTimeToFade: Duration(milliseconds: 800),
              // default : Duration(milliseconds: 600)
              style: VsScrollbarStyle(
                hoverThickness: 10.0, // default 12.0
                radius: Radius.circular(10), // default Radius.circular(8.0)
                thickness: 10.0, // [ default 8.0 ]
                color: Colors.purple.shade900, // default ColorScheme Theme
              ),

              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: 5,
                scrollDirection: Axis.vertical,
                padding: EdgeInsets.all(16.0),
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _row(index);
                },
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
                  }
                },
                child: const Text('Submit2'),
              )
            ])));
  }
}
