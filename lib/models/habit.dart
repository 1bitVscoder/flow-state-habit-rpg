import 'package:hive/hive.dart';

class Habit extends HiveObject {
  final String id;
  String name;
  String icon;
  int colorValue;
  int streak;
  bool isCompletedToday;
  int currentProgress;
  int targetGoal;
  
  // Custom metadata fields from the PRD
  String category;             // e.g. Health, Mind, Relationships, Work, Finance, Custom
  String frequencyType;        // daily, weekly, specific, monthly, interval
  List<int> frequencyDays;     // days of week: 1=Mon, 7=Sun; or count for X times/week
  int frequencyInterval;       // every N days
  List<String> reminderTimes;   // e.g. ["08:00", "20:00"]
  String notes;
  bool archived;
  int createdAt;
  String? lastCompletedDate;   // e.g. "2026-05-31" to prevent double-completion calculations

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    this.streak = 0,
    this.isCompletedToday = false,
    this.currentProgress = 0,
    this.targetGoal = 1,
    this.category = 'Custom',
    this.frequencyType = 'daily',
    this.frequencyDays = const [],
    this.frequencyInterval = 1,
    this.reminderTimes = const [],
    this.notes = '',
    this.archived = false,
    required this.createdAt,
    this.lastCompletedDate,
  });
}

class HabitLog extends HiveObject {
  final String id;
  final String habitId;
  final String date;           // YYYY-MM-DD
  final bool completed;
  final int value;             // for quantified habits
  final String note;           // Daily reflection text
  final int completedAt;       // Epoch milliseconds

  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    this.completed = true,
    this.value = 1,
    this.note = '',
    required this.completedAt,
  });
}

// 🛡️ MANUAL TYPE ADAPTERS (Avoid build_runner generation errors & maintain backwards compatibility)
class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      name: fields[1] as String,
      icon: fields[2] as String,
      colorValue: fields[3] as int,
      streak: fields[4] as int? ?? 0,
      isCompletedToday: fields[5] as bool? ?? false,
      currentProgress: fields[6] as int? ?? 0,
      targetGoal: fields[7] as int? ?? 1,
      category: fields[8] as String? ?? 'Custom',
      frequencyType: fields[9] as String? ?? 'daily',
      frequencyDays: (fields[10] as List?)?.cast<int>() ?? const [],
      frequencyInterval: fields[11] as int? ?? 1,
      reminderTimes: (fields[12] as List?)?.cast<String>() ?? const [],
      notes: fields[13] as String? ?? '',
      archived: fields[14] as bool? ?? false,
      createdAt: fields[15] as int? ?? 0,
      lastCompletedDate: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.icon)
      ..writeByte(3)..write(obj.colorValue)
      ..writeByte(4)..write(obj.streak)
      ..writeByte(5)..write(obj.isCompletedToday)
      ..writeByte(6)..write(obj.currentProgress)
      ..writeByte(7)..write(obj.targetGoal)
      ..writeByte(8)..write(obj.category)
      ..writeByte(9)..write(obj.frequencyType)
      ..writeByte(10)..write(obj.frequencyDays)
      ..writeByte(11)..write(obj.frequencyInterval)
      ..writeByte(12)..write(obj.reminderTimes)
      ..writeByte(13)..write(obj.notes)
      ..writeByte(14)..write(obj.archived)
      ..writeByte(15)..write(obj.createdAt)
      ..writeByte(16)..write(obj.lastCompletedDate);
  }
}

class HabitLogAdapter extends TypeAdapter<HabitLog> {
  @override
  final int typeId = 1;

  @override
  HabitLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitLog(
      id: fields[0] as String,
      habitId: fields[1] as String,
      date: fields[2] as String,
      completed: fields[3] as bool? ?? true,
      value: fields[4] as int? ?? 1,
      note: fields[5] as String? ?? '',
      completedAt: fields[6] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, HabitLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.habitId)
      ..writeByte(2)..write(obj.date)
      ..writeByte(3)..write(obj.completed)
      ..writeByte(4)..write(obj.value)
      ..writeByte(5)..write(obj.note)
      ..writeByte(6)..write(obj.completedAt);
  }
}
