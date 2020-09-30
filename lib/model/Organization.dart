

import 'dart:collection';

import 'package:harpokrat/model/Group.dart';
import 'package:json_api/document.dart';

import 'User.dart';

class Organization {
  String name;
  String id;
  List<Group> groups;
  List<User> members;

  Organization(this.name, this.id);

  Identifier getIdentifier() => Identifier("organizations", id);
}