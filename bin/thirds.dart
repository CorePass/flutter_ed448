import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:thirds/ed448.dart' as ed448;
import 'package:thirds/jwt.dart';

int main(List<String> arguments) {
  if(arguments.length <= 0) {
    print("Thirds");
    print("Try gen_key_pair and create_jwt");
    return 0;
  }

  if (arguments.first == "gen_key_pair") {
    var random = Random.secure();
    var secret = List<int>.generate(57, (_) => random.nextInt(256));
    var public = ed448.secretToPublic(secret);

    print(
      "private key: ${ed448.toHexString(secret)}\n"
      " public key: ${ed448.toHexString(public)}"
    );
    return 0;
  }

  if (arguments.first == "create_jwt") {
    if (arguments.length < 2) {
      stderr.writeln("Must provide private key/secret as argument");
      return -1;
    }

    var secretAsHex = arguments[1];

    String? jsonData = stdin.readLineSync();
    if (jsonData == null) {
      stderr.writeln("Must provide JSON data from stdin");
      return -1;
    }

    Map<String, dynamic> data;
    try {
      data = json.decode(jsonData);
    } catch (e) {
      stderr.writeln("Must provide valid JSON data from stdin");
      return -1;
    }

    print(
      jwtEncode(
        data,
        algorithm: "EdDSA",
        key: OkpPrivateKey.fromSecret("Ed448", ed448.parseKeyString(secretAsHex))
      )
    );
  }

  return 0;
}
