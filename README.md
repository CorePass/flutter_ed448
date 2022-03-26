# thirds

SHA-3, BLAKE3, and EdDSA/Ed448 implementations in Dart, with EdDSA/Ed448 JWT support

## Installation

With Dart:
```sh
dart pub add thirds
```

With Flutter:
```sh
flutter pub add thirds
```

## Examples

```dart
import 'dart:convert';

import 'package:thirds/sha3.dart';
import 'package:thirds/blake3.dart';
import 'package:thirds/ed448.dart' as ed448;
import 'package:thirds/jwt.dart';

main() {
  // SHA-3/Keccak
  sha3_224Hex(utf8.encode("abc"));
  // "e642824c3f8cf24ad09234ee7d3c766fc9a3a5168d0c94ad73b46fdf"
  shake_128Hex(utf8.encode("abc"), 32);
  // "5881092dd818bf5cf8a3ddb793fbcba74097d5c526a6d35f97b83351940f2cc8"

  // BLAKE3
  blake3Hex(utf8.encode("abc"));
  // "6437b3ac38465133ffb63b75273a8db548c558465d79db03fd359c6cd5bd9d85"

  // EdDSA/Ed448
  final secret = ed448.parseKeyString(
    // Must be 114 bytes -- make sure to securely randomly generate for real
    "872d093780f5d3730df7c212664b37b8a0f24f56810daa8382cd4fa3f"
    "77634ec44dc54f1c2ed9bea86fafb7632d8be199ea165f5ad55dd9ce8"
  );
  final public = ed448.secretToPublic(secret);
  print("Public key is: ${ed448.toHexString(public)}");  // View public key
  final signature = ed448.sign(secret, utf8.encode("abc"));
  print("Signature is: ${ed448.toHexString(signature)}");
  assert(ed448.verify(public, utf8.encode("abc"), signature));

  // EdDSA/Ed448 JWT
  final secretHexString = (
    "d204c7a9585cca8fa52ff922946046be799a4595f7db24255d9cfbe0d"
    "d09056350a14d3fe705a5fa715528e4e4a3ba42990f7fdc77db266052"
  );
  final privateKey = OkpPrivateKey.fromSecret('Ed448', ed448.parseKeyString(secretHexString));
  final encoded = jwtEncode({'test': 'data'}, key: privateKey, algorithm: 'EdDSA');
  print("JWT: ${encoded}");
  // Verify and decode with private key
  assert(jwtDecode(encoded, key: privateKey, algorithm: 'EdDSA')['test'] == 'data');
  final publicKey = OkpPublicKey.fromPublic(
    'Ed448',
    ed448.secretToPublic(ed448.parseKeyString(secretHexString))
  );
  // Verify and decode with public key
  assert(jwtDecode(encoded, key: publicKey, algorithm: 'EdDSA')['test'] == 'data');
}
```

See tests for examples of additional supported functionality

## Running Tests

```sh
dart --enable-asserts test/all.dart
```

## License

`thirds` is dual-licensed under the BSD 3-Clause License and the Unlicense.

## Author

Michael P. Nitowski (Email: <mike@nitow.ski>)

## Contributing

Contributions are welcome.
