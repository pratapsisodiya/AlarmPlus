enum NapPresetType { powerNap, energizer, fullCycle, custom }

class NapPreset {
  const NapPreset({
    required this.type,
    required this.label,
    required this.icon,
    required this.durationMinutes,
  });

  final NapPresetType type;
  final String label;
  final String icon;
  final int durationMinutes;

  static const List<NapPreset> presets = [
    NapPreset(type: NapPresetType.powerNap, label: 'Power Nap', icon: '⚡', durationMinutes: 20),
    NapPreset(type: NapPresetType.energizer, label: 'Energizer', icon: '🌙', durationMinutes: 45),
    NapPreset(type: NapPresetType.fullCycle, label: 'Full Cycle', icon: '😴', durationMinutes: 90),
  ];
}
