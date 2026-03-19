class SleepLog {
  final String? id;
  final DateTime date;        // the calendar date this sleep belongs to
  final DateTime bedtime;     // when the user went to sleep
  final DateTime wakeTime;    // when the user woke up
  final int? qualityScore;    // optional 1–5 self-rated quality

  const SleepLog({
    this.id,
    required this.date,
    required this.bedtime,
    required this.wakeTime,
    this.qualityScore,
  });

  // Computed from bedtime → wakeTime, expressed in hours
  double get durationH {
    final diff = wakeTime.difference(bedtime);
    return diff.inMinutes / 60.0;
  }

  Map<String, dynamic> toMap() => {
    'date':      date.toIso8601String().substring(0, 10), // 'YYYY-MM-DD'
    'bedtime':   bedtime.toIso8601String(),
    'wake_time': wakeTime.toIso8601String(),
    'duration_h': durationH,                              // stored for easy querying
    if (qualityScore != null) 'quality_score': qualityScore,
  };

  factory SleepLog.fromMap(String id, Map<String, dynamic> map) {
    return SleepLog(
      id:           id,
      date:         DateTime.parse(map['date'] as String),
      bedtime:      DateTime.parse(map['bedtime'] as String),
      wakeTime:     DateTime.parse(map['wake_time'] as String),
      qualityScore: map['quality_score'] as int?,
    );
  }
}
