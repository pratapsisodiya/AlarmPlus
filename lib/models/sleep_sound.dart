enum SleepSound {
  rain,
  thunder,
  ocean,
  forest,
  whiteNoise,
  brownNoise,
  fan,
  crickets,
}

extension SleepSoundExtension on SleepSound {
  String get displayName {
    switch (this) {
      case SleepSound.rain: return 'Rain';
      case SleepSound.thunder: return 'Thunder';
      case SleepSound.ocean: return 'Ocean';
      case SleepSound.forest: return 'Forest';
      case SleepSound.whiteNoise: return 'White Noise';
      case SleepSound.brownNoise: return 'Brown Noise';
      case SleepSound.fan: return 'Fan';
      case SleepSound.crickets: return 'Crickets';
    }
  }

  String get icon {
    switch (this) {
      case SleepSound.rain: return '🌧️';
      case SleepSound.thunder: return '⛈️';
      case SleepSound.ocean: return '🌊';
      case SleepSound.forest: return '🌲';
      case SleepSound.whiteNoise: return '📻';
      case SleepSound.brownNoise: return '🌫️';
      case SleepSound.fan: return '🌀';
      case SleepSound.crickets: return '🦗';
    }
  }

  String get assetPath {
    switch (this) {
      case SleepSound.rain: return 'assets/sounds/rain.mp3';
      case SleepSound.thunder: return 'assets/sounds/thunder.mp3';
      case SleepSound.ocean: return 'assets/sounds/ocean.mp3';
      case SleepSound.forest: return 'assets/sounds/forest.mp3';
      case SleepSound.whiteNoise: return 'assets/sounds/white_noise.mp3';
      case SleepSound.brownNoise: return 'assets/sounds/brown_noise.mp3';
      case SleepSound.fan: return 'assets/sounds/fan.mp3';
      case SleepSound.crickets: return 'assets/sounds/crickets.mp3';
    }
  }
}
