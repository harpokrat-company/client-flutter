import 'package:harpokrat/model/Group.dart';
import 'package:harpokrat/model/Organization.dart';
import 'package:harpokrat/model/Password.dart';
import 'package:harpokrat/model/Vault.dart';
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

class  Session {
  String _url;
  String _port;
  User user;
  String captchaKey;
  String captchaToken;
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

  Future<bool> getCaptchaKey() async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/recaptcha");
    final response = await this.jsonApiClient.fetchResourceAt(uri);
    if (response.isFailed) {
      print(response.statusCode);
      return false;
    }
    Resource r = response.data.unwrap();
    captchaKey = r.attributes["siteKey"];
    return true;
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

  Future<List<Organization>> getOrganization() async {
    var l = new List<String>();
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/users/${user.id}/organizations");
    final response = await this.jsonApiClient.fetchCollectionAt(uri, headers: this._header);
    if (response.isFailed) {
      return null;
    }
    List<Organization> res = [];
    var collection = response.data.unwrap();
    for (var element in collection) {
      res.add(Organization(element.attributes["name"], element.id));
    }
    return res;
  }

  Future<List<Organization>> addOrganization_member() async {
    var l = new List<String>();
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/users/${user.id}/organizations");
    final response = await this.jsonApiClient.fetchCollectionAt(uri, headers: this._header);
    if (response.isFailed) {
      return null;
    }
    List<Organization> res = [];
    var collection = response.data.unwrap();
    for (var element in collection) {
      res.add(Organization(element.attributes["name"], element.id));
    }
    return res;
  }

  Future<List<Vault>> getVaultsFrom(Uri uri) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final response = await this.jsonApiClient.fetchCollectionAt(uri, headers: this._header);
    if (response.isFailed) {
      return null;
    }
    List<Vault> res = [];
    var collection = response.data.unwrap();
    for (var element in collection) {
      res.add(Vault(element.attributes["name"], element.id));
    }
    return res;
  }
  
  Future<List<Vault>> getUserVaults() async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/users/${user.id}/vaults");
    return getVaultsFrom(uri);
  }
  
  Future<List<Vault>> getGroupVaults(Identifier id) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/groups/${id.id}/vaults");
    return getVaultsFrom(uri);
  }

  Future<List<Group>> getUserGroup(Identifier owner) async {
    var l = new List<String>();
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/organizations/${owner.id}/groups");
    final response = await this.jsonApiClient.fetchCollectionAt(uri, headers: this._header);
    if (response.isFailed) {
      return [];
    }
    List<Group> res = [];
//    var collection = response.data.unwrap();
    for (var element in response.data.collection) {
      res.add(Group(element.attributes["name"], element.id));
    }
    return res;
  }

  Future<bool> createOrganisationGroup(String name, Identifier organisation) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/groups");
    Resource group = new Resource("groups", "",
        attributes: {"name": name},
        toOne: {"organization": organisation});
    final response = await this.jsonApiClient.createResourceAt(uri, group, headers: this._header);
    if (response.isFailed) {
      return false;
    }
    return true;
  }

  Future<bool> createGroupGroup(String name, Identifier groupId) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/groups");
    Resource group = new Resource("groups", "",
        attributes: {"name": name},
        toOne: {"group": groupId});
    final response = await this.jsonApiClient.createResourceAt(uri, group, headers: this._header);
    if (response.isFailed) {
      return false;
    }
    return true;
  }
  

  Future<bool> createVault(String name, Identifier owner) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version//vaults");
    Resource vault = new Resource("vaults", "",
        attributes: {"name": name},
        toOne: {"owner": owner});
    final response = await this.jsonApiClient.createResourceAt(uri, vault, headers: this._header);
    if (response.isFailed) {
      return false;
    }
    return true;
  }

  Future<bool> addMemberTo(String email, Uri uri) async {
    QueryParameters queryParameters = QueryParameters({"Filter[user.email]": email});
    var uri = Uri.parse("${this._url}:${this._port}/$api_version/users/");
    final collection = await fetchCollection("users", queryParameters: queryParameters);
    final l = collection.data.unwrap().where((element) => element.attributes["email"] == email).toList();
    if (l.length < 1)
      return false;
    final id = l[0].id;
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    Identifier member = Identifier("users", id);
    final response = await this.jsonApiClient.addToRelationshipAt(uri,
        [member], headers: this._header);
    if (response.isFailed) {
      return false;
    }
    return true;
  }

  Future<bool> addOrganizationMember(String email, Identifier owner) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/organizations/${owner.id}/relationships/members");
    return addMemberTo(email, uri);
  }

  Future<bool> addGroupMember(String email, Identifier owner) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/groups/${owner.id}/relationships/members");
    return addMemberTo(email, uri);
  }

  Future<bool> createOrganization(String name, Identifier owner) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/organizations");
    Resource vault = new Resource("organizations", "",
        attributes: {"name": name},
        toOne: {"owner": owner});
    final response = await this.jsonApiClient.createResourceAt(uri, vault, headers: this._header);
    if (response.isFailed) {
      return false;
    }
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

    var organizations = await getOrganization();
    for (var organization in organizations) {
      organization.groups = await getUserGroup(organization.getIdentifier());
      organization.members = await getOrganisationMembers(organization.getIdentifier());
    }
    this.user.organizations = organizations;
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
  Future<bool> createPassword(String url, String email, String password, Identifier owner) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets");

    final blob = createBlob(url, email, password);
    final resource = Resource("secrets", "",
      attributes: {"content": blob}, toOne: {"owner": owner});
    final test = await this.jsonApiClient.createResourceAt(uri, resource, headers: this._header);
    return test.isSuccessful;
  }

  // Register and encrypt new password on the server
  Future<bool> updatePassword(Password password) async {
    //TODO: Update to the last encryption version
/*    var sym_key = hclw_sym_key.SymmetricKey(this.lib);
    sym_key.initializeSymmetric();
    sym_key.key = user.password;*/
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets/${password.id}");

    final resource = Resource("secrets", password.id,
        attributes: {"content": password.secret.password(user.password)},
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

  // Register and encrypt new password on the server
  Future<bool> deleteGroup(Group group) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/organizations/${group.id}/relationship/groups");
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
    final test = await this.jsonApiClient.createResourceAt(uri, resource /*, meta: {"captcha": captchaToken}*/);
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
    return secret.content;
    // TODO: Update encryption library
    /* var sym_key = hclw_sym_key.SymmetricKey(this.lib);
    sym_key.initializeSymmetric();
    sym_key.key = user.password;
    return password.serialize(sym_key.secret);*/
  }

  Future<List<Password>> getPassword() async {
    //TODO: Update to the latest encryption library
  /*  var sym_key = hclw_sym_key.SymmetricKey(this.lib);
    sym_key.initializeSymmetric();
    sym_key.key = user.password;*/
    // QueryParameters queryParameters = QueryParameters({"filter[owner.id]": this.user.id});
    final response = await fetchCollection("users/${user.id}/secrets");
    List<Password> res = [];
    for (var secret in response.data.collection) {
      final String encryptedSecret = secret.attributes["content"];
      final decryptedSecret = new hclw_secret.Secret(
          lib, content: encryptedSecret, key: user.password);
//      Secret decryptedSecret;
      res.add(Password(decryptedSecret, secret.id));
    }
    return res;
  }

  Future<List<User>> getMembersFrom(Uri uri) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final response = await this.jsonApiClient.fetchCollectionAt(uri, headers: this._header);
    if (response.isFailed) {
      return [];
    }
    List<User> res = [];
    for (var element in response.data.collection) {
      var u = User(element.attributes["email"], "");
      u.id = element.id;
      res.add(u);
    }
    return res;
  }

  Future<List<User>> getOrganisationMembers(Identifier identifier) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/organizations/${identifier.id}/members");
    return getMembersFrom(uri);
  }

  Future<List<User>> getGroupMembers(Identifier identifier) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/groups/${identifier.id}/members");
    return getMembersFrom(uri);
  }

}