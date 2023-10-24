import 'dart:io';
import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:form_test/custom_image_state.dart';

class CustomImageFormFieldWeb extends FormField<CustomImageState?> {

  CustomImageFormFieldWeb(FormFieldSetter<CustomImageState> onSaved,
      CustomImageState? initialValue, {super.key}) : super(
      onSaved: onSaved,
      initialValue: initialValue,
      builder: (formFieldState) {

        Column c = Column(
            children: [

              MaterialButton(
                color: Colors.blue,
                child: const Text(
                    "Pick Image from Camera (form field)",
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold
                    )
                ),
                onPressed: () async {
                  FilePickerResult? file = await FilePicker.platform
                      .pickFiles(type: FileType.image, allowMultiple: false);
                  if (file != null) {
                    File? pickedFile = File(file.files.first.name!);
                    Uint8List bytes = file.files.first.bytes!;
                    formFieldState.didChange( CustomImageState(true,  bytes));

                  }
                },
              ),
            ]
        );


        if (formFieldState.value != null) {
          Uint8List? content = formFieldState.value!.content;
          if( content != null) {
            c.children.add(Image.memory(content));
          }
        }


        return c;
      });
}


