import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class CustomImageFormFieldWeb extends FormField<Uint8List?> {

  CustomImageFormFieldWeb(FormFieldSetter<Uint8List> onSaved,
      Uint8List? initialValue, {super.key}) : super(
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
                    Uint8List bytes = file.files.first.bytes!;
                    formFieldState.didChange(bytes);
                  }
                },
              ),
            ]
        );

        if (formFieldState.value != null) {
          c.children.add(Image.memory(formFieldState.value!));
          //print('refresh');
        }


        return c;
      });
}


