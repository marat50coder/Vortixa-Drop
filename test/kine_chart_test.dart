import 'package:flutter_test/flutter_test.dart';
import 'package:vortixadropgame/kine/kine_chart.dart';
import 'package:vortixadropgame/kine/cord/http_persona.dart';

void main() {
  test('sealed credentials unwind to the expected plaintext', () {
    expect(KineChart.endpoint, 'https://vortixadrop.com/config.php');
    expect(KineChart.gcdBase, 'https://gcdsdk.appsflyer.com/install_data/v5.0/');
    expect(KineChart.webKitBuild, '605.1.15');
    expect(KineChart.safariVersion, '18.7');
    expect(KineChart.safariBuild, '604.1');
    expect(KineChart.appsFlyerKey, 'w9qhZNJXDwMeT6pmJSWM6o');
    expect(KineChart.firebaseProjectNumber, '612877951339');
    expect(KineChart.uaProduct, 'Mozilla/5.0');
    expect(KineChart.uaPlatformHead, '(iPhone; CPU iPhone OS');
    expect(KineChart.uaPlatformTail, 'like Mac OS X)');
    expect(KineChart.uaEngine, 'AppleWebKit/605.1.15 (KHTML, like Gecko)');
    expect(KineChart.uaMobileTag, 'Mobile/15E148');
  });

  test('identity constants line up with the store listing', () {
    expect(KineChart.bundleId, 'com.vortixadrop.vortixadropgame');
    expect(KineChart.iosStoreId, '6806988292');
    expect(KineChart.storeToken, 'id6806988292');
  });

  test('pipeline is ready once real credentials are packed', () {
    expect(KineChart.pipelineReady, isTrue);
  });

  test('fallback user agent is Mobile Safari with no app identity trailer', () {
    final String ua = HttpPersona().userAgent;
    expect(ua, startsWith('Mozilla/5.0'));
    expect(ua, contains('iPhone'));
    expect(ua, contains('Safari/604.1'));
    expect(ua, contains('Mobile/15E148'));
    expect(ua, isNot(contains('appid')));
    expect(ua, isNot(contains('appname')));
    expect(ua, isNot(contains(KineChart.iosStoreId)));
    expect(ua, isNot(contains(KineChart.bundleId)));
    expect(ua, isNot(contains('Vortixa')));
    expect(ua, isNot(contains('Dart')));
    expect(ua, isNot(contains('Flutter')));
  });
}
