import 'package:cloud_firestore/cloud_firestore.dart';

class SleepLog {
  final String?  id;
  final DateTime bedtime;
  final DateTime wakeTime;
  final double   durationHours;
  final int?     qualityScore;

  const SleepLog({
    this.id,
    required this.bedtime,
    required this.wakeTime,
    required this.durationHours,
    this.qualityScore,
  });

  // Date
  factory SleepLog.create({
    required DateTime bedtime,
    required DateTime wakeTime,
    int? qualityScore,
  }) {
    final hours = wakeTime.difference(bedtime).inMinutes / 60.0;
    return SleepLog(
      bedtime:      bedtime,
      wakeTime:     wakeTime,
      durationHours: double.parse(hours.toStringAsFixed(2)),
      qualityScore: qualityScore,
    );
  }

  // Write to Firestore
  Map<String, dynamic> toMap() => {
    'bedtime':        Timestamp.fromDate(bedtime),
    'wake_time':      Timestamp.fromDate(wakeTime),
    'duration_hours': durationHours,
    if (qualityScore != null) 'quality_score': qualityScore,
  };

  // Read from Firestore
  factory SleepLog.fromMap(String id, Map<String, dynamic> map) {
    final bed  = (map['bedtime']   as Timestamp).toDate();
    final wake = (map['wake_time'] as Timestamp).toDate();
    return SleepLog(
      id:           id,
      bedtime:      bed,
      wakeTime:     wake,
      durationHours: (map['duration_hours'] as num).toDouble(),
      qualityScore: map['quality_score'] as int?,
    );
  }

  String get formattedDate {
    final d = bedtime;
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
  String get formattedBedtime  => '${_pad(bedtime.hour)}:${_pad(bedtime.minute)}';
  String get formattedWakeTime => '${_pad(wakeTime.hour)}:${_pad(wakeTime.minute)}';
}
