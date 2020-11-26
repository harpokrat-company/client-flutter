import 'package:flutter/services.dart';
import 'package:harpokrat/controller/f_grecaptcha.dart';
import 'package:hclw_flutter/hclw_flutter.dart';
import 'package:hclw_flutter/password.dart' as hclw_secret;
/*class Secret {
  String name = "plop";
  String domain = "plop.com";
  String login = "Toto";
  String password = "aziodnazfn";
  String serialize(String a) {
    return a.toLowerCase();
  }
}*/

Future<List<Password>> getPasswordsFromAutofill(HclwFlutter lib) async {
  var passwordList = List<Password>();
  String canRetrieve = await FGrecaptcha.channel.invokeMethod("canRetrievePassword");
  print("AAAAAAAAAAAAAAAAAAA");
  while (canRetrieve == "true") {
    Map<String, String> response = await FGrecaptcha.channel.invokeMapMethod("retrievePassword");
    var secret = hclw_secret.Password(lib);
    secret.password = response["password"];
    secret.login = response["login"];
    secret.domain = response["domain"];
    passwordList.add(Password(secret, ""));
    canRetrieve = await FGrecaptcha.channel.invokeMethod("canRetrievePassword");
  }
  print("BBBBBBBBBBBBB");
  return passwordList;
}

class Password {
  hclw_secret.Password _secret;
//  Secret secret;
  String id;
  Password(this._secret, this.id) {
    FGrecaptcha.channel.invokeMethod("givePassword",
        {
          "password": _secret.password,
          "domain": _secret.domain,
          "login": _secret.login
        }
        );
  }

  get password {
    return _secret.password;
  }

  get name {
    return _secret.name;
  }

  get login {
    return _secret.login;
  }

  get domain {
    return _secret.domain;
  }

  set name(String name) {
    _secret.name = name;
  }

  set login(String login) {
    _secret.login = login;
  }

  set domain(String domain) {
    _secret.domain = domain;
  }

  set password(String password) {
    _secret.password = password;
  }

  update({String name, String login, String domain, String password}) {

    _secret.domain = domain;
    _secret.password = password;
  }


  String serialize(String encryptionKey) {
    _secret.initializePlain();
    return _secret.serialize(""/*encryptionKey*/);
  }
}