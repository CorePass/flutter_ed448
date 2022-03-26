import 'dart:convert';

import '../lib/sha3.dart';

test() {
  var output = shake_128Hex(utf8.encode("abc"), 32);
  print(output);
  assert (output == "5881092dd818bf5cf8a3ddb793fbcba74097d5c526a6d35f97b83351940f2cc8");

  output = shake_256Hex(utf8.encode("abc"), 64);
  print(output);
  assert (output == "483366601360a8771c6863080cc4114d8db44530f8f1e1ee4f94ea37e78b5739d5a15bef186a5386c75744c0527e1faa9f8726e462a12a4feb06bd8801e751e4");

  output = sha3_224Hex(utf8.encode("abc"));
  print(output);
  assert (output == "e642824c3f8cf24ad09234ee7d3c766fc9a3a5168d0c94ad73b46fdf");

  output = sha3_256Hex(utf8.encode("abc"));
  print(output);
  assert (output == "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532");

  output = sha3_384Hex(utf8.encode("abc"));
  print(output);
  assert (output == "ec01498288516fc926459f58e2c6ad8df9b473cb0fc08c2596da7cf0e49be4b298d88cea927ac7f539f1edf228376d25");

  output = sha3_512Hex(utf8.encode("abc"));
  print(output);
  assert (output == "b751850b1a57168a5693cd924b6b096e08f621827444f70d884f5d0240d2712e10e116e9192af3c91a7ec57647e3934057340b4cf408d5a56592f8274eec53f0");

  // TODO Add more tests
}

main() {
  test();
}
