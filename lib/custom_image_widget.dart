import 'dart:io';
import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:form_test/custom_image_state.dart';
import 'package:form_test/src/store/front/front_store.dart';

class CustomImageFormField extends FormField<CustomImageState?> {


  final FrontStore store;
  final String label;



  CustomImageFormField(FormFieldSetter<CustomImageState> onSaved,
      this.store,
      CustomImageState? initialValue,
      this.label,

      {super.key, super.validator,super.autovalidateMode}) : super(
      onSaved: onSaved,
      initialValue: initialValue,
      builder: (formFieldState)  {

        const double imageHeight = 290;

        Widget? child;


        if (formFieldState.value !=  null) {
          Uint8List? content = formFieldState.value!.content;
          if( content != null) {
            child = SizedBox( height: imageHeight, child: Image.memory(content));
          } else  {
            if (formFieldState.value!.url != null && formFieldState.value!.url!.isNotEmpty) {
              Future.delayed(const Duration(seconds: 0), () async {
                Uint8List? img = await store.loadImage(formFieldState.value!.url);
                if( img != null) {
                  formFieldState.didChange(CustomImageState(
                      false, formFieldState.value!.url,
                      img));
                } else  {
                  ByteData datas = await rootBundle.load('images/image-not-found.png');


                  formFieldState.didChange(CustomImageState(
                      false, null,datas.buffer.asUint8List()));
                }
              });
              child = const Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  SizedBox(
                  height: 20.0,
                  width: 20.0,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2,)
                    )),
                  ]

                  )
              );
            }
          }
       }



        child ??= Container();

        Column c = Column(
            children: [

         InputDecorator(decoration: InputDecoration(
          suffixIcon:
          SizedBox(
            width: 96,
            height: formFieldState.value!.content == null ? 20 : imageHeight + 30,
            child: Align(alignment: Alignment.topLeft,
                child:
                Row(children: [

                    IconButton(
                      onPressed: () async {
                        FilePickerResult? file = await FilePicker.platform
                            .pickFiles(type: FileType.image, allowMultiple: false);
                        if (file != null) {
                          File? pickedFile = File(file.files.first.path!);
                          formFieldState.didChange( CustomImageState(true, null, await pickedFile.readAsBytes()));
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
              ),

            labelText: label, //label text of field

            errorText: formFieldState.errorText

            ),
            child: child


         )]);



        return c;
      });


}


