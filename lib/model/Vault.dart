
import 'package:json_api/document.dart';
//import 'package:hclw_flutter/asecret.dart' as hclw_asecret;


class Vault {
  String name;
  String id;
//  List<hclw_secret> secrets;

  Vault(this.name, this.id);

  Identifier getIdentifier() => Identifier("groups", id);
}