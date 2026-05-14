import 'dart:math';
import 'dart:typed_data';

import 'ed448.dart' as ed448;
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/pointycastle.dart';

export 'ed448.dart';

Uint8List _bytes(List<int> value) => Uint8List.fromList(value);

Uint8List _secretScalarForHdPrivateKey(List<int> privateKey) {
  if (privateKey.length != ed448.KEY_LENGTH) {
    throw FormatException('Bad private key length');
  }

  final scalar = Uint8List.fromList(privateKey);
  scalar[ed448.KEY_LENGTH - 1] = 0;
  scalar[ed448.KEY_LENGTH - 2] |= 0x80;
  scalar[0] &= 0xfc;
  return scalar;
}

Uint8List ed448GenerateKey() {
  final privateKey = Uint8List(ed448.KEY_LENGTH);
  final random = Random.secure();
  for (var i = 0; i < privateKey.length; i++) {
    privateKey[i] = random.nextInt(256);
  }
  privateKey[ed448.KEY_LENGTH - 1] &= 0x7f;
  return privateKey;
}

Uint8List ed448DerivePublicKey(Uint8List privateKey) {
  if (privateKey.length != ed448.KEY_LENGTH) {
    throw FormatException('Bad private key length');
  }

  if ((privateKey[ed448.KEY_LENGTH - 1] & 0x80) == 0) {
    return _bytes(ed448.secretToPublic(privateKey));
  }

  final scalar = _secretScalarForHdPrivateKey(privateKey);
  return _bytes(ed448.secretToPublicFromScalar(scalar));
}

Uint8List ed448Sign(Uint8List privateKey, Uint8List message) {
  if (privateKey.length != ed448.KEY_LENGTH) {
    throw FormatException('Bad private key length');
  }

  if ((privateKey[ed448.KEY_LENGTH - 1] & 0x80) == 0) {
    return _bytes(ed448.sign(privateKey, message));
  }

  final scalar = _secretScalarForHdPrivateKey(privateKey);
  return _bytes(ed448.signWithScalar(scalar, scalar, message));
}

bool ed448Verify(
  Uint8List publicKey,
  Uint8List message,
  Uint8List signature,
) {
  return ed448.verify(publicKey, message, signature);
}

Uint8List secretToPublicFromScalar(Uint8List scalar) {
  return _bytes(ed448.secretToPublicFromScalar(scalar));
}

Uint8List signWithScalar(
  Uint8List scalar,
  Uint8List noncePrefix,
  Uint8List message,
) {
  return _bytes(ed448.signWithScalar(scalar, noncePrefix, message));
}

class Ed448HDWallet {
  Uint8List SHA512Hash(Uint8List password, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(Mac('SHA3-512/HMAC'));
    derivator.reset();
    derivator.init(Pbkdf2Parameters(salt, 2048, ed448.KEY_LENGTH));
    return derivator.process(password);
  }

  Uint8List seedToExtendedPrivate(Uint8List seed) {
    final hashChain = Uint8List.fromList('mnemonicforthechain'.codeUnits);
    final hashSeed = Uint8List.fromList('mnemonicforthekey'.codeUnits);
    final s1 = SHA512Hash(seed, hashChain);
    final s2 = SHA512Hash(seed, hashSeed);
    s2[56] |= 0x80;
    s2[55] |= 0x80;
    s2[55] &= 0xbf;

    final result = Uint8List(114);
    result.setRange(0, 57, s1);
    result.setRange(57, 114, s2);
    return result;
  }

  Uint8List toExtendedPublic(Uint8List extendedPrivate) {
    final private = Uint8List.fromList(extendedPrivate.sublist(57, 114));
    final public = ed448DerivePublicKey(private);

    final extendedPublic = Uint8List(114);
    extendedPublic.setRange(0, 57, extendedPrivate.sublist(0, 57));
    extendedPublic.setRange(57, 114, public);
    return extendedPublic;
  }

  Uint8List concatenateAndHex(
    int prefix,
    Uint8List key,
    int index,
    Uint8List salt,
  ) {
    final input = Uint8List(62);
    input[0] = prefix % 256;
    input.setRange(1, 58, key);
    for (var i = 0; i < 4; i++) {
      input[i + 58] = index % 256;
      index = index ~/ 256;
    }
    return SHA512Hash(input, salt);
  }

  Uint8List addScalar(Uint8List a, Uint8List b) {
    final b1 = Uint8List.fromList(b);
    for (var i = 53; i < 57; i++) {
      b1[i] = 0;
    }
    b1[0] &= 0xfc;

    final c = Uint8List(57);
    var hold = 0;
    for (var i = 0; i < 57; i++) {
      hold += a[i] + b1[i];
      c[i] = hold % 256;
      hold = hold ~/ 256;
    }
    return c;
  }

  Uint8List childPrivateToPrivate(Uint8List extended, int index) {
    final chain = Uint8List.fromList(extended.sublist(0, 57));
    final key = Uint8List.fromList(extended.sublist(57, 114));

    late Uint8List r0;
    late Uint8List r1;
    if (index >= 0x80000000) {
      r0 = concatenateAndHex(1, key, index, chain);
      r1 = concatenateAndHex(0, key, index, chain);
    } else {
      final pub = ed448DerivePublicKey(key);
      r0 = concatenateAndHex(3, pub, index, chain);
      r1 = concatenateAndHex(2, pub, index, chain);
    }

    final r2 = addScalar(key, r1);
    final result = Uint8List(114);
    result.setRange(0, 57, r0);
    result.setRange(57, 114, r2);
    return result;
  }

  Uint8List HDWalletGenerateKey(Uint8List seed, int index) {
    final m = seedToExtendedPrivate(seed);
    final k1 = childPrivateToPrivate(m, 0x80000000 + 44);
    final k2 = childPrivateToPrivate(k1, 0x80000000 + 654);
    final k3 = childPrivateToPrivate(k2, 0x80000000);
    final k4 = childPrivateToPrivate(k3, 0x80000000);
    final k5 = childPrivateToPrivate(k4, index);
    return Uint8List.fromList(k5.sublist(57, 114));
  }

  Uint8List ed448GenerateKey() {
    return coreEd448GenerateKey();
  }

  Uint8List ed448DerivePublicKey(Uint8List privateKeyBytes) {
    return coreEd448DerivePublicKey(privateKeyBytes);
  }

  Uint8List ed448Sign(Uint8List privateKeyBytes, Uint8List message) {
    return coreEd448Sign(privateKeyBytes, message);
  }

  bool ed448Verify(
    Uint8List publicKeyBytes,
    Uint8List message,
    Uint8List signature,
  ) {
    return coreEd448Verify(publicKeyBytes, message, signature);
  }
}

Uint8List coreEd448GenerateKey() => ed448GenerateKey();

Uint8List coreEd448DerivePublicKey(Uint8List privateKey) {
  return ed448DerivePublicKey(privateKey);
}

Uint8List coreEd448Sign(Uint8List privateKey, Uint8List message) {
  return ed448Sign(privateKey, message);
}

bool coreEd448Verify(
  Uint8List publicKey,
  Uint8List message,
  Uint8List signature,
) {
  return ed448Verify(publicKey, message, signature);
}
