import 'package:harpokrat/entities/Password.dart';
import 'package:http/http.dart' as http;
import 'package:json_api/json_api.dart' as json_api;
import 'package:hclw_flutter/hclw_flutter.dart' as hclw;
import 'package:hclw_flutter/secret.dart' as hclw_secret;

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
    String basicAuth = lib.getBasicAuth(email, password);
    user = User(email, password);
    this._header["Authorization"] = basicAuth;
    final path = "${this._url}:${this._port}/$api_version/json-web-tokens";
    final authToken = Uri.parse(path);
    final rsc = json_api.Resource("user", null, attributes: {"email": email, "password": password});
    final response = await this.jsonApiClient.createResource(authToken, rsc, headers: this._header);
    if (response.isFailed) {
      return false;
    }
    final resource = response.data.unwrap();
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
    final response = await this.jsonApiClient.fetchCollection(uri, headers: this._header);
    if (response.isFailed) {
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
    final response = await this.jsonApiClient.fetchResource(uri, headers: this._header);
    if (response.isFailed) {
      return null;
    }
    return response;
  }

  // Register and encrypt new password on the server
  Future<bool> createPassword(String url, String email, String password) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets");

    final blob = createBlob(url, email, password);
    final resource = json_api.Resource("secrets", "",
      attributes: {"content": blob}, toOne: {"owner": json_api.Identifier("users", user.id)});
    final test = await this.jsonApiClient.createResource(uri, resource, headers: this._header);
    return test.isSuccessful;
  }

  // Register and encrypt new password on the server
  Future<bool> updatePassword(Password password) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets/${password.id}");

    final resource = json_api.Resource("secrets", password.id,
        attributes: {"content": password.secret.serialize(user.password)},
        toOne: {"owner": json_api.Identifier("users", user.id)});
    final test = await this.jsonApiClient.updateResource(uri, resource, headers: this._header);
    return test.isSuccessful;
  }

  // Register and encrypt new password on the server
  Future<bool> deletePassword(Password password) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets/${password.id}");
    final test = await this.jsonApiClient.deleteResource(uri, headers: this._header);
    return test.isSuccessful;
  }


  /*
  * Create user on the server, needs the User object
   */
  Future<bool> createUser(User user) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/users");

    final resource = json_api.Resource("users", "",
        attributes: {"email": user.email, "password": lib.getDerivedKey(user.password),
          "firstName": user.attributes["firstName"],
          "lastName": user.attributes["lastName"]});
    final test = await this.jsonApiClient.createResource(uri, resource);
    return test.isSuccessful;
  }

  Future<bool> updateUser() async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";

    final uri = Uri.parse("${this._url}:${this._port}/$api_version/users/${user.id}");
    final resource = json_api.Resource("users", user.id,
        attributes: {"email": user.email, "password": lib.getDerivedKey(user.password),
      "firstName": user.attributes["firstName"],
      "lastName": user.attributes["lastName"]});

    final res = await this.jsonApiClient.updateResource(uri, resource, headers: _header);
    return res.isSuccessful;
  }

  /*
  * Create and encrypt blob from json to hexadecimal format
   */
  String createBlob(String url, String email, String password) {
    hclw_secret.Secret secret = new hclw_secret.Secret(lib, key: user.password);
    secret.password = password;
    secret.domain = url;
    secret.name = url;
    secret.login = email;
    // TODO: inject encryption library
    return secret.serialize(user.password);
  }

  Future<List<Password>> getPassword() async {
    final response = await fetchCollection("secrets");
    List<Password> res = [];
    for (var secret in response.data.collection) {
      final String encryptedSecret = secret.attributes["content"];
      if ((secret.relationships["owner"] as json_api.ToOne).linkage.id != this.user.id)
        continue;
        final decryptedSecret = new hclw_secret.Secret(
            lib, content: encryptedSecret, key: user.password);
        res.add(Password(decryptedSecret, secret.id));
    }
    return res;
  }
}