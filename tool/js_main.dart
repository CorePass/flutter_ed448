import 'dart:js' as js;

import '../lib/jwt.dart';

ed448PublicKeyJwtDecode(String jwt, String publicKey) {
  var obj = js.JsObject(js.context['Object']);
  var key = OkpPublicKey.fromPublic("Ed448", publicKey);

  try {
    var decoded = jwtDecode(jwt, key: key, algorithm: "EdDSA");
    obj["verified"] = true;
    obj["decoded"] = js.JsObject(js.context['Object']);
    decoded.forEach((key, value) {
      obj["decoded"][key] = value;
    });
    obj["reason"] = null;
  } catch (e) {
    obj["verified"] = false;
    obj["decoded"] = null;
    if (e is InvalidToken) {
      obj["reason"] = e.toString().split(':')[0];
    } else {
      obj["reason"] = "Unable to parse token";
    }
  }

  return obj;
}

main() {
  js.context['ed448PublicKeyJwtDecode'] = ed448PublicKeyJwtDecode;
}
