import 'package:harpokrat/model/Password.dart';
import 'package:http/http.dart' as http;
import 'package:json_api/client.dart' as json_api;
import 'package:hclw_flutter/hclw_flutter.dart' as hclw;
import 'package:hclw_flutter/secret.dart' as hclw_secret;
import 'package:json_api/client.dart';
import 'package:json_api/document.dart';
import 'package:json_api/http.dart';
import 'package:json_api/query.dart';
import 'package:json_api/routing.dart';

import '../model/User.dart';

const api_version = "v1";

class Session {
  String _url;
  String _port;
  User user;
  json_api.JsonApiClient jsonApiClient;
  json_api.RoutingClient jsonRootingClient;
  hclw.HclwFlutter lib;
  Map<String, String> _header = {
  };


  Session(this._url, this._port) {
    lib = new hclw.HclwFlutter();
    final httpClient = http.Client();
    final routing = StandardRouting(Uri.parse('${this._url}:${this._port}/$api_version'));
    final httpHandler = LoggingHttpHandler(DartHttp(httpClient));

    this.jsonApiClient = json_api.JsonApiClient(httpHandler);
    this.jsonRootingClient = RoutingClient(json_api.JsonApiClient(httpHandler), routing);
  }

  Future<bool> connectUser(String email, String password) async {
    String basicAuth = lib.getBasicAuth(email, password);
    user = User(email, password);
    this._header["Authorization"] = basicAuth;
    print(basicAuth);
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/json-web-tokens");
    final rsc = Resource("users", null, attributes: {"email": email, "password": password});
    final response = await this.jsonApiClient.createResourceAt(uri, rsc, headers: this._header);
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


  Future<json_api.Response<ResourceCollectionData>> fetchCollection(String route, {String arg, QueryParameters queryParameters}) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/$route" + (arg == null ? "": "/$arg"));
    final response = await this.jsonApiClient.fetchCollectionAt(uri, headers: this._header, parameters: queryParameters);
    if (response.isFailed) {
      return null;
    }
    return response;
  }
 /*
 *  Fetch resources from the server
 *
 */
  Future<json_api.Response<ResourceData>> fetchResource(String route, {String arg}) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/$route" + (arg == null ? "": "/$arg"));
    final response = await this.jsonApiClient.fetchResourceAt(uri, headers: this._header);
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
    final resource = Resource("secrets", "",
      attributes: {"content": blob}, toOne: {"owner": Identifier("users", user.id)});
    final test = await this.jsonApiClient.createResourceAt(uri, resource, headers: this._header);
    return test.isSuccessful;
  }

  // Register and encrypt new password on the server
  Future<bool> updatePassword(Password password) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets/${password.id}");

    final resource = Resource("secrets", password.id,
        attributes: {"content": password.secret.serialize(user.password)},
        toOne: {"owner": Identifier("users", user.id)});
    final test = await this.jsonApiClient.updateResourceAt(uri, resource, headers: this._header);
    return test.isSuccessful;
  }

  // Register and encrypt new password on the server
  Future<bool> deletePassword(Password password) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets/${password.id}");
    final test = await this.jsonApiClient.deleteResourceAt(uri, headers: this._header);
    return test.isSuccessful;
  }


  /*
  * Create user on the server, needs the User object
   */
  Future<bool> createUser(User user) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/users");
    final resource = Resource("users", "",
        attributes: {"email": user.email, "password": lib.getDerivedKey(user.password),
          "firstName": user.attributes != null ? user.attributes["firstName"]: "",
          "lastName": user.attributes != null ? user.attributes["lastName"]: ""});
    final test = await this.jsonApiClient.createResourceAt(uri, resource);
    return test.isSuccessful;
  }

  Future<bool> updateUser() async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";

    final uri = Uri.parse("${this._url}:${this._port}/$api_version/users/${user.id}");
    final resource = Resource("users", user.id,
        attributes: {"email": user.email, "password": lib.getDerivedKey(user.password),
      "firstName": user.attributes["firstName"],
      "lastName": user.attributes["lastName"]});

    final res = await this.jsonApiClient.updateResourceAt(uri, resource, headers: _header);
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
    QueryParameters queryParameters = QueryParameters({"filter[owner.id]": this.user.id});
    final response = await fetchCollection("secrets", queryParameters: queryParameters);
    List<Password> res = [];
    for (var secret in response.data.collection) {
      final String encryptedSecret = secret.attributes["content"];
        final decryptedSecret = new hclw_secret.Secret(
            lib, content: encryptedSecret, key: user.password);
        res.add(Password(decryptedSecret, secret.id));
    }
    return res;
  }
}