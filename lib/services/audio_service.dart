import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  final AudioPlayer _selectPlayer = AudioPlayer();
  final AudioPlayer _movePlayer = AudioPlayer();
  final AudioPlayer _popPlayer = AudioPlayer();
  final AudioPlayer _errorPlayer = AudioPlayer();

  bool _initialized = false;

  AudioService._internal() {
    _selectPlayer.setPlayerMode(PlayerMode.lowLatency);
    _movePlayer.setPlayerMode(PlayerMode.lowLatency);
    _popPlayer.setPlayerMode(PlayerMode.lowLatency);
    _errorPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  Future<void> init() async {
    if (_initialized) return;
    
    // Set audio contexts to match the platform, and preload sounds
    await _selectPlayer.setSourceAsset('sounds/select.wav');
    await _movePlayer.setSourceAsset('sounds/move.wav');
    await _popPlayer.setSourceAsset('sounds/pop.wav');
    await _errorPlayer.setSourceAsset('sounds/error.wav');
    
    _initialized = true;
  }

  void playSelect() {
    _selectPlayer.play(AssetSource('sounds/select.wav'));
  }

  void playMove() {
    // Stop current move sound to avoid overlapping mess
    _movePlayer.stop().then((_) {
      _movePlayer.play(AssetSource('sounds/move.wav'));
    });
  }

  void playPop() {
    _popPlayer.play(AssetSource('sounds/pop.wav'));
  }

  Future<void> playError() async {
    if (!_initialized) return;
    await _errorPlayer.resume();
  }
}
