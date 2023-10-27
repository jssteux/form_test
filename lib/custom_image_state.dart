import 'dart:typed_data';

class CustomImageState {

bool modified = false;
Uint8List? content;

CustomImageState( this.modified, this.content);
}