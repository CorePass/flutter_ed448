import 'dart:convert';
import 'dart:js' as js;

import '../lib/jwt.dart' as jwt;

dynamic _toDartValue(js.JsObject value) {
  return json.decode(js.context['JSON'].callMethod('stringify', [value]));
}

String jwtEncode(js.JsObject data, String algorithm, js.JsObject key) {
  if (algorithm != "EdDSA") {
    throw UnsupportedError("jwtDecode currently only supports EdDSA algorithm with Ed448 keys");
  }

  return jwt.jwtEncode(
    _toDartValue(data),
    algorithm: algorithm,
    key: jwt.OkpPrivateKey.fromSecret("Ed448", key['key'])
  );
}

js.JsObject jwtDecode(String token, String algorithm, js.JsObject key) {
  var obj = js.JsObject(js.context['Object']);

  if (algorithm != "EdDSA") {
    throw UnsupportedError("jwtDecode currently only supports EdDSA algorithm with Ed448 keys");
  }

  var jwtKey;
  if (key.hasProperty("public") && key['public']) {
    jwtKey = jwt.OkpPublicKey.fromPublic("Ed448", key['key']);
  } else {
    jwtKey = jwt.OkpPrivateKey.fromSecret("Ed448", key['key']);
  }

  try {
    var decoded = jwt.jwtDecode(token, key: jwtKey, algorithm: "EdDSA");
    obj["verified"] = true;
    obj["decoded"] = js.JsObject.jsify(decoded);
    obj["reason"] = null;
  } catch (e) {
    obj["verified"] = false;
    obj["decoded"] = null;
    if (e is jwt.InvalidToken) {
      obj["reason"] = e.toString().split(': ')[0];
    } else if (e is UnsupportedError) {
      obj["reason"] = e.toString().split(': ')[1];
    } else {
      obj["reason"] = "Unable to parse token";
    }
  }

  return obj;
}

main() {
  var thirds = {};;
  thirds['jwtEncode'] = jwtEncode;
  thirds['jwtDecode'] = jwtDecode;

  var ctx = 'exports';
  var isBrowser = !js.context.hasProperty('exports');
  if (isBrowser) {
      ctx = 'Thirds';
      js.context[ctx] = js.JsObject(js.context['Object']);
  }
  thirds.forEach((key, value) {
    js.context[ctx][key] = value;
  });
}
