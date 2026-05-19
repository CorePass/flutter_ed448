import 'dart:typed_data';

import 'package:flutter_ed448/flutter_ed448_core.dart' as core;
import 'package:test/test.dart';

Uint8List hexToBytes(String hex) {
  if (hex.length.isOdd) {
    throw FormatException('Odd hex length');
  }

  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

String bytesToHex(List<int> bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

Uint8List deterministicMessage(int length, int offset) {
  final message = Uint8List(length);
  for (var i = 0; i < message.length; i++) {
    message[i] = (i + offset) & 0xff;
  }
  return message;
}

Uint8List nonCanonicalEd448EncodingP() {
  final encoding = Uint8List(57);
  for (var i = 0; i < 56; i++) {
    encoding[i] = 0xff;
  }
  encoding[28] = 0xfe;
  return encoding;
}

List<Uint8List> torsionPointEncodings() {
  return [
    hexToBytes(
      '010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
    ),
    hexToBytes(
      'fefffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffffffffffffffffffffffffffffffffffffffffffffffffff00',
    ),
    hexToBytes(
      '000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080',
    ),
    Uint8List(57),
  ];
}

class VerifyVector {
  final Uint8List publicKey;
  final Uint8List signature;
  final Uint8List message;

  VerifyVector(this.publicKey, this.signature, this.message);
}

void main() {
  group('flutter_ed448 canonical API', () {
    final privateKey = hexToBytes(
      '6c82a562cb808d10d632be89c8513ebf6c929f34ddfa8c9f63c9960ef'
      '6e348a3528c8a3fcc2f044e39a3fc5b94492f8f032e7549a20098f95b',
    );
    final publicKey = hexToBytes(
      '5fd7449b59b461fd2ce787ec616ad46a1da1342485a70e1f8a0ea75d80'
      'e96778edf124769b46c7061bd6783df1e50f6cd1fa1abeafe8256180',
    );
    final signature = hexToBytes(
      '533a37f6bbe457251f023c0d88f976ae2dfb504a843e34d2074fd823d'
      '41a591f2b233f034f628281f2fd7a22ddd47d7828c59bd0a21bfd398'
      '0ff0d2028d4b18a9df63e006c5d1c2d345b925d8dc00b4104852db99'
      'ac5c7cdda8530a113a0f4dbb61149f05a7363268c71d95808ff2e652600',
    );
    final message = Uint8List(0);

    test('derives public key from canonical private seed', () {
      expect(bytesToHex(core.ed448DerivePublicKey(privateKey)),
          bytesToHex(publicKey));
    });

    test('signs canonical RFC8032 vector', () {
      expect(bytesToHex(core.ed448Sign(privateKey, message)),
          bytesToHex(signature));
    });

    test('verifies canonical RFC8032 vector', () {
      expect(core.ed448Verify(publicKey, message, signature), isTrue);
    });

    test('rejects signature for a different message', () {
      expect(core.ed448Verify(publicKey, hexToBytes('00'), signature), isFalse);
    });
  });

  group('go-goldilocks compatibility vectors', () {
    final canonicalVectors = [
      {
        'name': 'empty-message',
        'private': '000102030405060708090a0b0c0d0e0f101112131415161718191a1b'
            '1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738',
        'public': '18d0a70e42a742dfb561279893385061d7b4dad8f6feed4791eaab66'
            'b2f4a4f02fc09462a8bfb1842d0bac60e8a1b3e55ba2407f33226f3800',
        'message': '',
        'signature': 'cb682b115cf0f0b0cf2a068acba2d0495714f2a50832739af364191c'
            '611f6983890ee133a4bf75ed2d09adc5d70f6d256b0806f3224b35'
            'd7802748b7cf55f5e9583df9f8c85db809f4877191c99ed0670ad62'
            'f54d63d7d35fddfd85efbad63554ff3ce9b847607b2f79181020880'
            'f13c1b00',
      },
      {
        'name': 'zero-byte-message',
        'private':
            '010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
        'public':
            'e0758a33267939a394fb5ccb202ee851cebc2e89c91ac1289e2bfcddfd9ff9fc5694b0f569d7f7e9da16e1cde9301b29f48128b3cbd1168580',
        'message': '00',
        'signature':
            'a94e33bb28aa3b07ac36178ebe75315b7d24f9d7cab4954b190d7369a3bd4f263510cd16e5bb939e3bbd6d0561b715c18b2c2ae4bf093a0500b2690980ddcdafaeb2e14663bd1e281c3125ef8dcaa46e8af6c2515d4e42b995c639388eb464977711e1725144ab6c4eb7215142cabb3f0c00',
      },
      {
        'name': 'text-message',
        'private':
            '020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202',
        'public':
            'b52fd5b2cb34d6f944ab81d765fa026b63fd8448b4890d025cba17308a312ae4f31a012dc08c891e9a7c3d29dbad1aaf964e6c74073249f300',
        'message': bytesToHex(Uint8List.fromList(
            'Core Ed448 compatibility test message'.codeUnits)),
        'signature':
            '57c1488556a9e7e780d7630203d446f655b5f742036feb2db204ee6ffa642f2c1fa112e4bd47a289d7fa95e0df5cc8ceba45ac7ac1e251bd80e5dd228fd81a95bc1ffdb8b7936c5a69cec124a07a1ed5f40bba9b8b74576154a846a73d4a282e9ae2f8d5c15044af7aa8a2c2d38028d72c00',
      },
    ];

    for (final vector in canonicalVectors) {
      test('canonical ${vector['name']}', () {
        final privateKey = hexToBytes(vector['private']!);
        final publicKey = hexToBytes(vector['public']!);
        final message = hexToBytes(vector['message']!);
        final signature = hexToBytes(vector['signature']!);

        expect(bytesToHex(core.ed448DerivePublicKey(privateKey)),
            bytesToHex(publicKey));
        expect(bytesToHex(core.ed448Sign(privateKey, message)),
            bytesToHex(signature));
        expect(core.ed448Verify(publicKey, message, signature), isTrue);
      });
    }

    final longMessageVectors = [
      {
        'name': '64-byte-message',
        'private':
            '030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303',
        'public':
            '18e2f925aef56fc05910474593ee84c932bc7ea4d352a3416f72d115e60eb58cd862f73ac50886fbaad6354a4eeb01fd9f740491fb11f59580',
        'length': '64',
        'offset': '0',
        'signature':
            '99706c0d43655cbbdb0987520c20a2c9c98fe169d6e9ada9ed9f1167a249aff06a6c56b8147f9bda815e709cb2c2291e324042a6c1b4896b809d9dc41058be1d814bee8d55cf065a010277c96ea9a39982a95d98b7a97ade70aefb79c4b9024c16b89e5129553c11b0dc8b4894712fa73700',
      },
      {
        'name': '256-byte-message',
        'private':
            '040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404',
        'public':
            '4e15975a78604b2d6575f2d3310ca4e4f122226189f5900f744c1ead49408bdf8247843c05ba24fbb26c9b5f81c287cbbe3d3e8a3ad0231d00',
        'length': '256',
        'offset': '1',
        'signature':
            'e0ffeebb9584f0be43ab16bdb6e75b08b48f9ec7029376afc8822494434a9f85eb023af5279f0bfa466fe15eabb062008fd5baaf2c61f5b180d86a810e3bae994d563d7872e3a7f85fc0d0ed8179c027527f2ccc5bc9a237ff0d659e4834e83151c02caaa8ae031d398a17cd1ae816210300',
      },
      {
        'name': '1023-byte-message',
        'private':
            '050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505',
        'public':
            'f4c0eecfc7f17d960823180420fb8074d882317a39a719480d3ba6e7f565fc518a4ff54ef7dca5df5de9bb3740384c84ecac265c81398c3400',
        'length': '1023',
        'offset': '2',
        'signature':
            '9ae36ecbaece22e2f779a1818672467d34961d6028601c5e32d90d2ee1fd14b7fecd0168aeb7862b3ea6879fde654aae4670f3dc27aede2200d6f10899deede10db29a115c988005c52462a4e8cea1ff3846e581cf915b6b011d670c18abe9a7b90dc93d20ff82d53812a7c57c9dbdc33c00',
      },
    ];

    for (final vector in longMessageVectors) {
      test('long ${vector['name']}', () {
        final privateKey = hexToBytes(vector['private'] as String);
        final publicKey = hexToBytes(vector['public'] as String);
        final message = deterministicMessage(
          int.parse(vector['length'] as String),
          int.parse(vector['offset'] as String),
        );
        final signature = hexToBytes(vector['signature'] as String);

        expect(bytesToHex(core.ed448DerivePublicKey(privateKey)),
            bytesToHex(publicKey));
        expect(bytesToHex(core.ed448Sign(privateKey, message)),
            bytesToHex(signature));
        expect(core.ed448Verify(publicKey, message, signature), isTrue);
      });
    }

    test('signs with scalar and nonce prefix', () {
      final secret = hexToBytes(
        '26ad14d91ef8f1e5bbf5a1a7e44a9532e4854f1e1346761ee9b4ed1e'
        'd103e5e05c87fd9ecd788bc879a7433a7115255b7aad667fe84ee35c28',
      );
      final nonce = hexToBytes(
        '66dd9754284a1b7d77c1c43bfdfe38a116bd143e7c901b8e8e4561a'
        '7ee0a401dd5120fa2b77e2a6bda3a68d5a47e34fd29cf14ce3489067602',
      );
      final signature = hexToBytes(
        'a5fb561f2beb377e35bbf4d93b460ebeff3b55c1d64fffbcc2168c'
        '2d3998d310ed4f581499428ed46acfed19d7c8f5aa00b8fa88a725'
        '8e9c00f40ddd5e41cd33eb569d324d16babb5e840d60b6e52df10c'
        'bb2c6ea8bb3be49f39dace9cdfc7f606c2f4bfeef7bab2ab85fb78'
        '7c8041302a00',
      );

      expect(bytesToHex(core.signWithScalar(secret, nonce, Uint8List(0))),
          bytesToHex(signature));
    });

    final scalarSignVectors = [
      {
        'name': 'zero-byte-message',
        'nonce': '000102030405060708090a0b0c0d0e0f101112131415161718191a1b'
            '1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738',
        'message': '00',
        'signature':
            '23a56dc2bd6db200aded4a2ad5cea6083f29b412c5575f3c4f14d53373f14b9cc03e37a3c49bfd445cd4766f7b14c3755cb6849ac357ca8880ca1a9bb804d0bab2227a0e1e8ca798f77aa59c7f98541551f6c6b5ecf89c336272e96323094b7eb5fe20cf966f94c307aab6d303f138c82500',
      },
      {
        'name': 'text-message',
        'nonce':
            '020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202',
        'message': bytesToHex(Uint8List.fromList(
            'Core Ed448 compatibility test message'.codeUnits)),
        'signature':
            '2175036838bce81b72161107af10e67a39ea968ca6edfc0a1a074c3d14ae69bb7a446ca6b3c5a54727957f2bca8f2738cd8efd6a9645385500af3d2fcb330cb40e0d0252274d39c298e7c01e05cf46630872f133b99787c9069ee93dc30ec9d699e859c0cd20b7bf964aae6fa690d8713d00',
      },
    ];

    for (final vector in scalarSignVectors) {
      test('scalar/prenonce ${vector['name']}', () {
        final secret = hexToBytes(
          '26ad14d91ef8f1e5bbf5a1a7e44a9532e4854f1e1346761ee9b4ed1e'
          'd103e5e05c87fd9ecd788bc879a7433a7115255b7aad667fe84ee35c28',
        );
        final nonce = hexToBytes(vector['nonce']!);
        final message = hexToBytes(vector['message']!);
        final signature = hexToBytes(vector['signature']!);

        expect(bytesToHex(core.signWithScalar(secret, nonce, message)),
            bytesToHex(signature));
      });
    }

    test('rejects non-torsion negative verify vectors', () {
      final publicKey = hexToBytes(
        '18d0a70e42a742dfb561279893385061d7b4dad8f6feed4791eaab66'
        'b2f4a4f02fc09462a8bfb1842d0bac60e8a1b3e55ba2407f33226f3800',
      );
      final otherPublicKey = hexToBytes(
        'e0758a33267939a394fb5ccb202ee851cebc2e89c91ac1289e2bfcdd'
        'fd9ff9fc5694b0f569d7f7e9da16e1cde9301b29f48128b3cbd1168580',
      );
      final signature = hexToBytes(
        'cb682b115cf0f0b0cf2a068acba2d0495714f2a50832739af364191c'
        '611f6983890ee133a4bf75ed2d09adc5d70f6d256b0806f3224b35'
        'd7802748b7cf55f5e9583df9f8c85db809f4877191c99ed0670ad62'
        'f54d63d7d35fddfd85efbad63554ff3ce9b847607b2f79181020880'
        'f13c1b00',
      );

      final mutatedR = Uint8List.fromList(signature);
      mutatedR[0] ^= 0x01;
      final mutatedS = Uint8List.fromList(signature);
      mutatedS[57] ^= 0x01;
      final invalidR = Uint8List.fromList(signature);
      invalidR.setRange(0, 57, Uint8List(57)..fillRange(0, 57, 0xff));
      final nonCanonicalR = Uint8List.fromList(signature);
      nonCanonicalR.setRange(0, 57, nonCanonicalEd448EncodingP());
      final invalidPublicKey = Uint8List(57)..fillRange(0, 57, 0xff);
      final nonCanonicalPublicKey = nonCanonicalEd448EncodingP();

      final vectors = [
        VerifyVector(publicKey, signature, hexToBytes('00')),
        VerifyVector(otherPublicKey, signature, Uint8List(0)),
        VerifyVector(publicKey, mutatedR, Uint8List(0)),
        VerifyVector(publicKey, mutatedS, Uint8List(0)),
        VerifyVector(invalidPublicKey, signature, Uint8List(0)),
        VerifyVector(publicKey, invalidR, Uint8List(0)),
        VerifyVector(nonCanonicalPublicKey, signature, Uint8List(0)),
        VerifyVector(publicKey, nonCanonicalR, Uint8List(0)),
      ];

      for (final vector in vectors) {
        expect(
          core.ed448Verify(vector.publicKey, vector.message, vector.signature),
          isFalse,
        );
      }
    });

    test('rejects all-zero public key and all-zero signature', () {
      final publicKey = hexToBytes(
        '18d0a70e42a742dfb561279893385061d7b4dad8f6feed4791eaab66'
        'b2f4a4f02fc09462a8bfb1842d0bac60e8a1b3e55ba2407f33226f3800',
      );
      final signature = hexToBytes(
        'cb682b115cf0f0b0cf2a068acba2d0495714f2a50832739af364191c'
        '611f6983890ee133a4bf75ed2d09adc5d70f6d256b0806f3224b35'
        'd7802748b7cf55f5e9583df9f8c85db809f4877191c99ed0670ad62'
        'f54d63d7d35fddfd85efbad63554ff3ce9b847607b2f79181020880'
        'f13c1b00',
      );

      expect(core.ed448Verify(Uint8List(57), Uint8List(0), signature), isFalse);
      expect(
          core.ed448Verify(publicKey, Uint8List(0), Uint8List(114)), isFalse);
      expect(core.ed448Verify(Uint8List(57), Uint8List(0), Uint8List(114)),
          isFalse);
    });

    test('rejects torsion public keys and signature R points', () {
      final publicKey = hexToBytes(
        '18d0a70e42a742dfb561279893385061d7b4dad8f6feed4791eaab66'
        'b2f4a4f02fc09462a8bfb1842d0bac60e8a1b3e55ba2407f33226f3800',
      );
      final signature = hexToBytes(
        'cb682b115cf0f0b0cf2a068acba2d0495714f2a50832739af364191c'
        '611f6983890ee133a4bf75ed2d09adc5d70f6d256b0806f3224b35'
        'd7802748b7cf55f5e9583df9f8c85db809f4877191c99ed0670ad62'
        'f54d63d7d35fddfd85efbad63554ff3ce9b847607b2f79181020880'
        'f13c1b00',
      );

      for (final torsion in torsionPointEncodings()) {
        expect(core.ed448Verify(torsion, Uint8List(0), signature), isFalse);

        final torsionRSignature = Uint8List.fromList(signature);
        torsionRSignature.setRange(0, 57, torsion);
        expect(core.ed448Verify(publicKey, Uint8List(0), torsionRSignature),
            isFalse);
      }
    });
  });

  group('Ed448HDWallet compatibility API', () {
    final wallet = core.Ed448HDWallet();

    test('derives public key through the old class API', () {
      final vectors = [
        {
          'private':
              '582f73eb3d951ef93a8c392c7b113ad85c0f60a744c95c47370d4d593593edc0d745eb24fa2130f51fd5b1e6b2363a5405bf1e074ecbf4382d',
          'public':
              '4e6ef3aa2a74ce85c9c75de379c72abbce30601db4f66af1535d00190fa5de83af3831fa32e37c59e14a25788e56140896fb59b494e4fdca80',
        },
        {
          'private':
              '59fc82f514f3fc8d02d987e52a03cdcae81a257bed6ec9b668bf6acd8fe9e7d27cbcc4d8f463d917642d30e7ca44c3521370f78790b3b561dd',
          'public':
              '3cba3b2560c2779170ce5947f55bf73b93a1dd51d99b0b483ed0cfb5a9bb8409830c0f96068c799dbc6a28ca6bc1aad95d0387c36a731d7800',
        },
        {
          'private':
              '1edc2069350104b5594c602f7967c4b1580f2a757fc9a2745f621868cd333c245ec3c775d730d3c01a2e18f3e5d0b5e767ed3ec77e69732781',
          'public':
              '3a7a141eccbb86791845e85708c210c4641711bb19d2754d59c08ba21fc91d436bc82f26aeed03d56d33ae4c56a43a75ba316b0911bc981e80',
        },
      ];

      for (final vector in vectors) {
        expect(
          bytesToHex(
              wallet.ed448DerivePublicKey(hexToBytes(vector['private']!))),
          vector['public'],
        );
      }
    });

    test('signs and verifies through the old class API', () {
      final message = Uint8List.fromList(
          'The quick brown fox jumps over the lazy dog'.codeUnits);
      final vectors = [
        {
          'private':
              'e959068474bc720bf3a94c7a524750f0d4fe68a4828137e58d48303af1fa929a6c50f87d0cab27fc557aa1a3190cfad0abbca2a2e5d7da272d',
          'signature':
              '92a7e08f86b25f288eb0308f3fb780950ab77c333d5d1b91b6de40a199fc028fe66a001dc09341905a58f8c3d4a959ee5d416735f59d91640095dd83e70b6bc05fa6a26b32c00be454bfb87285417554183c2da64bbbad77b746bd86299fd4188578bc9aa321a8291c5d2281029ca24e2d00',
        },
        {
          'private':
              '1edc2069350104b5594c602f7967c4b1580f2a757fc9a2745f621868cd333c245ec3c775d730d3c01a2e18f3e5d0b5e767ed3ec77e69732781',
          'signature':
              '789dd9e1a4471c30cfef1da68076542e6918676424593936dbeb282f5929dcfa3437aef85fd890999ea7a1b16a2c8c3a8cf330c58768789b006b183034ec43acab783039d53fe46f6c39ab29f988a43371d07fe7746a2fd45c660f2a8c441446b8f1cdbfc0787e4cfe69280e5cd7b92d0400',
        },
      ];

      for (final vector in vectors) {
        final privateKey = hexToBytes(vector['private']!);
        final got = wallet.ed448Sign(privateKey, message);
        final publicKey = wallet.ed448DerivePublicKey(privateKey);

        expect(bytesToHex(got), vector['signature']);
        expect(wallet.ed448Verify(publicKey, message, got), isTrue);
      }
    });

    test('derives seed to extended private', () {
      final seed = hexToBytes(
        '6bc0169565eecbc8e62259959534a67684adbd4c229cc8830405fe81f60c7b896a273421c9587f4b3321ab8353bf7178b8f383ce07f916de7abebabfef0f5fee',
      );
      const extendedPrivate =
          '348728c67f8827c5fac17c81c17cba245c957ee16d115def1802cb39d637fb682047b054f3eb4b169477d845b3b4d7c87fa36ec3e7e98d0c0361f1dc6767753ca9db7ed41c32a745d7930121feba01b9b9ad0a6774dc906e8775c3eedb26037e4c2ffceccc198df6f97f9c7f2d79b89baf85';

      expect(bytesToHex(wallet.seedToExtendedPrivate(seed)), extendedPrivate);
    });

    test('derives extended private to extended public', () {
      final extendedPrivate = hexToBytes(
        '004e843c2991930124e5a0711c6a8be763f5b605ee80f089dfa9cbec5ebb20123dcc787b162a7baf37b0251f6bdd4ac14ae111491ef391cf0d1413821ed67083c855c6db4405dd4fa5fdec39e1c761be1415623c1c202c5cb5176e578830372b7e07eb1ef9cf71b19518815c4da0fd2d3594',
      );
      const extendedPublic =
          '004e843c2991930124e5a0711c6a8be763f5b605ee80f089dfa9cbec5ebb20123dcc787b162a7baf37b0251f6bdd4ac14ae111491ef391cf0db615e57dd4d15c3ed1323725c0ba8b1d7f6e740d08e0e29c6d3ff564c896c0c3dd28a9bb5065e06725c8f9e3f7c2c6bbad4900b7447ecf9880';

      expect(
          bytesToHex(wallet.toExtendedPublic(extendedPrivate)), extendedPublic);
    });

    test('derives child private keys', () {
      final vectors = [
        {
          'extended':
              '757a4a352e3aafdad7f65f6bf4f150800d334ffcac56e719cc3412ae6ae5a2f547f2b587785ac52c0136a09f05bbe43b6b000e3f9c49f7f7c76a103854fa8597b9514a0d6b11e0e972d492c0fd61afe5fb5baa38d51406ba333c7e5a7c43a121b694d6694047e6433e05c372a5eb78a48e99',
          'index': '0',
          'child':
              'b8254111ddf243fd897b44878678ff15d16763c7939e86512fd2b6d6535fde62ec6c94dd61fc76033d94e001ea26ef3950a0edd2ef74713760e63a36576ee565e08646a99c2062ebdf773167dc533a0a3a1b0d929d8b77b5faf7d54d557f3b537eeb572b04b04d246fb63154381679a48e99',
        },
        {
          'extended':
              '88b8592017482e0d85a8c405b84e12ba3a8ac552198216b0da811adc368589cc86a8bb38c67c766f9a942e7cedf5a6a36338f3d5bdd9466e2554b229028a76f79a18f4171fea287db096f05cc62ff3246ec70a2ebbf896b094350650846703183c09a13790e93fd3110c3ec0fe338daf93ba',
          'index': '${0x80000000}',
          'child':
              'bd9c963ce9ac0fb9da7f9dfa0ea84251ed6f3eba924858bb7b2f9eb3a66aa4fb42a87a0d5b05c9a48c442b480477d17cd89b8679acd6ccdf02fca262c2f9a158d51bea28d0b2724f237560f65a3b8ae98215dc97ade43beb1e3dad4fc12ec8a81da661db0ab6b94f1c566e38f16e8daf93ba',
        },
      ];

      for (final vector in vectors) {
        expect(
          bytesToHex(wallet.childPrivateToPrivate(
            hexToBytes(vector['extended']!),
            int.parse(vector['index']!),
          )),
          vector['child'],
        );
      }
    });

    test('generates HD wallet private keys', () {
      final vectors = [
        {
          'seed':
              '37a615be9f9e403a7b539ad9564c037e6ea0827628ecc664d436bbe3a37c3ab93d4f0693ba2b7dbf3634836e016736cf8403d949b516308c8c2a4c49acfbaba7',
          'index': '0',
          'private':
              'c06b81ed5e7be6a8604a863c1b7a6bc6b35256535ffcf23f35cc1531621cde892d45b21bfd647a79ba06b145dbd45f4200ff54fa787533bf94',
        },
        {
          'seed':
              '4db501dc0bdb8770bec9a2a3fb54c73b66e2abc1bd0d1b71dbf7beb339f65ef148ab9eb901241e8ba02eb570a7406e4be429b0a98aaa5729cae9bef895ec0b6b',
          'index': '1',
          'private':
              'a3b210b8771782a74d877a26c7f86aec9a6c9177972fd1f4b5d1a79524a7d48b15b1a3eb9fd2feefd18c8b4ca24a66f478c37e472037f3a8e5',
        },
        {
          'seed':
              'cde1fdb6597e7103ec622b76381a6f6a4847c00f5f3c7190e1ea87aae3ba512db23d08a614dcc6448ef85d1d5303861258c48902059bcf33bf40a61546b2079c',
          'index': '5',
          'private':
              'e6159b2a38dbbe289b2000354035bc864b3d53b7af9a5967449c167eb4144b6efafabd2f66f93d445d2fb49b515c6509ceb9d50b99dd8084ef',
        },
      ];

      for (final vector in vectors) {
        expect(
          bytesToHex(wallet.HDWalletGenerateKey(
            hexToBytes(vector['seed']!),
            int.parse(vector['index']!),
          )),
          vector['private'],
        );
      }
    });
  });
}
