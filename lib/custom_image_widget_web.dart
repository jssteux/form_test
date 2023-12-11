import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:form_test/custom_image_state.dart';

class CustomImageFormFieldWeb extends FormField<CustomImageState?> {

  final String label;

  CustomImageFormFieldWeb(FormFieldSetter<CustomImageState> onSaved,
      CustomImageState? initialValue,  this.label, {super.key}) : super(
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
                            Uint8List bytes = file.files.first.bytes!;
                            formFieldState.didChange( CustomImageState(true,  null, bytes));

                          }
                        },
                        icon: const Icon(Icons.image),
                      ),
                      IconButton(
                        onPressed: () async {
                          formFieldState.didChange(  CustomImageState(true, null, null));
                        },
                        icon: const Icon(Icons.clear),
                      ),

                    ])),
                labelText: "Image", //label text of field
              ),
                  child: child

              )
            ]);



        return c;


      });
}


