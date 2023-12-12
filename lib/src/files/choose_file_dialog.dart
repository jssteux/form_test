import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:form_test/form_store.dart';
import 'package:form_test/sheet.dart';
import 'package:form_test/src/files/file_item.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:vs_scrollbar/vs_scrollbar.dart';

class ChooseFileDialog extends StatefulWidget {
  final FormStore store;
  final Function(FileItem) onSelect;

  const ChooseFileDialog(this.store, this.onSelect, {super.key});



  @override
  ChooseFileDialogState createState() {
    return ChooseFileDialogState();
  }
}

// Define a corresponding State class.
// This class holds data related to the form.
class ChooseFileDialogState extends State<ChooseFileDialog> {
  final _formKey = GlobalKey<FormState>();



  List<Widget> buildWidget() {
    List<Widget> widgets = [];

    var myController = TextEditingController(text: "");
    widgets.add(TypeAheadFormField(
        suggestionsBoxDecoration: const SuggestionsBoxDecoration(
            hasScrollbar: true,
            color: Colors.white,
            shadowColor: Colors.transparent
          //constraints: BoxConstraints(minHeight: 1000)
        ),
        textFieldConfiguration: TextFieldConfiguration(
            controller: myController,
            autofocus: true,
          decoration: const InputDecoration(contentPadding: EdgeInsets.only(left:15))


        ),
        suggestionsCallback: (pattern) async {
          // Replace with your backend call to get suggestions
          List<FileItem> suggestions = await widget.store
              .allFileList(pattern);
          return suggestions;
        },
        itemBuilder: (context, file) {
          // Customize each suggestion item here
          return SizedBox(height: 60,child:  ListTile(
            title: Text(file.name ),
            subtitle : Row(children: [ Flexible(child:Text(file.path, overflow: TextOverflow.ellipsis))]),
              minVerticalPadding: 20
          ));
        },
        onSuggestionSelected: (suggestion) {
          widget.onSelect(suggestion);
          Navigator.of(context).pop();
        },

        animationDuration: const Duration(milliseconds: 0)

    ));

    return widgets;
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(child: Form(key: _formKey, child: Column(
      children: buildWidget(),
    ),
    ),);
  }
}
