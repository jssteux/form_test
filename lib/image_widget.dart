

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';

// Define a custom Form widget.
class ImageWidget extends StatefulWidget {

  const ImageWidget({super.key});

  @override
  ImageWidgetState createState() {
    return ImageWidgetState();
  }
}

// Define a corresponding State class.
// This class holds data related to the form.
class ImageWidgetState extends State<ImageWidget> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<ImageWidgetState>();

  File? image;
  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if(image == null) return;
      final imageTemp = File(image.path);
      setState(() => this.image = imageTemp);
    } on PlatformException catch(e) {
      e;//print('Failed to pick image: $e');
    }
  }




  Widget _build() {
       Column c = Column(
          children: [
            MaterialButton(
                color: Colors.blue,
                child: const Text(
                    "Pick Image from Camera",
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold
                    )
                ),

                onPressed: () {pickImage();
                }
            ),

          ]);

      if( image != null) {
        c.children.add(Image.file(File(image!.path)));
      }
      return c;
   }




  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _build()
        ],
      ),
    );
  }
}