

import 'dart:collection';

import 'package:harpokrat/model/Organization.dart';
import 'package:harpokrat/model/Vault.dart';
import 'package:json_api/document.dart';

class User {
  String email;
  String id;
  String jwt;
  String password;
  List<Organization> organizations;
  List<Vault> vaults = [];
  HashMap<String, dynamic> attributes = HashMap();

  User(this.email, this.password);

  Organization getOrganization(String name) {
    for (var o  in organizations)
      if (o.name == name)
        return o;
      return null;
  }

  Identifier getIdentifier() => Identifier("users", id);
}