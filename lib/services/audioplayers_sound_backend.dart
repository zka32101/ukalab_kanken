import 'package:audioplayers/audioplayers.dart';
import 'package:ukalab_core/learning.dart';

/// 効果音の再生（audioplayers）。`assets/sounds/` の音源を鳴らす。
/// キット（[AnswerFeedback]）の [SoundBackend] を、このアプリの音源で実装したもの。
class AudioplayersSoundBackend implements SoundBackend {
  static const _paths = {
    SoundCue.correct: 'sounds/correct.ogg',
    SoundCue.incorrect: 'sounds/incorrect.ogg',
    SoundCue.badgeUnlocked: 'sounds/badge_unlocked.ogg',
    SoundCue.combo: 'sounds/combo.ogg',
  };

  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(SoundCue cue, {required double volume}) async {
    // 短いSEを連打しても途切れないよう、止めてから鳴らす。
    // 音声ファイル未配置・再生環境の問題は、呼び出し側（AnswerFeedback）が握りつぶす。
    await _player.stop();
    await _player.play(AssetSource(_paths[cue]!), volume: volume);
  }

  @override
  Future<void> dispose() => _player.dispose();
}
