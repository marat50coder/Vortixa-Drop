import 'href_guard.dart';

/// Last successful boot path. Token strings are persisted as-is.
enum PathKind {
  home,
  web,
  unresolved;

  String get token => switch (this) {
    PathKind.home => 'home',
    PathKind.web => 'web',
    PathKind.unresolved => 'unresolved',
  };

  static PathKind read(String? raw) => switch (raw) {
    'web' => PathKind.web,
    'home' => PathKind.home,
    _ => PathKind.unresolved,
  };
}

/// Parsed JSON body from the config endpoint.
class PilotReply {
  const PilotReply({
    required this.accepted,
    this.url,
    this.expiresAt,
    this.reason,
  });

  factory PilotReply.fromJson(Map<String, dynamic> json) {
    final Object? rawExpiry = json['expires'];
    final Object? rawUrl = json['url'];
    return PilotReply(
      accepted: json['ok'] == true,
      url: rawUrl is String ? HrefGuard.sanitize(rawUrl) : null,
      expiresAt: rawExpiry is num
          ? rawExpiry.toInt()
          : int.tryParse(rawExpiry?.toString() ?? ''),
      reason: json['message']?.toString(),
    );
  }

  factory PilotReply.declined(String reason) =>
      PilotReply(accepted: false, reason: reason);

  final bool accepted;
  final String? url;
  final int? expiresAt;
  final String? reason;

  bool get hasDestination => accepted && (url?.isNotEmpty ?? false);

  bool get transientFailure {
    final String? code = reason;
    if (code == 'network_failure' || code == 'invalid_response') return true;
    if (code == null) return false;
    return RegExp(r'^http_5\d\d$').hasMatch(code) ||
        code == 'http_408' ||
        code == 'http_429';
  }
}

sealed class SteerHint {
  const SteerHint();
}

final class NestPath extends SteerHint {
  const NestPath();
}

final class PanePath extends SteerHint {
  const PanePath(this.url, {this.coldLaunch = false});

  final String url;
  final bool coldLaunch;
}

final class QuietPath extends SteerHint {
  const QuietPath({required this.returnToHome});

  final bool returnToHome;
}
