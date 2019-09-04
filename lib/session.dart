import 'package:http/http.dart' as http;
import 'dart:convert';

const api_version = "v1";

class Session {
  String _url;
  String _port;
  String _token;
  Map<String, String> _header = {
  };


  Session(this._url, this._port);

  Future<bool> connectUser(String email, String password) async {
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$email:$password'));
    print(email);
    print(password);
    this._header["Authorization"] = basicAuth;
    final response = await http.post("${this._url}:${this._port}/$api_version/json-web-tokens",
        headers: this._header, body: {});
    if (response.statusCode != 200) {
      print(response.statusCode);
      print(response.body);
      return false;
    }
    final resJson = json.decode(response.body);
    this._token = resJson["data"]["attributes"]["token"];
    return true;
  }
}