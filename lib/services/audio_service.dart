import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _loop = AudioPlayer();
  bool enabled = true;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    await _sfx.setReleaseMode(ReleaseMode.stop);
    await _sfx.setPlayerMode(PlayerMode.lowLatency);
    await _loop.setReleaseMode(ReleaseMode.loop);
    _ready = true;
  }

  Future<void> play(String asset) async {
    if (!enabled) return;
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> startLoop(String asset) async {
    if (!enabled) return;
    try {
      await _loop.stop();
      await _loop.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> stopLoop() async {
    try {
      await _loop.stop();
    } catch (_) {}
  }
}
