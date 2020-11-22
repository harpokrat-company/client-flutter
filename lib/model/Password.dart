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

class Password {
  hclw_secret.Password _secret;
//  Secret secret;
  String id;
  Password(this._secret, this.id);

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
    return _secret.serialize(encryptionKey);
  }
}