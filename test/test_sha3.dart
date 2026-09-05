import 'dart:convert';

import 'package:flutter_ed448/sha3.dart';
import 'package:test/test.dart';

List<int> _pattern(int length) => List<int>.generate(length, (i) => i % 251);

String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('SHA-3 known-answer vectors', () {
    test('matches all digest sizes for abc', () {
      final input = utf8.encode('abc');
      expect(
        sha3_224Hex(input),
        'e642824c3f8cf24ad09234ee7d3c766fc9a3a5168d0c94ad73b46fdf',
      );
      expect(
        sha3_256Hex(input),
        '3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532',
      );
      expect(
        sha3_384Hex(input),
        'ec01498288516fc926459f58e2c6ad8df9b473cb0fc08c2596da7cf0e49be4b2'
        '98d88cea927ac7f539f1edf228376d25',
      );
      expect(
        sha3_512Hex(input),
        'b751850b1a57168a5693cd924b6b096e08f621827444f70d884f5d0240d2712e1'
        '0e116e9192af3c91a7ec57647e3934057340b4cf408d5a56592f8274eec53f0',
      );
    });

    test('matches empty-input vectors', () {
      expect(
        sha3_224Hex(const []),
        '6b4e03423667dbb73b6e15454f0eb1abd4597f9a1b078e3f5b5a6bc7',
      );
      expect(
        sha3_256Hex(const []),
        'a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a',
      );
      expect(
        sha3_384Hex(const []),
        '0c63a75b845e4f7d01107d852e4c2485c51a50aaaa94fc61995e71bbee983a2a'
        'c3713831264adb47fb6bd1e058d5f004',
      );
      expect(
        sha3_512Hex(const []),
        'a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a6'
        '15b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26',
      );
    });

    test('handles the SHA3-256 rate boundary', () {
      const expected = {
        135: 'fded8fd9d6551c601eeb3b7c6bc5e5cfd8aad1d015b7e9aaa9c9b9475231d5e2',
        136: 'cf3ccff92480a29160c2d38317c430e14749bfee1788106957dfe73f8c4930e5',
        137: 'ce9d7dc90913ee5d92745019479a5352c6d6279bef18ed07dc0a83ee8084daca',
      };

      for (final entry in expected.entries) {
        expect(sha3_256Hex(_pattern(entry.key)), entry.value);
      }
    });

    test('handles multi-block input', () {
      expect(
        sha3_512Hex(_pattern(4096)),
        'ac8fc5c0a7dc20b9234524accd6000bcafbad2850a66455600873c13d1cb6875'
        '824f6888630829896eb411ee4973896e0fb6487d8be89fcc3dfd9eed6c93fe90',
      );
    });
  });

  group('SHAKE extendable output', () {
    test('matches known vectors', () {
      expect(
        shake_128Hex(utf8.encode('abc'), 32),
        '5881092dd818bf5cf8a3ddb793fbcba74097d5c526a6d35f97b83351940f2cc8',
      );
      expect(
        shake_256Hex(utf8.encode('abc'), 64),
        '483366601360a8771c6863080cc4114d8db44530f8f1e1ee4f94ea37e78b5739'
        'd5a15bef186a5386c75744c0527e1faa9f8726e462a12a4feb06bd8801e751e4',
      );
      expect(
        shake_128Hex(const [], 32),
        '7f9c2ba4e88f827d616045507605853ed73b8093f6efbc88eb1a6eacfa66ef26',
      );
    });

    test('supports zero and variable-length output', () {
      expect(shake_128Hex(const [], 0), isEmpty);
      final shortDigest = shake_256Hex(utf8.encode('abc'), 16);
      final longDigest = shake_256Hex(utf8.encode('abc'), 64);
      expect(shortDigest.length, 32);
      expect(longDigest.length, 128);
      expect(longDigest, startsWith(shortDigest));
    });

    test('handles the SHAKE128 rate boundary', () {
      const expected = {
        167: '1e552791cc4e93a0d4a8dc47ae49228c2faa869e40e628f6ace477aec3f1ca7a',
        168: 'f15277eb61c4908d44a2853f3cde071ae2ed7a23461fbe162a1a98cf6875059c',
        169: '015be3338c986d9846affa0f94b4afc2a76bc289c709e1a596ec9eccf090a773',
      };

      for (final entry in expected.entries) {
        expect(shake_128Hex(_pattern(entry.key), 32), entry.value);
      }
    });
  });

  test('byte and hexadecimal APIs agree', () {
    final input = utf8.encode('Tone');
    expect(_hex(sha3_256(input)), sha3_256Hex(input));
    expect(_hex(shake_256(input, 48)), shake_256Hex(input, 48));
  });
}
