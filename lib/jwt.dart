import 'dart:convert';

import './ed448.dart' as ed448;

abstract class Key {
  final String? kid;
  String get kty;

  Key(this.kid);
}

abstract class OkpKey extends Key {
  final String kty = 'OKP';
  final String crv;
  final String x;

  OkpKey({crv, x, kid}): this.crv = crv, this.x = x, super(kid);
}

class OkpPublicKey extends OkpKey {
  OkpPublicKey({crv, x, kid}): super(crv: crv, x: x, kid: kid);

  factory OkpPublicKey._ed448FromPublic(dynamic public, [kid]) {
    public = public is List<int> ? public : ed448.parseKeyString(public);

    if (public.length != 57) {
      throw FormatException("Ed448 key length must be 57");
    }

    return OkpPublicKey(
      crv: 'Ed448',
      x: base64Url.encode(public),
      kid: kid
    );
  }

  factory OkpPublicKey.fromPublic(String curve, dynamic public, {kid}) {
    if (curve == 'Ed448') {
      return OkpPublicKey._ed448FromPublic(public, kid);
    } else {
      throw UnsupportedError("Curve is currently unsupported");
    }
  }
}

class OkpPrivateKey extends OkpKey {
  final String d;

  OkpPrivateKey({crv, x, d, kid}): this.d = d, super(crv: crv, x: x, kid: kid);

  factory OkpPrivateKey._ed448FromSecret(dynamic secret, [kid]) {
    secret = secret is List<int> ? secret : ed448.parseKeyString(secret);

      if (secret.length != 57) {
        throw FormatException("Ed448 key length must be 57");
      }
      return OkpPrivateKey(
        crv: 'Ed448',
        x: base64Url.encode(ed448.secretToPublic(secret)),
        d: base64Url.encode(secret),
        kid: kid,
      );
  }

  factory OkpPrivateKey.fromSecret(String curve, dynamic secret, [kid]) {
    if (curve == 'Ed448') {
      return OkpPrivateKey._ed448FromSecret(secret, kid);
    } else {
      throw UnsupportedError("Curve is currently unsupported");
    }
  }
}

class InvalidToken implements Exception {
  final type;
  final message;

  InvalidToken._(this.type, this.message);

  InvalidToken(message): this._('InvalidToken', message);

  @override
  toString() {
    return '${this.type}: ${this.message}';
  }
}

class InvalidSignature extends InvalidToken {
  InvalidSignature(message): super._('InvalidSignature', message);
}

class NotYetValidToken extends InvalidToken {
  NotYetValidToken(message): super._('NotYetValidToken', message);
}

class ExpiredToken extends InvalidToken {
  ExpiredToken(message): super._('ExpiredToken', message);
}

class MalformedClaim extends InvalidToken {
  MalformedClaim(message): super._('MalformedClaim', message);
}

String _encode(Map<String, dynamic> m) {
  return base64Url.encode(utf8.encode(json.encode(m))).replaceAll('=', '');
}

Map<String, dynamic> _decode(String m) {
  return json.decode(utf8.decode(base64Url.decode(base64Url.normalize(m))));
}

String _ed448JwtEncode(Map<String, dynamic> data, OkpPrivateKey privateKey) {
  final header = _encode({
    'alg': 'EdDSA',
    'typ': 'JWT',
    ...(privateKey.kid != null ? {'kid': privateKey.kid} : {}),
  });

  final payload = _encode(data);

  final signingInput = '$header.$payload';

  final signature = base64Url.encode(
    ed448.sign(base64Url.decode(privateKey.d), utf8.encode(signingInput))
  );

  return '$signingInput.$signature';
}


Map<String, dynamic> _ed448JwtDecode(String jwt, OkpKey key) {
  final header = _decode(jwt.substring(0, jwt.indexOf('.')));

  if (header['alg'] == null) {
    throw FormatException("Invalid JWT Format");
  }

  if (header['alg'] != 'EdDSA') {
    throw UnsupportedError(
      "Algorithm must be EdDSA in Ed448 decoding context"
    );
  }

  final public = base64.decode(key.x);
  final signedInput = jwt.substring(0, jwt.lastIndexOf('.'));
  final signature = base64.decode(jwt.substring(jwt.lastIndexOf('.') + 1));

  if (!ed448.verify(public, utf8.encode(signedInput), signature)) {
    throw InvalidSignature("Failed to verify JWT signature");
  }

  final data = _decode(jwt.substring(jwt.indexOf('.') + 1, jwt.lastIndexOf('.')));

  return data;
}

String jwtEncode(Map<String, dynamic> data, {required String algorithm, required Key key}) {
  _coerceAndValidateNumericDateIfPresent(String claim) {
    if (!data.containsKey(claim)) {
      return;
    }

    if (data[claim] is DateTime) {
      data[claim] = data[claim].toUtc().millisecondsSinceEpoch ~/ 1000;
    }

    if (!(data[claim] is int)) {
      throw FormatException("Claim \"$claim\" must be NumericDate");
    }
  }

  _coerceAndValidateNumericDateIfPresent('iat');
  _coerceAndValidateNumericDateIfPresent('nbf');
  _coerceAndValidateNumericDateIfPresent('exp');

  if (algorithm == 'EdDSA') {
    if (!(key is OkpKey)) {
      throw FormatException("EdDSA algorithm must use OKP key");
    }

    if (!(key is OkpPrivateKey)) {
      throw FormatException("Must encode with private key, not public key");
    }

    if (key.crv != 'Ed448') {
      throw UnsupportedError(
        "jwtEncode using the EdDSA algorithm currently only supports Ed448"
      );
    }

    return _ed448JwtEncode(data, key);
  } else {
    throw UnsupportedError("jwtEncode currently only supports EdDSA algorithm");
  }
}

void _validateClaims(Map<String, dynamic> data, {dtLeeway = const Duration(seconds: 0)}) {
  if (data.containsKey('iat') && !(data['iat'] is int)) {
    throw MalformedClaim("Claim \"iat\" is not a NumericDate");
  }

  if (data.containsKey('nbf')) {
    if (!(data['nbf'] is int)) {
      throw MalformedClaim("Claim \"nbf\" is not a NumericDate");
    }

    final nbf = DateTime.fromMillisecondsSinceEpoch(data['nbf'] * 1000, isUtc: true);
    if (DateTime.now().toUtc().compareTo(nbf.subtract(dtLeeway)) < 0) {
      throw NotYetValidToken("Token is not yet valid based on \"nbf\" claim");
    }
  }

  if (data.containsKey('exp')) {
    if (!(data['exp'] is int)) {
      throw MalformedClaim("Claim \"exp\" is not a NumericDate");
    }

    final exp = DateTime.fromMillisecondsSinceEpoch(data['exp'] * 1000, isUtc: true);
    if (DateTime.now().toUtc().compareTo(exp.add(dtLeeway)) >= 0) {
      throw ExpiredToken("Token is expired based on \"exp\" claim");
    }
  }
}

Map<String, dynamic> jwtDecodeUnverifiedHeader(String jwt) {
  return _decode(jwt.substring(0, jwt.indexOf('.')));
}

Map<String, dynamic> jwtDecode(String jwt, {required String algorithm, required Key key}) {
  Map<String, dynamic>? decoded;

  if (algorithm == 'EdDSA') {
    if (!(key is OkpKey)) {
      throw FormatException("EdDSA algorithm must use OKP key");
    }

    if (key.crv != 'Ed448') {
      throw UnsupportedError(
        "jwtDecode using the EdDSA algorithm currently only supports Ed448"
      );
    }

    decoded = _ed448JwtDecode(jwt, key);
  }

  if (decoded == null) {
    throw UnsupportedError("jwtDecode currently only supports EdDSA algorithm");
  }

  _validateClaims(decoded);

  return decoded;
}
