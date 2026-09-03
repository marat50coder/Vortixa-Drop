// ignore_for_file: avoid_print

// Dev-only sealer matching `lib/kine/veil/twist_codec.dart`.
//     dart run tool/pack_twist_values.dart

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

List<int> _seal(String plain) {
  final List<int> units = plain.codeUnits;
  final List<int> out = List<int>.filled(units.length, 0);
  int prev = 0xA7;
  for (int i = 0; i < units.length; i++) {
    final int mask = _mixTwist(i, prev);
    out[i] = (units[i] ^ mask) & 0xFF;
    prev = mask;
  }
  return out;
}

String _unseal(List<int> packed) {
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

class _Entry {
  const _Entry(this.name, this.value);
  final String name;
  final String value;
}

void main() {
  const List<_Entry> entries = <_Entry>[
    _Entry('cfgHost', 'https://vortixadrop.com/config.php'),
    _Entry('gcdRoot', 'https://gcdsdk.appsflyer.com/install_data/v5.0/'),
    _Entry('wkBuild', '605.1.15'),
    _Entry('sfVer', '18.7'),
    _Entry('sfBuild', '604.1'),
    _Entry('afKey', 'w9qhZNJXDwMeT6pmJSWM6o'),
    _Entry('fbNum', '612877951339'),
    _Entry('uaProd', 'Mozilla/5.0'),
    _Entry('uaHead', '(iPhone; CPU iPhone OS'),
    _Entry('uaTail', 'like Mac OS X)'),
    _Entry('uaEng', 'AppleWebKit/605.1.15 (KHTML, like Gecko)'),
    _Entry('uaMob', 'Mobile/15E148'),
  ];

  int mismatches = 0;
  for (final _Entry entry in entries) {
    final List<int> packed = _seal(entry.value);
    print(
      '  static const List<int> _${entry.name} = <int>[${packed.join(', ')}];',
    );
    if (_unseal(packed) != entry.value) {
      print('  // ROUND-TRIP MISMATCH ${entry.name}');
      mismatches += 1;
    }
  }

  if (mismatches != 0) {
    throw StateError(
      'pack_twist_values: $mismatches payload(s) failed to round-trip',
    );
  }
  print('pack_twist_values: ${entries.length} payloads packed');
}
