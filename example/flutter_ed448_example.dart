import 'dart:convert';

import 'package:flutter_ed448/blake3.dart';
import 'package:flutter_ed448/ed448.dart' as ed448;
import 'package:flutter_ed448/jwt.dart';
import 'package:flutter_ed448/sha3.dart';

void main() {
  print(sha3_256Hex(utf8.encode('hello')));
  print(blake3Hex(utf8.encode('hello')));

  final secret = ed448.generateSecret();
  final publicKey = ed448.secretToPublic(secret);
  final signature = ed448.sign(secret, utf8.encode('hello'));

  print(ed448.verify(publicKey, utf8.encode('hello'), signature));

  final privateKey = OkpPrivateKey.fromSecret('Ed448', secret);
  final token = jwtEncode(
    {'sub': 'demo', 'iat': DateTime.now().toUtc()},
    algorithm: 'EdDSA',
    key: privateKey,
  );

  print(token);
}
