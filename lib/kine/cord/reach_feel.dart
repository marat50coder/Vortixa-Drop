import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Two-step reachability: radio/stack first (instant), then a DNS probe so
/// a captive portal with an interface but no route does not look online.
class ReachFeel {
  final Connectivity _connectivity = Connectivity();

  Future<bool> hasInterface() async {
    try {
      final List<ConnectivityResult> types = await _connectivity
          .checkConnectivity();
      return types.any((ConnectivityResult t) => t != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  Future<bool> reachesNetwork() async {
    if (!await hasInterface()) return false;
    const List<String> hosts = <String>[
      'www.apple.com',
      'www.cloudflare.com',
    ];
    final List<bool> hits = await Future.wait<bool>(
      hosts.map(_lookup),
    );
    return hits.any((bool ok) => ok);
  }

  Future<bool> _lookup(String host) async {
    try {
      final List<InternetAddress> found = await InternetAddress.lookup(host)
          .timeout(const Duration(milliseconds: 1600));
      return found.any((InternetAddress a) => a.rawAddress.isNotEmpty);
    } catch (_) {
      return false;
    }
  }

  Stream<List<ConnectivityResult>> get changes =>
      _connectivity.onConnectivityChanged;
}
