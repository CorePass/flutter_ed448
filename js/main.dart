import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../lib/jwt.dart' as jwt;

JSObject _globalObject() {
	final exports = globalContext['exports'];
	if (exports != null) {
		return exports as JSObject;
	}

	final thirds = JSObject();
	globalContext['Thirds'] = thirds;
	return thirds;
}

dynamic _toDartValue(JSObject value) {
	final jsonObject = globalContext['JSON'] as JSObject;
	final stringified = jsonObject.callMethod<JSString>('stringify'.toJS, value);
	return json.decode(stringified.toDart);
}

String jwtEncode(JSObject data, String algorithm, JSObject key) {
	if (algorithm != 'EdDSA') {
		throw UnsupportedError(
			'jwtDecode currently only supports EdDSA algorithm with Ed448 keys',
		);
	}

	return jwt.jwtEncode(
		_toDartValue(data),
		algorithm: algorithm,
		key: jwt.OkpPrivateKey.fromSecret('Ed448', (key['key'] as JSString).toDart),
	);
}

JSObject jwtDecode(String token, String algorithm, JSObject key) {
	final obj = JSObject();

	if (algorithm != 'EdDSA') {
		throw UnsupportedError(
			'jwtDecode currently only supports EdDSA algorithm with Ed448 keys',
		);
	}

	final keyValue = (key['key'] as JSString).toDart;
	final keyIsPublic = key.has('public') && (key['public'] as JSBoolean).toDart;

	final jwtKey = keyIsPublic
		? jwt.OkpPublicKey.fromPublic('Ed448', keyValue)
		: jwt.OkpPrivateKey.fromSecret('Ed448', keyValue);

	try {
		final decoded = jwt.jwtDecode(token, key: jwtKey, algorithm: 'EdDSA');
		obj['verified'] = true.toJS;
		obj['decoded'] = decoded.jsify();
		obj['reason'] = null;
	} catch (e) {
		obj['verified'] = false.toJS;
		obj['decoded'] = null;
		if (e is jwt.InvalidToken) {
			obj['reason'] = e.toString().split(': ')[0].toJS;
		} else if (e is UnsupportedError) {
			obj['reason'] = e.toString().split(': ')[1].toJS;
		} else {
			obj['reason'] = 'Unable to parse token'.toJS;
		}
	}

	return obj;
}

void main() {
	final target = _globalObject();
	target['jwtEncode'] =
		((JSObject data, JSString algorithm, JSObject key) =>
			jwtEncode(data, algorithm.toDart, key).toJS).toJS;
	target['jwtDecode'] =
		((JSString token, JSString algorithm, JSObject key) =>
			jwtDecode(token.toDart, algorithm.toDart, key)).toJS;
}
