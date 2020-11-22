import 'package:hclw_flutter/asecret.dart';
import 'package:hclw_flutter/hclw_flutter.dart';
import 'package:hclw_flutter/rsaprivatekey.dart';
import 'package:hclw_flutter/rsapublickey.dart';
import 'package:hclw_flutter/symmetrickey.dart';
import 'package:json_api/document.dart';

class EncryptionKey {
  String id;
  bool visible;
  String owner;
  dynamic aSecret;

  EncryptionKey(Resource resource, HclwFlutter lib, {SymmetricKey decryptionSymmetricKey, RSAPrivateKey decryptionAsymmetricKey}) {
    this.id = resource.id;
    visible = resource.attributes["visible"];
    final content = resource.attributes["content"];
    if (content == null)
        throw Exception("Unable to deserialize Secret");
    if (decryptionSymmetricKey != null)
      this.aSecret = lib.deserializeSecret(decryptionSymmetricKey.key, content);
    else if (decryptionAsymmetricKey != null)
      this.aSecret = lib.deserializeSecretAsymmetric(decryptionAsymmetricKey, content);
    else
      this.aSecret = lib.deserializeSecret("", content);
//    owner = aSecret.owner;
  }

  SymmetricKey asSymmetric() {
    if (aSecret is SymmetricKey)
      return aSecret;
    else
      throw Exception("Could not cast EncryptionKey as Symmetric");
  }

  RSAPublicKey asRSAPublic() {
    if (aSecret is RSAPublicKey)
      return aSecret;
    throw Exception("Could not cast EncryptionKey as RSAPublic");
  }

  RSAPrivateKey asRSAPrivate() {
    if (aSecret is RSAPrivateKey)
      return aSecret;
    throw Exception("Could not cast EncryptionKey as RSAPrivate");
  }

  Resource serialize(String key) {
    aSecret.initializeSymmetric();
    return Resource(
      "secrets", id, attributes: {"visible": visible, "content": aSecret.serialize(key)}
    );
  }

  Resource serializeAsymetric(RSAPublicKey key) {
    aSecret.initializeAsymmetric();
    return Resource(
        "secrets", id, attributes: {"visible": visible, "content": aSecret.serializeAsymmetric(key)}
    );
  }

  Identifier getIdentifier() => Identifier("secret", id);
}