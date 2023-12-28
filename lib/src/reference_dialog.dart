import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:form_test/src/store/front/front_store.dart';
import 'package:form_test/src/store/front/sheet.dart';

class ReferenceDialog extends StatefulWidget {
  final FrontStore store;
  final String columnReference;
  final Function( FormSuggestionItem) onSelect;

  const ReferenceDialog(this.store, this.columnReference, this.onSelect , {super.key});

  @override
  ReferenceDialogState createState() {
    return ReferenceDialogState();
  }
}

// Define a corresponding State class.
// This class holds data related to the form.
class ReferenceDialogState extends State<ReferenceDialog> {

  final _formKey = GlobalKey<FormState>();
  bool closed = false;


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
          autofocus: true

        ),
        suggestionsCallback: (pattern) async {
          // Replace with your backend call to get suggestions
          List<FormSuggestionItem> suggestions = await widget.store
              .getSuggestions(widget.columnReference, pattern);
          return suggestions;
        },
        itemBuilder: (context, suggestion) {
          // Customize each suggestion item here
          return ListTile(
            title: Text(suggestion.displayName),


          );
        },
        onSuggestionSelected: (suggestion) {
          closed = true;
          widget.onSelect(suggestion);
          Navigator.of(context).pop();

        },
        onSuggestionsBoxToggle: (isOpen) async {

          // To handle close if keyboard is hidden
          if (isOpen == false) {
            if( closed == false) {
              Navigator.of(context).pop();
            }
          }

          if (isOpen == true) {
            myController.text = "";
          }
        },

        animationDuration: const Duration(milliseconds: 0)

    ));

    return widgets;
  }


  @override
  Widget build(BuildContext context) {
    return TapRegion( onTapOutside: (tap) { closed = true;}, child:Dialog(child: Form(key: _formKey, child: Column(
        children: buildWidget(),
      ),
    ),));
  }
}
