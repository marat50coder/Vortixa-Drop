import 'dart:convert';

import '../kine_chart.dart';
import '../veil/kine_log.dart';
import '../veil/path_kinds.dart';
import '../vault/lane_chest.dart';
import 'http_persona.dart';

/// POSTs the attribution map to the config host and maps the body
/// (or a missing body) into a [PilotReply].
class CfgPost {
  CfgPost(this._persona, this._chest);

  final HttpPersona _persona;
  final LaneChest _chest;

  Future<PilotReply> request(Map<String, dynamic> payload) async {
    if (!KineChart.pipelineReady) {
      return PilotReply.declined('credentials_missing');
    }
    try {
      kineLog(() => '[KINE.POST] request ${jsonEncode(payload)}');
      final response = await _persona
          .post(
            Uri.parse(KineChart.endpoint),
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(milliseconds: 19800));
      kineLog(
        () => '[KINE.POST] response ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 404) return PilotReply.declined('no_data');
      if (response.statusCode != 200) {
        return PilotReply.declined('http_${response.statusCode}');
      }

      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map) return PilotReply.declined('invalid_response');

      final PilotReply reply = PilotReply.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (reply.hasDestination) {
        await _chest.writeCachedUrl(reply.url!, reply.expiresAt);
      }
      return reply;
    } catch (error) {
      kineLog(() => '[KINE.POST] failed: $error');
      return PilotReply.declined('network_failure');
    }
  }
}
