import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:harpokrat/model/EcryptionKey.dart';
import 'package:harpokrat/model/Group.dart';
import 'package:harpokrat/model/Organization.dart';
import 'package:harpokrat/model/Owner.dart';
import 'package:harpokrat/model/Password.dart';
import 'package:harpokrat/model/Vault.dart';
import 'package:hclw_flutter/rsakeypair.dart';
import 'package:hclw_flutter/rsaprivatekey.dart';
import 'package:hclw_flutter/rsapublickey.dart';
import 'dart:math';
import 'package:hclw_flutter/symmetrickey.dart';
import 'package:http/http.dart' as http;
import 'package:json_api/client.dart' as json_api;
import 'package:hclw_flutter/hclw_flutter.dart' as hclw;
import 'package:hclw_flutter/asecret.dart' as hclw_secret;
import 'package:hclw_flutter/password.dart' as hclw_password;
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
    this.jsonRootingClient = RoutingClient(json_api.JsonApiClient(  httpHandler), routing);
  }

  Future<bool> getCaptchaKey() async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/recaptcha");
    final response = await this.jsonApiClient.fetchResourceAt(uri);
    if (response.isFailed) {
      print(response.statusCode);
      return false;
    }
    Resource r = response.data.unwrap();
    captchaKey = r.attributes["reCAPTCHA-v2-android"];
    return true;
  }

  Future<bool> deleteAllUserSecret() async {
    final response = await fetchCollection("users/${user.id}/secrets");
    for (var secret in response.data.collection) {
      deleteSecret(secret.id);
      }
    return true;
  }

  Future<bool> getUserSecret() async {
    var success = await getEncryptionKeyUser();
    if (!success)
      return false;
    final response = await fetchCollection("users/${user.id}/secrets");
    bool privateKeyFound = false;
    for (var secret in response.data.collection) {
      if (secret.id == user.encryptionKeyId) {
        user.privateKey = EncryptionKey(
            secret.unwrap(), lib, decryptionSymmetricKey: user.symmetricKey);
        privateKeyFound = true;
        break;
      }
    }
    if (privateKeyFound == false) {
      return false;
    }
    for (var secret in response.data.collection) {
      if (secret.attributes["private"] == true)
        user.publicKey = EncryptionKey(secret.unwrap(), lib);
      else if (secret.id != user.encryptionKeyId)
        user.groupKeys.add(EncryptionKey(secret.unwrap(), lib, decryptionAsymmetricKey: user.privateKey.asRSAPrivate()));
    }
    return true;
  }

  Future<bool> connectInitUser(String email, String password) async {
    bool isConnected = await connectUser(email, password);
    if (!isConnected)
      return false;
    return true;
//    return await getUserSecret();
  }

  Future<bool> verifyToken(String token) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secure-actions/${user.mfaId}");
    final r = Resource(
      "secure-actions", user.mfaId, attributes: {"validated": true}
    );
    final response = await this.jsonApiClient.updateResourceAt(uri, r, headers: this._header, meta: {"token": token});
    return response.isSuccessful;
  }

  Future<bool> connectUser(String email, String password) async {
    String basicAuth = lib.getBasicAuth(email, password);
    user = User(email, password, new SymmetricKey(lib));
    user.symmetricKey.key = password;
    this._header["Authorization"] = basicAuth;
    print(basicAuth);
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/json-web-tokens");
    final rsc = Resource("users", "", attributes: {"email": email, "password": lib.getDerivedKey(password)});
    final response = await this.jsonApiClient.createResourceAt(uri, rsc, headers: this._header);
    if (response.isFailed) {
      return false;
    }
    var resource;
    try {
      resource = response.data.unwrap();
      user.jwt = resource.attributes["token"];
      user.id = resource.toOne["user"].id;
    } catch (e) {
      resource = response.data.resourceObject;
      user.jwt = resource.attributes["token"];
      user.id = resource.relationships["user"].linkage.id;
    }
    QueryParameters queryParameters = QueryParameters({"Filter[user.email]": email});
    ToOne mfa = response.data.resourceObject.relationships["mfa"];
    if (mfa != null) {
      user.mfa = true;
      user.mfaId = mfa.identifier.id;
    }
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

  Future<bool> getVaultData(Vault vault, RSAPublicKey encryptionKey, RSAPrivateKey decryptionKey) async {
    bool keyFetched = true; //await getEncryptionKeyVault(vault, decryptionKey);
    if (!keyFetched) {
      bool keyCreated = await createEncryptionKeyVault(vault, encryptionKey, decryptionKey);
      if (!keyCreated)
        return false;
    }
    return await getPasswordVault(vault);
  }

  Future<List<Vault>> getVaultsFrom(Uri uri) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final response = await this.jsonApiClient.fetchCollectionAt(uri, headers: this._header);
    if (response.isFailed) {
      return null;
    }
    List<Vault> res = [];
    var collection = response.data.collection;
    for (var element in collection) {
      res.add(Vault(element.attributes["name"], element.id));
    }
    return res;
  }

  Future<List<Vault>> getUserVaults() async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/users/${user.id}/vaults");
    final vaultList = await getVaultsFrom(uri);
    for (var vault in vaultList)
      await deleteVault(vault);
    return vaultList;
  }

  Future<List<Vault>> getOwnerVaults(Owner owner) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/${owner.identifier.type}/${owner.identifier.id}/vaults");
    final vaultList = await getVaultsFrom(uri);
    return vaultList;
  }


  Future<List<Vault>> getGroupVaults(Group group) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/groups/${group.id}/vaults");
    return getVaultsFrom(uri);
  }

  Future<List<Group>> getGroupGroup(Identifier owner) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/organizations/${owner.id}/groups");
    final response = await this.jsonApiClient.fetchCollectionAt(uri, headers: this._header);
    if (response.isFailed) {
      return [];
    }
    List<Group> res = [];
    for (var element in response.data.collection) {
      if (element.attributes["name"] != null) {
        var group = Group(element.attributes["name"], element.id);
        var canDecrypt = false;
        group.groups = await getGroupGroup(group.getIdentifier());
        if (group.groups.length > 0) {
          group.privateKey = group.groups[0].privateKey;
          canDecrypt = true;
        } else
          canDecrypt = true; //await getGroupSecrets(group);
        if (!canDecrypt)
          res.add(group);
      }
    }
    return res;
  }

  Future<bool> getGroupSecrets(Group group) async {
    for (final groupKey in user.groupKeys) {
      if (groupKey.asRSAPrivate().owner == group.id) {
        group.privateKey = groupKey;
        break;
      }
    }
    if (group.privateKey == null)
      return false;
    final collection = await fetchCollection("group/${group.id}/secrets");
    final secretList = collection.data.unwrap();
    for (final resource in secretList) {
      if (resource.attributes["visible"] == true)
        group.publicKey = EncryptionKey(resource, lib);
      else {
        group.parentPrivateKey = EncryptionKey(resource, lib, decryptionAsymmetricKey: group.privateKey.asRSAPrivate());
      }
    }
    return true;
  }

  Future<bool> createOrganisationGroup(String name, Organization organisation) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/groups");
    Resource group = new Resource("groups", "",
        attributes: {"name": name},
        toOne: {"organization": organisation.getIdentifier()});
    final response = await this.jsonApiClient.createResourceAt(uri, group, headers: this._header);
    if (response.isFailed) {
      return false;
    }
    final resource = response.data.unwrap();
    return true;
  }

  Future<bool> initGroup(Group group, {EncryptionKey parentKey}) async {
    final keyPair = new RSAKeyPair(lib, 2048);
    final public = keyPair.createPublicKey();
    public.initializePlain();
    final publicKey = await this.createSecretSymmetric(public, group.getIdentifier(), SymmetricKey(lib));
    if (public == null)
      return false;
    group.publicKey = publicKey;
    final private = keyPair.createPrivateKey();
    private.initializeAsymmetric();
    final privateKey = await this.createSecretASymmetric(public, group.getIdentifier(), user.publicKey.asRSAPublic(), user.privateKey.asRSAPrivate());
    if (privateKey == null)
      return false;
    group.privateKey = privateKey;
    final privateParentKey = await this.createSecretASymmetric(public, group.getIdentifier(), publicKey.asRSAPublic(), privateKey.asRSAPrivate());
    if (privateParentKey == null)
      return false;
    group.parentPrivateKey = privateParentKey;
    return true;
  }

  final _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));


  Future<bool> createEncryptionKeyVault(Vault vault, RSAPublicKey encryptionKey, RSAPrivateKey decryptionKey) async {
    final encryptionKeyVault = SymmetricKey(lib);
    encryptionKeyVault.key = getRandomString(64);
    encryptionKeyVault.initializeAsymmetric();
     final keyVault = await createSecretASymmetric(encryptionKeyVault, vault.getIdentifier(), encryptionKey, decryptionKey);
    if (keyVault == null)
      return false;
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/vaults/${vault.getIdentifier().id}/relationships/encryption-key");

    final test = await this.jsonApiClient.updateResourceAt(uri, keyVault.serializeAsymetric(encryptionKey), headers: this._header);
    if (test.isFailed)
      return false;
    vault.symmetricKey = keyVault;
    return test.isSuccessful;
  }

  Future<bool> createEncryptionKeyUser(Identifier idKey) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/users/${user.id}/relationships/encryption-key");

    final r = Resource(
      "secrets", idKey.id
    );
    final test = await this.jsonApiClient.updateResourceAt(uri, r, headers: this._header);
    if (test.isFailed)
      return false;
    return test.isSuccessful;
  }

  Future<bool> getEncryptionKeyUser() async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/users/${user.getIdentifier().id}/relationships/encryption-key");

    final test = await this.jsonApiClient.fetchResourceAt(uri, headers: this._header);
    if (test.isFailed)
      return false;
    final resource = test.data.unwrap();
    if (resource != null)
      user.encryptionKeyId = resource.id;
    return test.isSuccessful;
  }

  Future<bool> getEncryptionKeyVault(Vault vault, RSAPrivateKey decryptionKey) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/vaults/${vault.getIdentifier().id}/relationships/encryption-key");

    final test = await this.jsonApiClient.fetchResourceAt(uri, headers: this._header);
    if (test.isFailed)
      return false;
    if (test.data.resourceObject != null) {
      vault.encryptionKeyId = test.data.resourceObject.id;
      return true;
    }
    return false;
  }

  Future<bool> createGroupGroup(String name, Group parentGroup, Organization organization) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/groups");
    Resource group = new Resource("groups", "",
        attributes: {"name": name},
        toOne: {"organization": organization.getIdentifier(), "parent": parentGroup.getIdentifier()});
    final response = await this.jsonApiClient.createResourceAt(uri, group, headers: this._header);
    if (response.isFailed)
      return false;
    final resource = response.data.unwrap();
    final newGroup = Group(name, resource.id);
    final init = await initGroup(newGroup, parentKey: parentGroup.privateKey);
    if (!init)
      return false;
    parentGroup.groups.add(newGroup);
    return true;
  }

  Future<Resource> uploadSecretResource(Resource resource) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets");
    final test = await this.jsonApiClient.createResourceAt(uri, resource, headers: this._header);
    if (test.isFailed)
      return null;
    final r = test.data.unwrap();
    return r;
  }

  Future<EncryptionKey> createSecretSymmetric(hclw_secret.ASecret aSecret, Identifier owner, SymmetricKey encryptionKey,
  {bool visible = false}) async {
    final blob = aSecret.serialize(encryptionKey.key);
    final resource = Resource("secrets", "",
        attributes: {"content": blob, "private": visible}, toOne: {"owner": owner});
    final r = await uploadSecretResource(resource);
    if (r == null)
      return null;
    return EncryptionKey(r, lib, decryptionSymmetricKey: encryptionKey);
  }

  Future<EncryptionKey> createSecretASymmetric(hclw_secret.ASecret aSecret, Identifier owner, RSAPublicKey encryptionKey, RSAPrivateKey decryptionKey,
      {bool visible = false}) async {
    final blob = aSecret.serializeAsymmetric(encryptionKey);
    final resource = Resource("secrets", "",
        attributes: {"content": blob, "private": visible}, toOne: {"owner": owner});
    final r = await uploadSecretResource(resource);
    if (r == null)
      return null;
    return EncryptionKey(r, lib, decryptionAsymmetricKey: decryptionKey);
  }

  Future<Vault> createVault(String name, Identifier owner, RSAPublicKey encryptionKey, RSAPrivateKey decryptionKey) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/vaults");
    Resource vaultResource = new Resource("vaults", "",
        attributes: {"name": name},
        toOne: {"owner": owner});
    final response = await this.jsonApiClient.createResourceAt(uri, vaultResource, headers: this._header);
    if (response.isFailed)
      return null;
//    final r = response.data.unwrap();
    Vault vault = Vault(response.data.resourceObject.attributes["name"], response.data.resourceObject.id);
//    final success = await createEncryptionKeyVault(vault, encryptionKey, decryptionKey);
//    if (!success)
//      return null;
    return vault;
  }

  Future<bool> banMemberFrom(String email, Uri uri) async {
    QueryParameters queryParameters = QueryParameters({"Filter[user.email]": email});
    final collection = await fetchCollection("users", queryParameters: queryParameters);
    final l = collection.data.collection.where((element) => element.attributes["email"] == email).toList();
    if (l.length < 1)
      return false;
    final id = l[0].id;
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    Identifier member = Identifier("users", id);
    final response = await this.jsonApiClient.deleteFromToManyAt(uri,
        [member], headers: this._header);
    if (response.isFailed) {
      return false;
    }
    return true;
  }

  Future<bool> addMemberTo(String email, Uri uri) async {
    QueryParameters queryParameters = QueryParameters({"Filter[user.email]": email});
    final collection = await fetchCollection("users", queryParameters: queryParameters);
    final l = collection.data.collection.where((element) => element.attributes["email"] == email).toList();
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

  Future<bool> banGroupMember(String email, Identifier owner) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/groups/${owner.id}/relationships/members");
    return banMemberFrom(email, uri);
  }

  Future<bool> banOrganizationMember(String email, Identifier owner) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/organizations/${owner.id}/relationships/members");
    return banMemberFrom(email, uri);
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
    var resource;
    try {
       resource = response.data.unwrap();
    } catch (e) {
      resource = response.data.resourceObject;
    }
    this.user.attributes["firstName"] = resource.attributes["firstName"] as String;
    this.user.attributes["lastName"] = resource.attributes["lastName"] as String;

    var organizations = await getOrganization();
    for (var organization in organizations) {
      organization.groups = await getGroupGroup(organization.getIdentifier());
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
  Future<bool> createPasswordFromObject(Password password, Identifier owner) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets");

    final resource = Resource("secrets", "",
        attributes: {"content": password.serialize("")}, toOne: {"owner": owner});
    final test = await this.jsonApiClient.createResourceAt(uri, resource, headers: this._header);
    return test.isSuccessful;
  }


  /**
   * Here is the section handling passwords
   */
  // Register and encrypt new password on the server
  Future<bool> createPassword(String url, String email, String password, Identifier owner, SymmetricKey encryptionKey) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets");

    final blob = createBlob(url, email, password, encryptionKey);
    final resource = Resource("secrets", "",
      attributes: {"content": blob}, toOne: {"owner": owner});
    final test = await this.jsonApiClient.createResourceAt(uri, resource, headers: this._header);
    return test.isSuccessful;
  }

  // Register and encrypt new password on the server
  Future<bool> updatePassword(Password password, Identifier owner, SymmetricKey encryptionKey) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets/${password.id}");

    final resource = Resource("secrets", password.id,
        attributes: {"content": password.serialize(null /*encryptionKey.key*/)},
        );
    final test = await this.jsonApiClient.updateResourceAt(uri, resource, headers: this._header);
    return test.isSuccessful;
  }

  // Register and encrypt new password on the server
  Future<bool> deleteSecret(String id) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/secrets/${id}");
    final test = await this.jsonApiClient.deleteResourceAt(uri, headers: this._header);
    return test.isSuccessful;
  }

  // Register and encrypt new password on the server
  Future<bool> deletePassword(Password password) async {
    return await deleteSecret(password.id);
  }

  // Register and encrypt new password on the server
  Future<bool> deleteGroup(Group group) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/organizations/${group.id}/relationship/groups");
    final test = await this.jsonApiClient.deleteResourceAt(uri, headers: this._header);
    return test.isSuccessful;
  }

  Future<bool> deleteVault(Vault vault) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/organizations/${vault.id}/relationship/vaults");
    final test = await this.jsonApiClient.deleteResourceAt(uri, headers: this._header);
    return test.isSuccessful;
  }

  Future<bool> activateMFA(bool activate) async {
    this._header["Authorization"] = "Bearer ${this.user.jwt}";
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/users/${user.id}");
    final resource = Resource("users", user.id,
      attributes: {"mfaActivated": activate}
    );
    final test = await jsonApiClient.updateResourceAt(uri, resource, headers: this._header);
    user.mfa = test.isSuccessful ? activate: user.mfa;
    return test.isSuccessful;
  }

  /*
  * Create user on the server, needs the User object
   */
  Future<bool> createUser(User newUser, String nounce) async {
    final uri = Uri.parse("${this._url}:${this._port}/$api_version/users");
    final userResource = Resource("users", "",
        attributes: {"email": newUser.email, "password": lib.getDerivedKey(newUser.password),
          "firstName": newUser.attributes != null ? newUser.attributes["firstName"]: "",
          "lastName": newUser.attributes != null ? newUser.attributes["lastName"]: ""});
    final test = await this.jsonApiClient.createResourceAt(uri, userResource,
        meta: {"captcha": {"type": "reCAPTCHA-v2-android", "response": nounce}});
    if (test.isFailed)
      return false;
    newUser.id = test.data.resourceObject.id;
    bool connected = await connectUser(newUser.email, newUser.password);
    if (!connected)
      return false;
    final v = await createVault("\$master", newUser.getIdentifier(), null, null);
    return v != null;//await initUser();
  }

  Future<bool> initUser() async {
    final keyPair = new RSAKeyPair(lib, 2048);
    final publicKey = keyPair.createPublicKey();
    publicKey.initializePlain();
    final publicEncryptionKey = await this.createSecretSymmetric(publicKey,
        user.getIdentifier(), SymmetricKey(lib), visible: true);
    if (publicEncryptionKey == null)
      return false;
    user.publicKey = publicEncryptionKey;
    final privateKey = keyPair.createPrivateKey();
    privateKey.initializeSymmetric();
    final privateEncryptionKey = await this.createSecretSymmetric(privateKey, user.getIdentifier(), user.symmetricKey);
    if (privateEncryptionKey == null)
      return false;
    return await createEncryptionKeyUser(privateEncryptionKey.getIdentifier());
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
  String createBlob(String url, String email, String password, SymmetricKey encryptionKey) {
    hclw_password.Password secret = new hclw_password.Password(lib);
    secret.password = password;
    secret.domain = url;
    secret.name = url;
    secret.login = email;

    /*    secret.initializeSymmetric();
    return secret.serialize(encryptionKey.key);*/

    secret.initializePlain();
    return secret.serialize("");
  }

  Future<List<EncryptionKey>> getPassword() async {
  }

  Future<bool> getPasswordVault(Vault vault) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final response = await fetchCollection("vaults/${vault.id}/secrets");
    List<Password> res = [];

    if (response.isFailed)
      return false;
    for (var secret in response.data.collection) {
      if (secret.id == vault.encryptionKeyId)
        continue;
      final encryptedSecret = secret.attributes["content"];
//      final decryptedSecret = lib.deserializeSecret(vault.symmetricKey.asSymmetric().key, encryptedSecret);
      final decryptedSecret = lib.deserializeSecret("", encryptedSecret);
      if (decryptedSecret is hclw_password.Password)
        res.add(Password(decryptedSecret, secret.id));
    }
    vault.passwords = res;
    if (vault.name == "\$master") {
      List<Password> autofill = await getPasswordsFromAutofill(lib);
      print(autofill);
      if (autofill != null && autofill.length > 0) {
        vault.passwords.addAll(autofill);
        for (Password p in autofill) {
          await createPasswordFromObject(p, vault.getIdentifier());
        }
      }
    }
    return true;
  }

  Future<List<User>> getMembersFrom(Uri uri) async {
    this._header["Authorization"] = "bearer ${this.user.jwt}";
    final response = await this.jsonApiClient.fetchCollectionAt(uri, headers: this._header);
    if (response.isFailed) {
      return [];
    }
    List<User> res = [];
    for (var element in response.data.collection) {
      var u = User(element.attributes["email"], "", null);
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