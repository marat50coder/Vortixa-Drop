import 'package:flutter_test/flutter_test.dart';
import 'package:vortixadropgame/kine/veil/href_guard.dart';
import 'package:vortixadropgame/kine/veil/twist_codec.dart';

void main() {
  group('unwindTwist round-trip', () {
    const List<int> wkBuild = <int>[45, 18, 188, 121, 172, 198, 66, 221];
    const List<int> uaProd = <int>[
      86, 77, 243, 62, 241, 132, 18, 199, 61, 216, 246,
    ];
    const List<int> sfVer = <int>[42, 26, 167, 96];

    test('WebKit build number decodes to a plausible version string', () {
      expect(unwindTwist(wkBuild), '605.1.15');
    });

    test('Mozilla product decodes cleanly', () {
      expect(unwindTwist(uaProd), 'Mozilla/5.0');
    });

    test('Safari version decodes cleanly', () {
      expect(unwindTwist(sfVer), '18.7');
    });

    test('An empty payload becomes an empty string', () {
      expect(unwindTwist(const <int>[]), '');
    });
  });

  group('HrefGuard.sanitize', () {
    test('keeps a well-formed https URL as-is', () {
      expect(
        HrefGuard.sanitize('https://example.test/offer?id=7#top'),
        'https://example.test/offer?id=7#top',
      );
    });

    test('keeps http as http (no silent upgrade)', () {
      expect(
        HrefGuard.sanitize('  http://example.test/a  '),
        'http://example.test/a',
      );
    });

    test('promotes a bare host to https', () {
      expect(
        HrefGuard.sanitize('example.test/offer'),
        'https://example.test/offer',
      );
    });

    test('keeps a path with characters WebKit tolerates', () {
      expect(
        HrefGuard.sanitize('https://example.test/r?to=a|b'),
        'https://example.test/r?to=a|b',
      );
    });

    test('refuses anything the WebView must not open', () {
      expect(HrefGuard.sanitize(null), isNull);
      expect(HrefGuard.sanitize(''), isNull);
      expect(HrefGuard.sanitize('   '), isNull);
      expect(HrefGuard.sanitize('javascript:alert(1)'), isNull);
      expect(HrefGuard.sanitize('mailto:hi@example.test'), isNull);
      expect(HrefGuard.sanitize('vortixa://offer'), isNull);
      expect(HrefGuard.sanitize('https:///no-host'), isNull);
    });
  });
}
