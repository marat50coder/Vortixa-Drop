/// Index-chained mask used only to keep plaintext out of the binary.
///
/// Each output byte depends on the seed row, the index, and the previous
/// mask byte. Empty payload decodes to an empty string.
const List<int> _twistSeed = <int>[
  0x56,
  0x74,
  0x44,
  0x72,
  0x6F,
  0x70,
  0x2F,
  0x6B,
  0x33,
  0x91,
  0xC4,
  0x1A,
  0xE8,
  0x5D,
];

int _mixTwist(int index, int previous) {
  final int seed = _twistSeed[index % _twistSeed.length];
  int acc = 0xC2B2AE35;
  acc = (acc ^ seed) & 0xFFFFFFFF;
  acc = (acc * 0x165667B1) & 0xFFFFFFFF;
  acc = (acc + ((index + 1) * 0x9E3779B9)) & 0xFFFFFFFF;
  acc = (acc ^ (acc >>> 16)) & 0xFFFFFFFF;
  acc = (acc + ((previous << 3) ^ previous)) & 0xFFFFFFFF;
  acc = (acc ^ (acc >>> 11)) & 0xFFFFFFFF;
  return acc & 0xFF;
}

/// Inverse of `sealTwist` in `tool/pack_twist_values.dart`.
String unwindTwist(List<int> packed) {
  if (packed.isEmpty) return '';
  final List<int> out = List<int>.filled(packed.length, 0);
  int prev = 0xA7;
  for (int i = 0; i < packed.length; i++) {
    final int mask = _mixTwist(i, prev);
    out[i] = packed[i] ^ mask;
    prev = mask;
  }
  return String.fromCharCodes(out);
}
