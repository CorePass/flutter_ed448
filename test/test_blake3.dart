import 'dart:typed_data';

import '../lib/blake3.dart';

_getInput(int length) {
  final input = Uint8List(length);
  for (int i = 0; i < input.length; i++) {
    input[i] = i % 251;
  }
  return input;
}

void test() {
  var output = blake3Hex(_getInput(0));
  print(output);
  assert(output == 'af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262');

  output = blake3Hex(_getInput(1));
  print(output);
  assert(output == '2d3adedff11b61f14c886e35afa036736dcd87a74d27b5c1510225d0f592e213');

  output = blake3Hex(_getInput(1023));
  print(output);
  assert(output == '10108970eeda3eb932baac1428c7a2163b0e924c9a9e25b35bba72b28f70bd11');

  output = blake3Hex(_getInput(1024));
  print(output);
  assert(output == '42214739f095a406f3fc83deb889744ac00df831c10daa55189b5d121c855af7');

  output = blake3Hex(_getInput(1025));
  print(output);
  assert(output == 'd00278ae47eb27b34faecf67b4fe263f82d5412916c1ffd97c8cb7fb814b8444');

  output = blake3Hex(_getInput(2048));
  print(output);
  assert(output == 'e776b6028c7cd22a4d0ba182a8bf62205d2ef576467e838ed6f2529b85fba24a');

  output = blake3Hex(_getInput(2049));
  print(output);
  assert(output == '5f4d72f40d7a5f82b15ca2b2e44b1de3c2ef86c426c95c1af0b6879522563030');

  output = blake3Hex(_getInput(7169));
  print(output);
  assert(output == 'a003fc7a51754a9b3c7fae0367ab3d782dccf28855a03d435f8cfe74605e7817');

  output = blake3Hex(_getInput(31744));
  print(output);
  assert(output == '62b6960e1a44bcc1eb1a611a8d6235b6b4b78f32e7abc4fb4c6cdcce94895c47');

  output = blake3Hex(_getInput(102400));
  print(output);
  assert(output == 'bc3e3d41a1146b069abffad3c0d44860cf664390afce4d9661f7902e7943e085');

  output = blake3Hex(_getInput(1048576));
  print(output);
  assert(output == '74cb441fd087764ca9c3694da742ebe30cbeb3060a17009ca81825c7a8d10343');

  output = blake3Hex(_getInput(10485760));
  print(output);
  assert(output == '84e1593352403358f61a898d41fbee5bbb71967b0499f79b31542f33a2ab68c5');

  output = blake3Hex(_getInput(104857600));
  print(output);
  assert(output == '123f28919c77665a2bce3cf71a64c89179e6aca42c9886db30c66be010e520df');
}

void main() {
  test();
}
