import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import './sha3.dart';

import './src/format.dart';

// Ed448 flavor of the Edwards-Curve Digital Signature Algorithm (EdDSA)
// Implemented according to RFC 8032 (https://tools.ietf.org/html/rfc8032)
// Heavily based on the reference implementations presented in RFC 8032

final KEY_LENGTH = 57;
final SIGNATURE_LENGTH = 114;

List<int> _toLE(BigInt n, int numBytes) {
  final List<int> bytes = [];
  for (int i = 0; i < numBytes; i++) {
    bytes.add(((n >> (8 * i)) & BigInt.from(0xFF)).toInt());
  }

  return bytes;
}

BigInt _asLE(List<int> bytes) {
  BigInt n = BigInt.zero;
  for (final int b in bytes.reversed) {
    n = (n << 8) | BigInt.from(b);
  }
  return n;
}

BigInt p = BigInt.two.pow(448) - BigInt.two.pow(224) - BigInt.one;

BigInt d = BigInt.from(-39081);

BigInt q = (
  BigInt.two.pow(446)
  - BigInt.parse(
    '13818066809895115352007386748515426880336692474882178609894547503885'
  )
);

List<BigInt> _pointAdd(List<BigInt> P, List<BigInt> Q) {
  final xcp = (P[0] * Q[0]) % p;
  final ycp = (P[1] * Q[1]) % p;
  final zcp = (P[2] * Q[2]) % p;

  final B = (zcp * zcp) % p;
  final E = (((d * xcp) % p) * ycp) % p;
  final F = ((B - E) % p) % p;
  final G = ((B + E) % p) % p;
  final H = ((P[0] + P[1]) % p) * ((Q[0] + Q[1]) % p) % p;

  return [
    ((((zcp * F) % p) * (p + ((p + (H - xcp) % p) - ycp) % p)) % p) % p,
    (zcp * G * (ycp - xcp)) % p,
    (F * G) % p
  ];
}

List<BigInt> _pointDouble(List<BigInt> P) {
  final xsq = (P[0] * P[0]) % p;
  final ysq = (P[1] * P[1]) % p;
  final zsq = (P[2] * P[2]) % p;

  final xplusy = (P[0] + P[1]) % p;
  final F = ((xsq + ysq) % p) % p;
  final J = (F - ((zsq + zsq) % p)) % p;

  return [
    ((((p + (p + (((xplusy * xplusy) % p) - xsq) % p) - ysq)) % p) * J) % p,
    (F * (xsq - ysq)) % p,
    (F * J) % p
  ];
}

List<BigInt> _pointMultiply(BigInt x, List<BigInt> P) {
  var Q = [BigInt.zero, BigInt.one, BigInt.one];
  while (x > BigInt.zero) {
    if ((x % BigInt.two) > BigInt.zero) {
      Q = _pointAdd(Q, P);
    }
    P = _pointDouble(P);
    x = x ~/ BigInt.two;
  }
  return Q;
}

bool _pointEqual(List<BigInt> P, List<BigInt> Q) {
  final A = P[0] * Q[2] % p;
  final B = Q[0] * P[2] % p;
  final C = P[1] * Q[2] % p;
  final D = Q[1] * P[2] % p;

  return A == B && C == D;
}

final _modpSqrtM1 = BigInt.two.modPow((p - BigInt.one) ~/ BigInt.from(4), p);

BigInt? _recoverX(BigInt y, BigInt sign) {
  if (y >= p) {
    return null;
  }

  final x2 = (y * y - BigInt.one) * (d * y * y - BigInt.one).modInverse(p);
  if (x2 == 0) {
    if (sign > BigInt.zero) {
      return null;
    } else {
      return BigInt.zero;
    }
  }

  // Calculate square root of x2
  var x = x2.modPow((p + BigInt.one) ~/ BigInt.from(4), p);
  if ((x*x - x2) % p != BigInt.zero) {
    x = x * _modpSqrtM1 % p;
  }

  if ((x*x - x2) % p != BigInt.zero) {
    return null;
  }

  if ((x & BigInt.one) != sign) {
    x = p - x;
  }

  return x;
}

List<int> _pointCompress(List<BigInt> P) {
  final zInv = P[2].modInverse(p);
  final x = P[0] * zInv % p;
  final y  = P[1] * zInv % p;
  return _toLE(y | ((x & BigInt.one) << 455), 57);
}

List<BigInt>? _pointDecompress(List<int> s) {
  if (s.length != 57) {
    throw FormatException("Invalid input length for decompression");
  }

  var y = _asLE(s);

  final sign = y >> 455;

  y &= (BigInt.one << 455) - BigInt.one;

  final x = _recoverX(y, sign);
  if (x == null) {
      return null;
  }

  return [x, y, BigInt.one];
}

final _gY = BigInt.parse(
  '0x693F46716EB6BC248876203756C9C7624BEA73736CA3984087789C1'
  'E05A0C2D73AD3FF1CE67C39C4FDBD132C4ED7C8AD9808795BF230FA14'
);
final _gX = _recoverX(_gY, BigInt.zero);
final _G = [_gX!, _gY, BigInt.one];

List<int> _clamp(List<int> a) {
  for (int i = 0; i < 2; i++) {
    a[i ~/ 8] &= ~(1 << (i % 8));
  }

  a[447 ~/ 8] |= 1 << (447 % 8);

  for (int i = 447 + 1; i < 456; i++) {
    a[i ~/ 8] &= ~(1 << (i % 8));
  }

  return a;
}

List<dynamic> _secretExpand(List<int> secret) {
  if (secret.length != 57) {
    throw FormatException("Bad size of private key");
  }

  final h = shake_256(secret, 114);
  var t = <int>[]..addAll(h);

  t = _clamp(t);

  var s = _asLE(t.sublist(0, 57));

  return [s, h.sublist(57)];
}

List<int> generateSecret() {
  final secret = Uint8List(57);

  final secureRandom = Random.secure();

  for (int i = 0; i < 57; i++) {
    final b = secureRandom.nextInt(256);
    assert(b >= 0 && b < 256);
    secret[i] = b;
  }

  return UnmodifiableUint8ListView(secret);
}

List<int> parseKeyString(String s) {
  if (s.length != 114) {
    throw FormatException("Bad key string length");
  }

  final l = Uint8List(57);
  for (int i = 0; i < 57; i++) {
    l[i] = int.parse(s[i * 2] + s[i * 2 + 1], radix: 16);
  }

  return UnmodifiableUint8ListView(l);
}

String toHexString(List<int> bytes) {
  return asHexString(bytes);
}

List<int> secretToPublic(List<int> secret) {
  final expanded = _secretExpand(secret);
  return UnmodifiableUint8ListView(
    Uint8List.fromList(_pointCompress(_pointMultiply(expanded[0], _G)))
  );
}

typedef ED448_XOF = List<int> Function(List<int> message, int outputLength);

BigInt _xofModQ(ED448_XOF xof, List<int> message, int outputLength) {
  return _asLE(xof(message, outputLength)) % q;
}

final List<int> MARKER = ascii.encode('SigEd448');

List<int> sign(List<int> secret, List<int> message, {ED448_XOF xof = shake_256}) {
  final expanded = _secretExpand(secret);
  final a = expanded[0];
  final prefix = expanded[1];
  final A = _pointCompress(_pointMultiply(a, _G));
  final r =  _xofModQ(xof, MARKER + [0] + [0] + prefix + message, 114);
  final R = _pointMultiply(r, _G);
  final Rs = _pointCompress(R);
  final h = _xofModQ(xof, MARKER + [0] + [0] + Rs + A + message, 114);
  final s = (r + h * a) % q;

  return UnmodifiableUint8ListView(Uint8List.fromList(Rs + _toLE(s, 57)));
}

bool verify(
  List<int> public,
  List<int> message,
  List<int> signature,
  {ED448_XOF xof = shake_256}
) {
  if (public.length != 57) {
    throw FormatException("Bad public key length");
  }

  if (signature.length != 114) {
    throw FormatException("Bad signature length");
  }

  final A = _pointDecompress(public);
  if (A == null) {
    return false;
  }

  final Rs = signature.sublist(0, 57);
  final R = _pointDecompress(Rs);
  if (R == null) {
      return false;
  }

  final s = _asLE(signature.sublist(57, 114));
  if (s >= q) {
    return false;
  }

  final h = _xofModQ(xof, MARKER + [0] + [0] + Rs + public + message, 114);
  var sB = _pointMultiply(s, _G);
  var hA = _pointMultiply(h, A);

  return _pointEqual(sB, _pointAdd(R, hA));
}
