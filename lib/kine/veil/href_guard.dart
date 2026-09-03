/// Gate for destinations the in-app WebView is allowed to open.
///
/// Launch slots, push payloads, config replies and cached URLs all pass
/// through here. Only an absolute `http`/`https` URL with a host survives.
/// `javascript:`, custom schemes and empty hosts become `null`.
abstract final class HrefGuard {
  /// Ready for `loadRequest`, or `null` when the WebView must not open it.
  ///
  /// `http` is kept as `http` — some partner links are not served on TLS.
  /// A bare `host/path` fragment is promoted to `https`.
  static String? sanitize(String? raw) {
    final String trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final Uri? parsed = Uri.tryParse(trimmed);
    if (parsed == null) return null;

    if (parsed.hasScheme) {
      final String scheme = parsed.scheme;
      final bool http = scheme == 'http' || scheme == 'https';
      if (!http) return null;
      if (parsed.host.isEmpty) return null;
      return trimmed;
    }

    final Uri? promoted = Uri.tryParse('https://$trimmed');
    if (promoted == null || promoted.host.isEmpty) return null;
    return promoted.toString();
  }
}
