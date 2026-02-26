import 'package:audioplayers/audioplayers.dart';
import '../core/constants/app_constants.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playAdzanBeep() async {
    await _player.play(AssetSource(AppConstants.adzanBeepAssetPath));
  }

  static Future<void> playIqomahBeep() async {
    await _player.play(AssetSource(AppConstants.iqomahBeepAssetPath));
  }
}
