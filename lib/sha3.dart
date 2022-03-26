import 'dart:math';
import 'dart:typed_data';

import 'src/format.dart';

// Based on public domain software at
// https://github.com/XKCP/XKCP/blob/master/Standalone/CompactFIPS202/Python/CompactFIPS202.py
// Original implementer: Gilles Van Assche
// Translated into Dart by Michael P. Nitowski <mike@nitow.ski>

BigInt _rotl64(BigInt a, int n) {
  return ((a >> (64 - (n % 64))) + (a << (n % 64))) % (BigInt.one << 64);
}

List<List<BigInt>> _KeccakF1600OnLanes(List<List<BigInt>> lanes) {
  BigInt R = BigInt.one;
  for (int i = 0; i < 24; i++) {
    final List<BigInt> C = [];
    for (int x = 0; x < 5; x++) {
      C.add(lanes[x][0] ^ lanes[x][1] ^ lanes[x][2] ^ lanes[x][3] ^ lanes[x][4]);
    }

    final List<BigInt> D = [];
    for (int x = 0; x < 5; x++) {
      D.add(C[(x+4) % 5] ^ _rotl64(C[(x + 1) % 5], 1));
    }

    List<List<BigInt>> tempLanes = [];
    for (int x = 0; x < 5; x++) {
      tempLanes.add([]);
      for(int y = 0; y < 5; y++) {
        tempLanes[x].add(lanes[x][y] ^ D[x]);
      }
    }

    lanes = tempLanes;

    var x = 1;
    var y = 0;
    var current = lanes[x][y];
    for (var t = 0; t < 24; t++) {
      final prevX = x;
      x = y;
      y = (2 * prevX + 3 * y) % 5;
      final prevCurrent = current;
      current = lanes[x][y];
      lanes[x][y] = _rotl64(prevCurrent, (t + 1) * (t + 2) ~/ 2);
    }

    for (var y = 0; y < 5; y++) {
      final T = [];
      for (int x = 0; x < 5; x++) {
        T.add(lanes[x][y]);
      }
      for (int x = 0; x < 5; x++) {
        lanes[x][y] = T[x] ^((~T[(x + 1) % 5]) & T[(x + 2) % 5]);
      }
    }

    for (var j = 0; j < 7; j++) {
      R = ((R << 1) ^ ((R >> 7) * BigInt.from(0x71))) % BigInt.from(256);
      if ((R & BigInt.two) != BigInt.zero) {
        lanes[0][0] = lanes[0][0] ^ (BigInt.one << ((1 << j) - 1));
      }
    }
  }

  return lanes;
}

BigInt _load64(List<BigInt> b) {
  var a = BigInt.zero;
  for (int i = 0; i <= 7; i++) {
    a += b[i] << (8 * i);
  }
  return a;
}

List<BigInt> _store64(BigInt a) {
  final List<BigInt> b = [];
  for (int i = 0; i <= 7; i++) {
    b.add((a >> (8*i)) % BigInt.from(256));
  }
  return b;
}

List<BigInt> _KeccakF1600(List<BigInt> state) {
  List<List<BigInt>> lanes = [];
  for (int x = 0; x < 5; x++) {
    lanes.add([]);
    for (int y = 0; y < 5; y++) {
      List<BigInt> l = state.sublist(8 * (x + 5 * y), 8 * (x + 5 * y) + 8);
      lanes[x].add(_load64(l));
    }
  }

  lanes = _KeccakF1600OnLanes(lanes);

  List<BigInt> newState = [];
  for (int i = 0; i < 200; i++) {
    newState.add(BigInt.from(i));
  }

  for (int x = 0; x < 5; x++) {
    for (int y = 0; y < 5; y++) {
      List<BigInt> b = _store64(lanes[x][y]);
      for (int i = 0; i < 8; i++) {
        newState[i + (8 * (x + 5 * y))] = b[i];
      }
    }
  }

  return newState;
}

List<int> _Keccak(
  int rate,
  int capacity,
  List<int> inputBytes,
  int delimitedSuffix,
  int outputByteLength
) {
  List<BigInt> outputBytes = [];

  List<BigInt> state = [];
  for (int _ = 0; _ < 200; _++) {
    state.add(BigInt.zero);
  }

  final int rateInBytes = rate ~/ 8;
  var blockSize = 0;

  if (((rate + capacity) != 1600) || ((rate % 8) != 0)) {
    throw StateError("Unexpected rate and capacity combination");
  }

  var inputOffset = 0;
  while(inputOffset < inputBytes.length) {
    blockSize = min(inputBytes.length - inputOffset, rateInBytes);
    for (int i = 0; i < blockSize; i++) {
      state[i] = state[i] ^ BigInt.from(inputBytes[i + inputOffset]);
    }
    inputOffset = inputOffset + blockSize;
    if (blockSize == rateInBytes) {
      state = _KeccakF1600(state);
      blockSize = 0;
    }
  }

  state[blockSize] = state[blockSize] ^ BigInt.from(delimitedSuffix);
  if (((delimitedSuffix & 0x80) != 0) && (blockSize == (rateInBytes - 1))) {
    state = _KeccakF1600(state);
  }
  state[rateInBytes - 1] = state[rateInBytes - 1] ^ BigInt.from(0x80);
  state = _KeccakF1600(state);

  while(outputByteLength > 0) {
    blockSize = min(outputByteLength, rateInBytes);
    outputBytes = outputBytes + state.sublist(0, blockSize);
    outputByteLength = outputByteLength - blockSize;
    if (outputByteLength > 0) {
      state = _KeccakF1600(state);
    }
  }

  return Uint8List.fromList(
    List<int>.from(outputBytes.map((b) => b.toInt()))
  );
}

List<int> shake_128(List<int> inputBytes, int outputByteLength) {
  return _Keccak(1344, 256, inputBytes, 0x1F, outputByteLength);
}

List<int> shake_256(List<int> inputBytes, int outputByteLength) {
  return _Keccak(1088, 512, inputBytes, 0x1F, outputByteLength);
}

List<int> sha3_224(List<int> inputBytes) {
  return _Keccak(1152, 448, inputBytes, 0x06, 224 ~/ 8);
}

List<int> sha3_256(List<int> inputBytes) {
  return _Keccak(1088, 512, inputBytes, 0x06, 256 ~/ 8);
}

List<int> sha3_384(List<int> inputBytes) {
  return _Keccak(832, 768, inputBytes, 0x06, 384 ~/ 8);
}

List<int> sha3_512(List<int> inputBytes) {
  return _Keccak(576, 1024, inputBytes, 0x06, 512 ~/ 8);
}

String shake_128Hex(List<int> inputBytes, int outputByteLength) {
  return asHexString(shake_128(inputBytes, outputByteLength));
}

String shake_256Hex(List<int> inputBytes, int outputByteLength) {
  return asHexString(shake_256(inputBytes, outputByteLength));
}

String sha3_224Hex(List<int> inputBytes) {
  return asHexString(sha3_224(inputBytes));
}

String sha3_256Hex(List<int> inputBytes) {
  return asHexString(sha3_256(inputBytes));
}

String sha3_384Hex(List<int> inputBytes) {
  return asHexString(sha3_384(inputBytes));
}

String sha3_512Hex(List<int> inputBytes) {
  return asHexString(sha3_512(inputBytes));
}
