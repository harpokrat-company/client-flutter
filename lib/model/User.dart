

import 'dart:collection';

import 'package:harpokrat/model/EcryptionKey.dart';
import 'package:harpokrat/model/Organization.dart';
import 'package:harpokrat/model/Vault.dart';
import 'package:hclw_flutter/symmetrickey.dart';
import 'package:json_api/document.dart';

import 'Owner.dart';

class User {
  String email;
  String id;
  String jwt;
  String encryptionKeyId;
  bool mfa = false;
  String mfaId;
  SymmetricKey symmetricKey;
  EncryptionKey publicKey;
  EncryptionKey privateKey;
  String password;
  List<EncryptionKey> groupKeys = [];
  List<Organization> organizations;
  List<Vault> vaults = [];
  HashMap<String, dynamic> attributes = HashMap();

  User(this.email, this.password, this.symmetricKey);

  Organization getOrganization(String name) {
    for (var o  in organizations)
      if (o.name == name)
        return o;
      return null;
  }

  Owner asOwner() {
    return Owner(getIdentifier(), privateKey, publicKey);
  }

  Identifier getIdentifier() => Identifier("users", id);
}