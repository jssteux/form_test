import 'dart:typed_data';

class CustomImageState {

bool modified = false;
String? url;
Uint8List? content;

CustomImageState( this.modified, this.url, this.content);
}