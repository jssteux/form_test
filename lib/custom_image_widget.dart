import 'dart:io';
import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:form_test/custom_image_state.dart';
import 'package:form_test/form_store.dart';

class CustomImageFormField extends FormField<CustomImageState?> {


  final FormStore store;
  final String label;



  CustomImageFormField(FormFieldSetter<CustomImageState> onSaved,
      this.store,
      CustomImageState? initialValue,
      this.label,

      {super.key, super.validator,super.autovalidateMode}) : super(
      onSaved: onSaved,
      initialValue: initialValue,
      builder: (formFieldState) {

        Widget? child;

        if (formFieldState.value != null) {
          Uint8List? content = formFieldState.value!.content;
          if( content != null) {
            child = Image.memory(content);
          }
        }

        child ??= Container();

        Column c = Column(
            children: [

         InputDecorator(decoration: InputDecoration(
          suffixIcon:
            SizedBox(
            width: 100,
            child: Row(children: [
              const Spacer(),
                IconButton(
                  onPressed: () async {
                    FilePickerResult? file = await FilePicker.platform
                        .pickFiles(type: FileType.image, allowMultiple: false);
                    if (file != null) {
                      File? pickedFile = File(file.files.first.path!);
                      formFieldState.didChange( CustomImageState(true, await pickedFile.readAsBytes()));
                    }
                  },
                  icon: const Icon(Icons.image),
                ),
              IconButton(
                onPressed: () async {
                  formFieldState.didChange(  CustomImageState(true, null));
                },
                icon: const Icon(Icons.clear),
              ),

            ])),
            labelText: label, //label text of field

            errorText: formFieldState.errorText

            ),
            child: child

          )
        ]);



        return c;
      });


}


