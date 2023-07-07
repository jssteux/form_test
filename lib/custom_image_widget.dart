import 'dart:io';


import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class CustomImageFormField extends FormField<File?> {

  CustomImageFormField(FormFieldSetter<File> onSaved,
      File? initialValue, {super.key}) : super(
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
                    File? pickedFile = File(file.files.first.path!);
                    formFieldState.didChange(pickedFile);
                  }
                },
              ),
            ]
        );

        if (formFieldState.value != null) {
          c.children.add(Image.file(formFieldState.value!));
        }

        print('refresh');
        return c;
      });
}


