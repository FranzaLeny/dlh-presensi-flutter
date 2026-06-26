// ====================================
// Crypto Utilities — RSA Keypair & Signature
// ====================================

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart';

/// Hasil generate keypair RSA dalam format PEM.
class KeyPairPem {
  final String publicKeyPem;
  final String privateKeyPem;

  const KeyPairPem({
    required this.publicKeyPem,
    required this.privateKeyPem,
  });
}

/// Menghasilkan SecureRandom untuk pointycastle.
SecureRandom _secureRandom() {
  final secureRandom = FortunaRandom();
  final random = Random.secure();
  final seeds = List<int>.generate(32, (_) => random.nextInt(256));
  secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
  return secureRandom;
}

/// Menghasilkan keypair RSA dan mengembalikan dalam format PEM.
/// Menggunakan RSA 1024-bit secara bawaan untuk kecepatan di perangkat seluler.
KeyPairPem generateKeyPair({int bits = 1024}) {
  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.from(65537), bits, 64),
      _secureRandom(),
    ));

  final pair = keyGen.generateKeyPair();
  final publicKey = pair.publicKey as RSAPublicKey;
  final privateKey = pair.privateKey as RSAPrivateKey;

  return KeyPairPem(
    publicKeyPem: _encodePublicKeyToPem(publicKey),
    privateKeyPem: _encodePrivateKeyToPem(privateKey),
  );
}

/// Melakukan tanda tangan pada payload menggunakan RSA-SHA256
/// dan mengembalikan signature berbasis base64.
String signPayload(dynamic payload, String privateKeyPem) {
  final privateKey = _decodePrivateKeyFromPem(privateKeyPem);

  final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
  signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

  final jsonBytes = utf8.encode(jsonEncode(payload));
  final signature =
      signer.generateSignature(Uint8List.fromList(jsonBytes)) as RSASignature;

  return base64Encode(signature.bytes);
}

// ── PEM Encoding Helpers ──────────────────────────────────────────

String _encodePublicKeyToPem(RSAPublicKey publicKey) {
  final algorithmSequence = ASN1Sequence()
    ..add(ASN1ObjectIdentifier.fromName('rsaEncryption'))
    ..add(ASN1Null());

  final publicKeySequence = ASN1Sequence()
    ..add(ASN1Integer(publicKey.modulus!))
    ..add(ASN1Integer(publicKey.exponent!));

  final publicKeyDer = publicKeySequence.encodedBytes;
  final publicKeyBitString = ASN1BitString(publicKeyDer);

  final topLevelSequence = ASN1Sequence()
    ..add(algorithmSequence)
    ..add(publicKeyBitString);

  final encoded = base64Encode(topLevelSequence.encodedBytes);
  return '-----BEGIN PUBLIC KEY-----\n$encoded\n-----END PUBLIC KEY-----';
}

String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
  final sequence = ASN1Sequence()
    ..add(ASN1Integer(BigInt.zero)) // version
    ..add(ASN1Integer(privateKey.n!)) // modulus
    ..add(ASN1Integer(privateKey.publicExponent!)) // publicExponent
    ..add(ASN1Integer(privateKey.privateExponent!)) // privateExponent
    ..add(ASN1Integer(privateKey.p!)) // prime1
    ..add(ASN1Integer(privateKey.q!)) // prime2
    ..add(ASN1Integer(
        privateKey.privateExponent! % (privateKey.p! - BigInt.one))) // exp1
    ..add(ASN1Integer(
        privateKey.privateExponent! % (privateKey.q! - BigInt.one))) // exp2
    ..add(ASN1Integer(privateKey.q!.modInverse(privateKey.p!))); // coeff

  final encoded = base64Encode(sequence.encodedBytes);
  return '-----BEGIN RSA PRIVATE KEY-----\n$encoded\n-----END RSA PRIVATE KEY-----';
}

RSAPrivateKey _decodePrivateKeyFromPem(String pem) {
  final rows = pem.split('\n');
  final base64String = rows
      .where((r) => !r.startsWith('-----'))
      .join('');
  final bytes = base64Decode(base64String);

  final asn1Parser = ASN1Parser(Uint8List.fromList(bytes));
  final topLevelSequence = asn1Parser.nextObject() as ASN1Sequence;
  final elements = topLevelSequence.elements!;

  final modulus = (elements[1] as ASN1Integer).valueAsBigInteger;
  final privateExponent = (elements[3] as ASN1Integer).valueAsBigInteger;
  final p = (elements[4] as ASN1Integer).valueAsBigInteger;
  final q = (elements[5] as ASN1Integer).valueAsBigInteger;

  return RSAPrivateKey(modulus, privateExponent, p, q);
}
