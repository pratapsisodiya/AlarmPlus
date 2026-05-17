import 'package:alarm_plus/shared/models/challenge_type.dart';

class QuestStep {
  QuestStep({required this.challengeType, this.completed = false});

  final ChallengeType challengeType;
  final bool completed;

  QuestStep copyWith({bool? completed}) {
    return QuestStep(challengeType: challengeType, completed: completed ?? this.completed);
  }
}

class WakeQuest {
  WakeQuest({required this.steps, this.xpReward = 150});

  final List<QuestStep> steps;
  final int xpReward;

  static WakeQuest ultimatePreset() => WakeQuest(
    steps: [
      QuestStep(challengeType: ChallengeType.shakeToWake),
      QuestStep(challengeType: ChallengeType.stepCounter),
      QuestStep(challengeType: ChallengeType.trivia),
      QuestStep(challengeType: ChallengeType.eyeOpen),
    ],
    xpReward: 200,
  );

  static WakeQuest fromTypes(List<ChallengeType> types) => WakeQuest(
    steps: types.map((t) => QuestStep(challengeType: t)).toList(),
    xpReward: types.length * 40,
  );
}
