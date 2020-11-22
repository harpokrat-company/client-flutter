

import 'package:harpokrat/model/EcryptionKey.dart';
import 'package:json_api/document.dart';

class Owner {
  Owner(this.identifier, this.privateKey, this.publicKey);
  Identifier identifier;
  EncryptionKey publicKey;
  EncryptionKey privateKey;
}