import 'package:harpokrat/model/EcryptionKey.dart';

import 'package:harpokrat/controller/session.dart';
import 'package:json_api/document.dart';

import 'User.dart';
import 'Vault.dart';

class Group {
  String name;
  String id;
  EncryptionKey privateKey;
  EncryptionKey publicKey;
  EncryptionKey parentPrivateKey;
  List<User> members;
  List<Group> groups;
  List<Vault> vaults;

  Group(this.name, this.id);

  Identifier getIdentifier() => Identifier("groups", id);
  Future<bool> fetchData(Session session) async {
    this.groups = await session.getGroupGroup(this.getIdentifier());
    this.vaults = await session.getGroupVaults(this);
    this.members = await session.getGroupMembers(this.getIdentifier());
  }
}