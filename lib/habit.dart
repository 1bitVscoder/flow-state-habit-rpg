import 'package:hive/hive.dart';

part 'habit.g.dart'; 

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String icon;

  @HiveField(3)
  final int colorValue;

  @HiveField(4)
  int streak;

  @HiveField(5)
  bool isCompletedToday;

  // 📝 NEW FIELDS FOR GOAL TARGETS
  @HiveField(6)
  int currentProgress;

  @HiveField(7)
  int targetGoal;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    this.streak = 0,
    this.isCompletedToday = false,
    this.currentProgress = 0,
    this.targetGoal = 1, // Default to 1-tap tasks
  });
}