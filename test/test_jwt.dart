import 'dart:io';

import '../lib/ed448.dart' as ed448;
import '../lib/jwt.dart';

test() {
  final secretHexString = 'd204c7a9585cca8fa52ff922946046be799a4595f7db24255d9cfbe0dd09056350a14d3fe705a5fa715528e4e4a3ba42990f7fdc77db266052';

  final privateKey = OkpPrivateKey.fromSecret('Ed448', ed448.parseKeyString(secretHexString));

  final encoded = jwtEncode({'test': 'data'}, key: privateKey, algorithm: 'EdDSA');
  print(encoded);
  assert(
    encoded == 'eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJ0ZXN0IjoiZGF0YSJ9.yC2oveTAJmBTp3kITJvHTm3yTDwfnWKFr7aFKXp9NCSG5_rMusTtDZyWfQwzvKy53N8BjG5733IAtxKezlNaWvUINdYhGMQ4VNXOivDe58frtbyBBRGI5AUvl2NQVY4uSYE1Nw-d_9E40jtPZxGDjCUA',
    "jwtEncode did not produce expected value"
  );

  try {
    jwtDecode(encoded, key: OkpPrivateKey.fromSecret('Ed448', ed448.generateSecret()), algorithm: 'EdDSA');
    assert(false, "JWT verification did not expectedly fail");
  } on InvalidToken {
    print("JWT verification expectedly failed");
  }

  final decodedWithPrivateKey = jwtDecode(encoded, key: privateKey, algorithm: 'EdDSA');
  assert(decodedWithPrivateKey.length == 1, "jwtDecode with private key did not produce expected value");
  assert(decodedWithPrivateKey['test'] == 'data', "jwtDecode with private key did not produce expected value");

  final publicKey = OkpPublicKey.fromPublic(
    'Ed448',
    ed448.secretToPublic(ed448.parseKeyString(secretHexString))
  );

  final decodedWithPublicKey = jwtDecode(encoded, key: publicKey, algorithm: 'EdDSA');
  assert(decodedWithPublicKey.length == 1, "jwtDecode with public key did not produce expected value");
  assert(decodedWithPublicKey['test'] == 'data', "jwtDecode with public key did not produce expected value");

  final anotherEncoded = (
    'eyJhbGciOiJFZERTQSIsImtpZCI6ImtDNFlEMTR2MjE4Nllma2FoTU9SV25RaUluc2xCcnZsU0VFb1ktVnVXN1UifQ.eyJ0ZXN0IjoiZGF0YSIsImlhdCI6MTU4OTk3ODY0Nn0.El5QWyTWj8ifde9ttzC0-dXoxb9-gQrps1gfgVegFy7kL_PIcjQg-LNnJD98LshBKb9LwK7B9fQAmaxoz0PzsxEWorRdR3wiW3W1hkBASVMoGz9ZByydgj5lRvLoKm9zb8akcw-o1IRfB4ekQPbvkC4A'
  );

  final anotherDecoded = jwtDecode(anotherEncoded, algorithm: 'EdDSA', key: publicKey);
  assert(anotherDecoded.length == 2, "Another jwtDecode with public key did not produce expected value");
  assert(anotherDecoded['test'] == 'data', "Another jwtDecode with public key did not produce expected value");
  assert(anotherDecoded['iat'] is int, "Another jwtDecode with public key did not produce expected value");

  final encodedWithNbf = jwtEncode({'test': 'data', 'nbf': (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) + 2}, algorithm: 'EdDSA', key: privateKey);
  print(encodedWithNbf);

  try {
    jwtDecode(encodedWithNbf, algorithm: 'EdDSA', key: publicKey);
    assert(false, "Token with nbf is unexpectedly valid");
  } on NotYetValidToken {
    print("Token is expectedly not yet valid");
  }

  sleep(Duration(seconds: 2));
  print(jwtDecode(encodedWithNbf, algorithm: 'EdDSA', key: publicKey));

  final encodedWithExp = jwtEncode({'test': 'data', 'exp': (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) + 2}, algorithm: 'EdDSA', key: privateKey);
  print(jwtDecode(encodedWithExp, algorithm: 'EdDSA', key: publicKey));

  sleep(Duration(seconds: 2));
  try {
    jwtDecode(encodedWithExp, algorithm: 'EdDSA', key: publicKey);
    assert(false, "Token with exp is unexpectedly expired");
  } on ExpiredToken {
    print("Token with exp is expectedly expired");
  }

  final encodedWithDtIat = jwtEncode({'test': 'data', 'iat': DateTime.now()}, algorithm: 'EdDSA', key: privateKey);
  final decodedWithDtIat = jwtDecode(encodedWithDtIat, algorithm: 'EdDSA', key: publicKey);
  print(encodedWithDtIat);
  print(decodedWithDtIat);
  assert(decodedWithDtIat['iat'] is int, "jwtEncode/jwtDecode with DateTime iat failed to present iat as NumericDate");

  final privateKeyWithKid = OkpPrivateKey.fromSecret('Ed448', ed448.generateSecret(), 'testKey');
  final encodedWithKeyWithKid = jwtEncode({'test': 'data'}, key: privateKeyWithKid, algorithm: 'EdDSA');

  final decodedHeader = jwtDecodeUnverifiedHeader(encodedWithKeyWithKid);
  print(decodedHeader);
  assert(decodedHeader['kid'] == 'testKey');

  assert(
    jwtDecode(encodedWithKeyWithKid, key: privateKeyWithKid, algorithm: 'EdDSA')['test']
    == 'data', "jwtDecode with private key with kid did not produce expected value"
  );
}

main() {
  test();
}
