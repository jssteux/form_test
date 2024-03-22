import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;


class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;

  final http.Client _client = http.Client( );
  static List<int> requests = [];

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {

    // Quota only for spreadsheet

    if( !request.url.path.startsWith("/drive")) {
      var ts = DateTime
          .now()
          .millisecondsSinceEpoch;
      requests.add(ts);

      debugPrint("send ${request.url.path}");

      debugPrint("send quota ${requests.length}");

      while (requests.length > 50) {
        await Future.delayed(const Duration(seconds: 1));

        debugPrint("wait quota ${requests.length}");

        var now = DateTime
            .now()
            .millisecondsSinceEpoch;
        requests.removeWhere((element) => (now - element) > 60000);
      }
    }


    return _client.send(request..headers.addAll(_headers));
  }
}