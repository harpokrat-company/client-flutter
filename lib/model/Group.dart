

import 'dart:collection';

import 'package:json_api/document.dart';

import 'User.dart';
import 'Vault.dart';

class Group {
  String name;
  String id;
  List<User> users;
  List<Group> groups;
  List<Vault> vaults;

  Group(this.name, this.id);

  Identifier getIdentifier() => Identifier("groups", id);
}