import "package:googleapis_auth/auth_io.dart";
import 'package:googleapis/logging/v2.dart';


class Logger {

  late LoggingApi logger;

  Logger()  {
   () async {
     obtainServiceCredentials();
    }.call();
  }

  // Use service account credentials to obtain oauth credentials.
  obtainServiceCredentials() async {
    var accountCredentials = ServiceAccountCredentials.fromJson({
      "type": "service_account",
      "project_id": "oauth2-demo-334509",
      "private_key_id": "37dc220ee0c9fd5e9a1af44ed72c0231cbccae85",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQCiz4AwxWIS3oQk\n1HqorhroH47ZdHWHXvr99OjmuJLIR1ScEiJbUPcvirOZktC1pY9yXKrnvhYISNlt\nQ7/O5AJ+fp6j1CaiUwiZQZDHKpKR3qjTXLA11jZMWstDLyxzzdtkuj0oAOXD5j3z\nUgt+Xngiv/JcYMvN8X2xTwvVbvFvOSGSEm0QizEImdcnWb9T71RKnI4U98MVK/5H\nOuJch4YLUdSwyGzJj/YTqJ0y7adzCHmCzSQUYUzSdpCergcx1S6Q9H/HlFNy1dpx\nwakbh3DmJx5gdj7277GhC0QekRn0ZpCfJkmk7Ji++CwecIJdwG0QTZrwLH7RXORf\nrxGETrQVAgMBAAECggEANYEuthhv6haRY88mPj/1XLpeRi1lIGdA4eu2DHi02DfE\n4QN+ofbiPQ/+hOZAS6nMkf9NNRp9gBx8w9FDfDjnbu2qsdlbFvZluYPYEfP2NhTv\n84Ie8JpkvsQJz5r1p1sMEja4OWjOGYqValzYpR9jqLve6Kfw4k3OClKZZ3ttwaiF\nJbh8KK0+9FDxSH3uspZpSOC3SP78Z1Y1I3Lf1fIrAHD+D7gF4J+DinoNYMoStUo9\n5il8vB4OljoWTjlUUEt8Yb1IHzXa9V+UM7rVEMm6Dtycv/CRCa1GlLgC5+Cki3id\n/nofu1oQIF4i2wg5KE0terAhzLM1fcBSD4+X9LHN4wKBgQDMVgOj/dWPW86jb+pk\ns6QYr3kXRsP19ODJ3zm9OxGh1xe+8m8wYSSj/gqp/Oly/NpB771/at27HYxW2NLy\nuaB1p6yBJV/8y9BB2r/INSW6fW9hzI7vUuDxtai/WsvDmBZzFlszG84IRYUiYmit\nwnISPTAAXnE129CquJpMy72qewKBgQDL+a7ytWvjQbAix4hG90/RBkl+AAUz004k\nEp0Qv3hjXiHFhta8WYVnLsFa3ewO3HNMNcqFHWU6Iynq8Imll9r/NC4yfMls91Sx\nMlkn3ABjyWX+XI60keviXy97yTbUALczAXeOEecdgu/6RkE6F1RAwn3Mn84G/zao\ninUL/MperwKBgQChOAxPS2tAXPNAyIBrS8FhKLGlx9O9L6RcIp/vybcztf2qTqWj\nykGakknfrQiUDSQ3eexNqAeiJsIfk5t8nzEXI2Bb1R1S24xJKUq/sA9AgM9snnT4\nJrAMhYPK1tyGSm0MCMuUG5AHvrI4WuS0lAJkmZpR8DHqiLCuwlAb33SaGQKBgQCp\nuUS9aAAxxQLOrcDTbA3aG6UjVtj9WqH2mhZfTTLbXAQ13BDqAINkbB8vgOFfLEgz\n7b5qLR+B1KiYeTXPuB/doomeMP9Z0COEniRZalJYtchMcq+7yH/CiPl1wuQAW+gU\nZPAaIwNwJveQBM1ZjPfqOut6TK6eW9YbP7pNEzdAuQKBgQCfToVH/1Je6cQ5PJxU\nKLrsBHbu6dxd5AOrcQ158JsXQEQMXcpW2V6vqB5wMPiHUvqcQs/4V75bZabWx4uv\nx62eBZ6dP8XCt8TCvbOrUZ0Dfs0NHbnqTrZNh/JwdtQTElqcpbp/yT/+RK52bYQn\nXDMKFipXqyceck8b85fBk3npZg==\n-----END PRIVATE KEY-----\n",
      "client_email": "logger@oauth2-demo-334509.iam.gserviceaccount.com",
      "client_id": "104969332865213967186",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/logger%40oauth2-demo-334509.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    }
    );
    List<String> scopes = [LoggingApi.loggingWriteScope];

    AuthClient client = await clientViaServiceAccount(accountCredentials, scopes);
    logger = LoggingApi(client);
  }

  Future<void> logEvent(String descr) async {
    final Map<String, String> params = {'message': descr};
    final logEntry = LogEntry(
        logName: 'projects/oauth2-demo-334509/logs/store',
        jsonPayload: params,
        resource: MonitoredResource(type: 'global'),
        labels: {'isWeb': '0'});
    final req = WriteLogEntriesRequest(entries: [logEntry]);
    logger.entries.write(req);
  }


}