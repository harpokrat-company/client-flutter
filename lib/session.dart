import 'package:http/http.dart' as http;
import 'package:json_api/json_api.dart' as json_api;
import 'dart:convert';

const api_version = "v1";

class Session {
  String _url;
  String _port;
  String _token;
  String _email;
  String _password;
  json_api.JsonApiClient jsonApiClient;
  Map<String, String> _header = {
  };


  Session(this._url, this._port);

  Future<bool> connectUser(String email, String password) async {
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$email:$password'));
    print(email);
    print(password);
    this._email = email;
    this._password = password;
    this._header["Authorization"] = basicAuth;
    final httpClient = http.Client();
    this.jsonApiClient = json_api.JsonApiClient(httpClient);
    final authToken = Uri.parse("${this._url}:${this._port}/$api_version/json-web-tokens/");
    final rsc = json_api.Resource("user", null, attributes: {"email": email, "password": password});

    final response = await this.jsonApiClient.createResource(authToken, rsc, headers: this._header);

    if (response.isFailed) {
      print(response.status);
      print(response.toString());
      return false;
    }
    final resource = response.data.unwrap();
    print(resource);
    this._token = resource.attributes["token"];
    return true;
  }

  Future<List<Map<String, dynamic>>> getPassword() async {
    this._header["Authorization"] = "bearer ${this._token}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets/");
    final response = await this.jsonApiClient.fetchCollection(uri, headers: this._header);
    if (response.isFailed) {
      print(response.status);
      print(response.toString());
      return null;
    }
    List<Map<String, dynamic>> res = [];
    for (var secret in response.data.collection) {
      final encryptedSecret = secret.attributes["content"];
      String decryptedSecret = utf8.decode(base64Decode(encryptedSecret));
      Map<String, dynamic> jsonSecret = jsonDecode(decryptedSecret);
      res.add(jsonSecret);
    }
    return res;
  }
}