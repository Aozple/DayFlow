class AppSettings {
  final String accentColor;

  final String firstDayOfWeek;

  final int defaultTaskPriority;

  const AppSettings({
    this.accentColor = '#0A84FF',
    this.firstDayOfWeek = 'monday',
    this.defaultTaskPriority = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'accentColor': accentColor,
      'firstDayOfWeek': firstDayOfWeek,
      'defaultTaskPriority': defaultTaskPriority,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      accentColor: map['accentColor'] ?? '#0A84FF',
      firstDayOfWeek: map['firstDayOfWeek'] ?? 'monday',
      defaultTaskPriority: map['defaultTaskPriority'] ?? 3,
    );
  }

  AppSettings copyWith({
    String? accentColor,
    String? firstDayOfWeek,
    int? defaultTaskPriority,
  }) {
    return AppSettings(
      accentColor: accentColor ?? this.accentColor,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      defaultTaskPriority: defaultTaskPriority ?? this.defaultTaskPriority,
    );
  }
}
