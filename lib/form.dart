import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:form_test/column_descriptor.dart';
import 'package:form_test/custom_image_state.dart';
import 'package:form_test/form_store.dart';
import 'package:form_test/row.dart';
import 'package:intl/intl.dart';
import 'custom_image_widget.dart';
import 'custom_image_widget_web.dart';

// Define a custom Form widget.
class MyCustomForm extends StatefulWidget {
  const MyCustomForm(this.store, this.index, {super.key});
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

  Map<String, String> initialValues = {};
  late Map<String, CustomImageState> files;
  late bool autofocusInit;
  late LinkedHashMap<String, ColumnDescriptor> columns;

  final _formKey = GlobalKey<FormState>();

  Map<String, TextEditingController> controllers = {};

  final ScrollController _scrollController = ScrollController();

  _row(int formIndex) {
    return _comp(formIndex);
  }

  Widget _comp(int formIndex) {
    String columnName = columns.keys.elementAt(formIndex);
    ColumnDescriptor columDescriptor = columns[columnName]!;
    String label = formIndex.toString();

    if (columDescriptor.type == "STRING") {
      var myController = TextEditingController(text: initialValues[columnName]);
      controllers.putIfAbsent(columnName, () => myController);
      var textField = TextFormField(
          controller: myController,
          // The validator receives the text that the user has entered.
          validator: (value) {
            if( formIndex == 1) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
            }
            return null;
          },
          decoration:  InputDecoration(
              labelText: columDescriptor.label//label text of field
          )

      );
      return textField;
    } else if (columDescriptor.type == "DATE") {
      var myController = TextEditingController(text: initialValues[columnName]);
      controllers.putIfAbsent(columnName, () => myController);
      return TextFormField(
          controller: myController,
          decoration: InputDecoration(
              suffixIcon:
              SizedBox(
                  width: 100,
                  child: Row(children: [

                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        DateTime initialDate;
                        if (initialValues[columnName] != null) {
                          try {
                            initialDate = DateFormat('yyyy-MM-dd')
                                .parse(initialValues[columnName]!);
                          } catch (e) {
                            initialDate = DateTime.now();
                          }
                        } else {
                          initialDate = DateTime.now();
                        }

                        DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            //get today's date
                            firstDate: DateTime(1900),
                            //DateTime.now() - not to allow to choose before today.
                            lastDate: DateTime.now());

                        if (pickedDate != null) {
                          String formattedDate =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                          //you can implement different kind of Date Format here according to your requirement

                          myController.text = formattedDate;
                        }
                      },
                      icon: const Icon(Icons.today),
                    ),

                    IconButton(
                      onPressed: () async {
                        myController.text = "";
                      },
                      icon: const Icon(Icons.clear),
                    ),

                  ])),

              labelText: columDescriptor.label //label text of field
          ),
          //readOnly: true, // when true user cannot edit text
          validator: (value) {

            if (value == null || value.isEmpty) {
              return 'Please enter some text';
            } else {
              try {} catch (e) {
                return 'incorrect date format';
              }
            }
            return null;
          }
      )
    ;
    } else if (columDescriptor.type == "GOOGLE_IMAGE") {
      if (kIsWeb) {
        return CustomImageFormFieldWeb(
                (value) => files[formIndex.toString()] = value!,

            files[formIndex.toString()],
            columDescriptor.label
        );
      } else {

            return CustomImageFormField(
                (value) => {
              if (value != null)
                files[formIndex.toString()] = value
              else
                null
            },
            widget.store,
            files[formIndex.toString()],
              columDescriptor.label,
            validator: (value) {

              if (value == null || value.content == null) {
                return 'Please enter a picture';
              } else {
                try {} catch (e) {
                  return 'incorrect date format';
                }
              }

              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,);


      }
    } else {
       return const Text("");
    }
  }

  List<Widget> buildWidgets() {
    List<Widget> widgets = [];
    for (int i = 0; i < columns.length; i++) {
      widgets.add(_row(i));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    //print('build');
    // Build a Form widget using the _formKey created above.
    return FutureBuilder<DatasRow>(
        future: widget.store.loadRow(widget.index),
        builder: (context, AsyncSnapshot<DatasRow> snapshot) {
          if (snapshot.hasData) {
            columns = snapshot.data!.columns;

            if (widget.index != -1) {
              initialValues = snapshot.data!.datas;
            }

            files = snapshot.data!.files;

            return Form(
                key: _formKey,
                child: Scaffold(
                    body: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: buildWidgets(),
                      ),
                    ),
                    bottomNavigationBar: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Validate returns true if the form is valid, or false otherwise.
                              if (_formKey.currentState!.validate()) {
                                // If the form is valid, display a snackbar. In the real world,
                                // you'd often call a server or save the information in a database.
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Processing Data')),
                                );

                                _formKey.currentState!.save();

                                Map<String, String> formValues = {};
                                if (initialValues["ID"] != null) {
                                  formValues.putIfAbsent(
                                      "ID", () => initialValues["ID"]!);
                                }

                                for (int i = 0; i < columns.length; i++) {
                                  String columnName = columns.keys.elementAt(i);
                                  ColumnDescriptor columDescriptor =
                                  columns[columnName]!;

                                  if (columDescriptor.type == "STRING" ||
                                      columDescriptor.type == "DATE") {
                                    formValues.putIfAbsent(columnName,
                                            () => controllers[columnName]!.text);
                                  }

                                  if (columDescriptor.type == "GOOGLE_IMAGE") {
                                    if (initialValues[columnName] != null) {
                                      formValues.putIfAbsent(columnName,
                                              () => initialValues[columnName]!);
                                    }
                                  }
                                }

                                widget.store.saveData(
                                    context, formValues, columns, files);
                              }
                            },
                            child: const Text('Submit2'),
                          )
                        ])));
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}
