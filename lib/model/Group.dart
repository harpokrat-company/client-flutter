

import 'dart:collection';

import 'package:harpokrat/controller/session.dart';
import 'package:json_api/document.dart';

import 'User.dart';
import 'Vault.dart';

class Group {
  String name;
  String id;
  List<User> members;
  List<Group> groups;
  List<Vault> vaults;

  Group(this.name, this.id);

  Identifier getIdentifier() => Identifier("groups", id);
  Future<bool> fetchData(Session session) async {
    this.groups = await session.getUserGroup(this.getIdentifier());
    this.vaults = await session.getUserVaults();
    this.members = await session.getGroupMembers(this.getIdentifier());
  }
}