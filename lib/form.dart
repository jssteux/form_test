import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:form_test/column_descriptor.dart';
import 'package:form_test/custom_image_state.dart';
import 'package:form_test/form_descriptor.dart';
import 'package:form_test/form_store.dart';
import 'package:form_test/main.dart';
import 'package:form_test/row.dart';
import 'package:form_test/src/reference_dialog.dart';
import 'package:intl/intl.dart';
import 'custom_image_widget.dart';
import 'custom_image_widget_web.dart';

// Define a custom Form widget.
class MyCustomForm extends StatefulWidget {
  const MyCustomForm(this.store, this.sheetName, this.rowIndex, this.context,
      {super.key});
  final FormStore store;
  final String sheetName;
  final int rowIndex;
  final Context context;

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
  late List<FormDescriptor> forms;
  Map<String, String> referencesValues = {};
  Map<String, String> referenceLabels = {};
  final _formKey = GlobalKey<FormState>();
  Map<String, FocusNode> focusNodes = {};

  Map<String, TextEditingController> controllers = {};

  final ScrollController _scrollController = ScrollController();

  _row(int formIndex) {
    return _comp(formIndex);
  }

  @override
  void initState() {
    for (var columName in focusNodes.keys) {
      focusNodes[columName]!.dispose();
    }
    super.initState();
  }




  Widget _comp(int formIndex) {
    String columnName = columns.keys.elementAt(formIndex);
    ColumnDescriptor columDescriptor = columns[columnName]!;

    if (columDescriptor.reference.isNotEmpty) {
      var myController =
          TextEditingController(text: referenceLabels[columnName]);
      controllers.putIfAbsent(columnName, () => myController);
      var textField = TextFormField(
          controller: myController,
          readOnly: true,
          // The validator receives the text that the user has entered.
          validator: (value) {
            if (formIndex == 1) {
              if (columDescriptor.mandatory) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
              }
            }
            return null;
          },
          decoration: InputDecoration(
              suffixIcon: SizedBox(
                  width: 100,
                  child: Row(children: [
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        await showDialog(
                            context: context,
                            builder: (BuildContext context) => ReferenceDialog(
                                    widget.store, columDescriptor.reference,
                                    (suggestion) {
                                  myController.text = suggestion.displayName;
                                  referencesValues[columnName] = suggestion.ref;
                                }));
                      },
                      icon: const Icon(Icons.search),
                    ),
                    IconButton(
                      onPressed: () async {
                        myController.text = "";
                        referencesValues[columnName] = "";
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ])),
              labelText: columDescriptor.label //label text of field
              ));
      return textField;
    } else if (columDescriptor.type == "STRING") {
      var myController = TextEditingController(text: initialValues[columnName]);

      controllers.putIfAbsent(columnName, () => myController);
      focusNodes[columnName] = FocusNode();
      var textField = TextFormField(
          controller: myController,
          focusNode: focusNodes[columnName],
          // The validator receives the text that the user has entered.
          validator: (value) {
            if (formIndex == 1) {
              if (columDescriptor.mandatory) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
              }
            }
            return null;
          },
          decoration: InputDecoration(
              suffixIcon: SizedBox(
                  width: 100,
                  child: Row(children: [
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        focusNodes[columnName]!.unfocus();
                        myController.text = "";
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ])),
              labelText: columDescriptor.label //label text of field
              ));
      return textField;
    } else if (columDescriptor.type == "DATE") {
      var myController = TextEditingController(text: initialValues[columnName]);
      controllers.putIfAbsent(columnName, () => myController);
      focusNodes[columnName] = FocusNode();
      return TextFormField(
          controller: myController,
          focusNode: focusNodes[columnName],
          decoration: InputDecoration(
              suffixIcon: SizedBox(
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
                      onPressed: () {
                        focusNodes[columnName]!.unfocus();
                        myController.text = "";
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ])),
              labelText: columDescriptor.label //label text of field
              ),
          //readOnly: true, // when true user cannot edit text
          validator: (value) {
            if (columDescriptor.mandatory) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              } else {
                try {} catch (e) {
                  return 'incorrect date format';
                }
              }
            }
            return null;
          });
    } else if (columDescriptor.type == "GOOGLE_IMAGE") {
      if (kIsWeb) {
        return CustomImageFormFieldWeb(
          (value) => files[formIndex.toString()] = value!,
          widget.store,
          CustomImageState(false, initialValues[columnName], null),
          columDescriptor.label,
          validator: (value) {
            if (columDescriptor.mandatory) {
              if (value == null || value.content == null) {
                return 'Please enter a picture';
              } else {
                try {} catch (e) {
                  return 'incorrect date format';
                }
              }
            }

            return null;
          },
        );
      } else {
        return CustomImageFormField(
          (value) => {
            if (value != null) files[formIndex.toString()] = value else null
          },
          widget.store,
          CustomImageState(false, initialValues[columnName], null),
          columDescriptor.label,
          validator: (value) {
            if (columDescriptor.mandatory) {
              if (value == null || value.content == null) {
                return 'Please enter a picture';
              } else {
                try {} catch (e) {
                  return 'incorrect date format';
                }
              }
            }

            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
        );
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

  List<PopupMenuItem> buildForms() {
    List<PopupMenuItem> widgets = [];
    for (var i = 0; i < forms.length; i++) {
      var form = forms[i];
      widgets.add(PopupMenuItem<ListRoute>(
          value: ListRoute(widget.store, widget.sheetName, i,
              Context(widget.sheetName, initialValues["ID"]), form.label),
          child: Text(form.label)));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    //print('build');
    // Build a Form widget using the _formKey created above.
    return FutureBuilder<DatasRow>(
        future: widget.store
            .loadRow(widget.sheetName, widget.rowIndex, widget.context),
        builder: (context, AsyncSnapshot<DatasRow> snapshot) {
          if (snapshot.hasData) {
            columns = snapshot.data!.columns;
            forms = snapshot.data!.formDescriptors;

            initialValues = snapshot.data!.datas;

            files = snapshot.data!.files;

            // references
            for (int i = 0; i < columns.length; i++) {
              String columnName = columns.keys.elementAt(i);
              ColumnDescriptor columDescriptor = columns[columnName]!;

              if (columDescriptor.reference.isNotEmpty) {
                if (snapshot.data!.datas[columnName] != null) {
                  referencesValues[columnName] =
                      snapshot.data!.datas[columnName]!;
                } else {
                  referencesValues[columnName] = "";
                }
              }
            }

            referenceLabels = snapshot.data!.initialsReferenceLabels;

            return Form(
                key: _formKey,
                // Without out this, pop in appBar has a blink effect due to keyboard
                // height if the focus is set on a text field
                child : WillPopScope(onWillPop: () async {

                  FocusScope.of(context).unfocus();
                  await Future.delayed(const Duration(milliseconds: 300));

                  return true;
                },

                child:
              Scaffold(
                resizeToAvoidBottomInset: false,
                  body: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: buildWidgets(),
                        )),
                  ),
                  bottomNavigationBar: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        (forms.isNotEmpty)
                            ? PopupMenuButton(
                                itemBuilder: (BuildContext context) {
                                return buildForms();
                              }, onSelected: (result) {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => result));
                              })
                            : Spacer(),

                        Container(
                            margin: EdgeInsets.only(right: 15),
                            child: ElevatedButton(
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
                                    String columnName =
                                        columns.keys.elementAt(i);
                                    ColumnDescriptor columDescriptor =
                                        columns[columnName]!;

                                    if (columDescriptor.reference.isNotEmpty) {
                                      formValues.putIfAbsent(columnName,
                                          () => referencesValues[columnName]!);
                                    } else if (columDescriptor.type ==
                                            "STRING" ||
                                        columDescriptor.type == "DATE") {
                                      formValues.putIfAbsent(columnName,
                                          () => controllers[columnName]!.text);
                                    } else if (columDescriptor.type ==
                                        "GOOGLE_IMAGE") {
                                      if (initialValues[columnName] != null) {
                                        formValues.putIfAbsent(columnName,
                                            () => initialValues[columnName]!);
                                      }
                                    }
                                  }

                                  widget.store.saveData(
                                      context,
                                      widget.sheetName,
                                      formValues,
                                      columns,
                                      files);
                                }
                              },
                              child: const Padding(
                                  padding: EdgeInsets.only(left: 20, right: 20),
                                  child: Text('Save')),
                            )),
                      ]),
                )));
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}
