import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/orientation.dart';
import 'kine/cord/cfg_post.dart';
import 'kine/cord/http_persona.dart';
import 'kine/cord/origin_ink.dart';
import 'kine/cord/reach_feel.dart';
import 'kine/kine_chart.dart';
import 'kine/kine_pilot.dart';
import 'kine/veil/kine_log.dart';
import 'kine/vault/lane_chest.dart';
import 'kine/vault/push_hub.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await VxOrientation.allowAny();

  final LaneChest locker = LaneChest();
  final HttpPersona agent = HttpPersona();
  await Future.wait<void>(<Future<void>>[locker.prepare(), agent.prepare()]);

  kineLog(
    () =>
        '[KINE.BOOT] pipelineReady=${KineChart.pipelineReady} '
        'endpoint=${KineChart.endpoint} '
        'afKeyLen=${KineChart.appsFlyerKey.length} '
        'fbNum=${KineChart.firebaseProjectNumber}',
  );

  final ReachFeel scout = ReachFeel();
  final OriginInk trail = OriginInk(agent);
  final PushHub beacon = PushHub(locker);
  final CfgPost dispatcher = CfgPost(agent, locker);
  final KinePilot helm = KinePilot(
    locker: locker,
    scout: scout,
    trail: trail,
    dispatcher: dispatcher,
    beacon: beacon,
    agent: agent,
    runtimeEnabled: KineChart.pipelineReady,
  );

  runApp(VortixaApp(helm: helm));
}
