import 'package:hclw_flutter/secret.dart' as hclw_secret;
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
  hclw_secret.Secret secret;
//  Secret secret;
  String id;
  Password(this.secret, this.id);
}