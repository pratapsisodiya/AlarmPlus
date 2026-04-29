import 'dart:math';

import '../models/alarm_model.dart';
import '../models/challenge_type.dart';

class ChallengeService {
  static final _rng = Random();

  static ChallengeType pickChallenge(AlarmModel alarm) {
    final type = alarm.challengeType;
    if (type == null || type == ChallengeType.random) {
      return randomChallenge();
    }
    return type;
  }

  static ChallengeType randomChallenge() {
    const pickable = [
      ChallengeType.math,
      ChallengeType.memoryPattern,
      ChallengeType.shakeToWake,
      ChallengeType.typing,
    ];
    return pickable[_rng.nextInt(pickable.length)];
  }

  static String label(ChallengeType type) {
    switch (type) {
      case ChallengeType.math:
        return 'Math';
      case ChallengeType.memoryPattern:
        return 'Memory Pattern';
      case ChallengeType.shakeToWake:
        return 'Shake to Wake';
      case ChallengeType.typing:
        return 'Typing';
      case ChallengeType.barcodeScan:
        return 'Barcode Scan';
      case ChallengeType.random:
        return 'Random';
    }
  }
}
