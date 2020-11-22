
import 'package:harpokrat/model/EcryptionKey.dart';
import 'package:harpokrat/model/Password.dart';
import 'package:json_api/document.dart';


class Vault {
  String name;
  String id;
  String encryptionKeyId;
  EncryptionKey symmetricKey;
  List<Password> passwords;

  Vault(this.name, this.id);

  Identifier getIdentifier() => Identifier("vaults", id);
}