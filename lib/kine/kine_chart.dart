import 'veil/twist_codec.dart';

/// Identity, timings, and sealed credentials for the kine boot path.
///
/// Byte rows come from `tool/pack_twist_values.dart` and open through
/// [unwindTwist] on first read.
abstract final class KineChart {
  static const String appTitle = 'Vortixa Drop';
  static const String bundleId = 'com.vortixadrop.vortixadropgame';
  static const String iosStoreId = '6806988292';

  /// Skip cooldown on the notification invite: 2 days 22 hours 11 minutes.
  static const int pushInviteSnoozeSeconds = 252660;

  /// Wait after an organic conversion callback before the GCD lookup.
  static const int organicRecheckSeconds = 14;

  /// Cached destination lifetime when the server omits `expires`.
  static const int savedUrlTtlSeconds = 471300;

  static const List<int> _cfgHost = <int>[
    115, 86, 253, 39, 238, 210, 92, 199, 126, 153, 180, 5, 0, 69, 251, 76,
    0, 6, 25, 127, 79, 23, 173, 1, 225, 200, 139, 248, 91, 248, 157, 85,
    13, 35,
  ];

  static const List<int> _gcdRoot = <int>[
    115, 86, 253, 39, 238, 210, 92, 199, 111, 149, 162, 2, 13, 86, 180, 73,
    2, 25, 26, 55, 64, 1, 165, 92, 172, 196, 138, 243, 29, 246, 221, 86,
    17, 50, 0, 18, 188, 213, 77, 89, 20, 99, 101, 221, 76, 222, 125,
  ];

  static const List<int> _wkBuild = <int>[45, 18, 188, 121, 172, 198, 66, 221];

  static const List<int> _sfVer = <int>[42, 26, 167, 96];

  static const List<int> _sfBuild = <int>[45, 18, 189, 121, 172];

  static const List<int> _afKey = <int>[
    108, 27, 248, 63, 199, 166, 57, 176, 76, 129, 139, 20, 61, 11, 234, 69,
    56, 58, 62, 28, 26, 23,
  ];

  static const List<int> _fbNum = <int>[
    45, 19, 187, 111, 170, 223, 74, 221, 57, 197, 245, 72,
  ];

  static const List<int> _uaProd = <int>[
    86, 77, 243, 62, 241, 132, 18, 199, 61, 216, 246,
  ];

  static const List<int> _uaHead = <int>[
    51, 75, 217, 63, 242, 134, 22, 211, 40, 181, 150, 36, 73, 84, 202, 64,
    29, 7, 12, 113, 99, 43,
  ];

  static const List<int> _uaTail = <int>[
    119, 75, 226, 50, 189, 165, 18, 139, 40, 185, 149, 81, 49, 20,
  ];

  static const List<int> _uaEng = <int>[
    90, 82, 249, 59, 248, 191, 22, 138, 67, 159, 178, 94, 95, 13, 175, 6,
    67, 71, 88, 100, 12, 80, 139, 102, 214, 234, 169, 178, 18, 243, 218, 78,
    0, 115, 43, 27, 128, 218, 67, 4,
  ];

  static const List<int> _uaMob = <int>[
    86, 77, 235, 62, 241, 141, 92, 217, 61, 179, 247, 69, 81,
  ];

  static String get endpoint => unwindTwist(_cfgHost);
  static String get gcdBase => unwindTwist(_gcdRoot);
  static String get webKitBuild => unwindTwist(_wkBuild);
  static String get safariVersion => unwindTwist(_sfVer);
  static String get safariBuild => unwindTwist(_sfBuild);
  static String get appsFlyerKey => unwindTwist(_afKey);
  static String get firebaseProjectNumber => unwindTwist(_fbNum);
  static String get uaProduct => unwindTwist(_uaProd);
  static String get uaPlatformHead => unwindTwist(_uaHead);
  static String get uaPlatformTail => unwindTwist(_uaTail);
  static String get uaEngine => unwindTwist(_uaEng);
  static String get uaMobileTag => unwindTwist(_uaMob);

  static String get storeToken => 'id$iosStoreId';

  /// Boot path stays dormant until every sealed credential is present.
  static bool get pipelineReady {
    if (endpoint.isEmpty ||
        appsFlyerKey.isEmpty ||
        firebaseProjectNumber.isEmpty) {
      return false;
    }
    if (endpoint.contains('REPLACE') || appsFlyerKey.contains('REPLACE')) {
      return false;
    }
    if (iosStoreId == '0000000000') return false;
    if (firebaseProjectNumber == '000000000000') return false;
    return true;
  }
}
