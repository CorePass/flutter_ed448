# flutter_ed448

`flutter_ed448` is a Flutter-compatible Dart cryptography package that provides:

- SHA-3 and SHAKE hashing helpers
- BLAKE3 hashing
- EdDSA/Ed448 signing and verification
- Ed448-backed JWT encoding and decoding helpers

The package is pure Dart, so it works in both Dart and Flutter projects.

## Installation

With Dart:

```sh
dart pub add flutter_ed448
```

With Flutter:

```sh
flutter pub add flutter_ed448
```

## Quick Start

```dart
import 'dart:convert';

import 'package:flutter_ed448/flutter_ed448.dart';
import 'package:flutter_ed448/ed448.dart' as ed448;

void main() {
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
    // Must be 57 bytes -- make sure to securely randomly generate for real
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

See [test/flutter_ed448_test.dart](test/flutter_ed448_test.dart) for compatibility vectors and edge-case coverage.

## Running Tests

```sh
dart test
dart --enable-asserts run test/all.dart
```

## Release Process

```sh
dart pub get
dart analyze
dart test
dart --enable-asserts run test/all.dart
dart pub publish --dry-run
git tag <version>
git push origin <version>
```

After pushing the version tag, publish a GitHub release for the same tag, for example `0.2.0`.

The workflows are split as follows:

- Publishing a GitHub release runs the repository `Release` workflow.
- Pushing a matching version tag runs the `Publish to pub.dev` workflow.

The pub.dev publish step must stay tag-triggered. Dart's official automated publishing flow only allows GitHub Actions publishing when the workflow was triggered by a pushed git tag, not only by a GitHub release event.

If `flutter_ed448` is being published to pub.dev for the first time, the initial release must still be published manually. After that, automated publishing can be enabled for this repository on pub.dev using the plain version tag pattern `{{version}}`.

## Licensing

`flutter_ed448` is licensed under the BSD 3-Clause License.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
