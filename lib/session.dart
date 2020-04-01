import 'dart:collection';

import 'package:harpokrat/entities/Password.dart';
import 'package:http/http.dart' as http;
import 'package:json_api/json_api.dart' as json_api;
import 'package:hclw_flutter/hclw_flutter.dart' as hclw;
import 'package:hclw_flutter/secret.dart' as hclw_secret;
import 'dart:convert';

import 'entities/User.dart';

const api_version = "v1";

class Session {
  String _url;
  String _port;
  User user;
  json_api.JsonApiClient jsonApiClient;
  hclw.HclwFlutter lib;
  Map<String, String> _header = {
  };


  Session(this._url, this._port) {
    lib = new hclw.HclwFlutter();
    final httpClient = http.Client();
    this.jsonApiClient = json_api.JsonApiClient(httpClient);
  }

  Future<bool> connectUser(String email, String password) async {
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$email:$password'));
    print(email);
    print(password);
    user = User(email, password);
    this._header["Authorization"] = basicAuth;
    final path = "${this._url}:${this._port}/$api_version/json-web-tokens";
    final authToken = Uri.parse(path);
    print(authToken.toString());
    final rsc = json_api.Resource("user", null, attributes: {"email": email, "password": password});
    final response = await this.jsonApiClient.createResource(authToken, rsc, headers: this._header);

    if (response.isFailed) {
      print(response.status);
      print(response.data.toString());
      return false;
    }
    final resource = response.data.unwrap();
    print(resource);
    user.jwt = resource.attributes["token"];
    user.id = resource.toOne["user"].id;
    return true;
  }


  /// This function returns true or false if it succeeded to
  /// fetch data about the user,
  /// if it did, it update the attribute this.user.attribute
  Future<bool> getPersonalInfo() async {
    final response = await fetchResource("users", arg: user.id);
    if (response.isFailed)
      return false;
    final resource = response.data.unwrap();
    this.user.attributes["firstName"] = resource.attributes["firstName"] as String;
    this.user.attributes["lastName"] = resource.attributes["lastName"] as String;
    return true;
  }


  Future<json_api.Response<json_api.ResourceCollectionData>> fetchCollection(String route, {String arg}) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/$route" + (arg == null ? "": "/$arg"));
    print("fetchesource $uri");
    final response = await this.jsonApiClient.fetchCollection(uri, headers: this._header);
    if (response.isFailed) {
      print("fetchResource ${response.status}");
      print("fetchResource ${response.toString()}");
      return null;
    }
    return response;
  }
 /*
 *  Fetch resources from the server
 *
 */
  Future<json_api.Response<json_api.ResourceData>> fetchResource(String route, {String arg}) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/$route" + (arg == null ? "": "/$arg"));
    print("fetchesource $uri");
    final response = await this.jsonApiClient.fetchResource(uri, headers: this._header);
    if (response.isFailed) {
      print("fetchResource ${response.status}");
      print("fetchResource ${response.toString()}");
      return null;
    }
    return response;
  }

  // Register and encrypt new password on the server
  void createPassword(String url, String email, String password) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets");

    final blob = createBlob(url, email, password);
    final resource = json_api.Resource("secrets", "",
      attributes: {"content": blob}, toOne: {"owner": json_api.Identifier("users", user.id)});
    print(this._header);
    final test = await this.jsonApiClient.createResource(uri, resource, headers: this._header);
    print("blob: $blob");
    print(test.status);
  }

  // Register and encrypt new password on the server
  void updatePassword(Password password) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets/${password.id}");

    print(uri);
    final resource = json_api.Resource("secrets", password.id,
        attributes: {"content": password.secret.content},
        toOne: {"owner": json_api.Identifier("users", user.id)});
    final test = await this.jsonApiClient.updateResource(uri, resource, headers: this._header);
    print(test.status);
  }

  // Register and encrypt new password on the server
  void deletePassword(Password password) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets/${password.id}");
    print(uri);
    final test = await this.jsonApiClient.deleteResource(uri, headers: this._header);
    print(test.status);
  }


  /*
  * Create user on the server, needs the User object
   */
  Future<bool> createUser(User user) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/users");

    final resource = json_api.Resource("users", "",
        attributes: {"email": user.email, "password": user.password,
          "firstName": user.attributes["firstName"],
          "lastName": user.attributes["lastName"]});
    print(user.attributes);
    final test = await this.jsonApiClient.createResource(uri, resource);
    print(test.status);
    print(test.data);
    return test.isSuccessful;
  }

  /*
  * Create and encrypt blob from json to hexadecimal format
   */
  String createBlob(String url, String email, String password) {
    hclw_secret.Secret secret = new hclw_secret.Secret(lib, content:"");
    secret.password = password;
    secret.domain = url;
    secret.name = url;
    secret.login = email;
    // TODO: inject encryption library
    return secret.content;
  }

  Future<List<Password>> getPassword() async {
    final response = await fetchCollection("secrets");
    List<Password> res = [];
    for (var secret in response.data.collection) {
      final String encryptedSecret = secret.attributes["content"];
      if ((secret.relationships["owner"] as json_api.ToOne).linkage.id != this.user.id)
        continue;
        final decryptedSecret = new hclw_secret.Secret(
            lib, content: encryptedSecret);
        res.add(Password(decryptedSecret, secret.id));
    }
    return res;
  }
}