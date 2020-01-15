

import 'dart:collection';

class User {
  String email;
  String id;
  String jwt;
  String password;
  HashMap<String, dynamic> attributes = HashMap();

  User(this.email, this.password);

}