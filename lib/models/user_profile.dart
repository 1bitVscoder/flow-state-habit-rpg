import 'package:hive/hive.dart';

class UserProfile extends HiveObject {
  String name;
  int streakFreezes;
  String subscriptionTier; // free, premium
  String themeMode;        // dark, light, system
  String themeBackground;  // aurora, ocean, ember, forest, monochrome
  
  // Gamification systems
  int userLevel;
  int userSparks;
  int bossHp;
  int maxBossHp;
  int bossTier;
  
  // Anti-abuse constraints
  String? lastStreakFreezeDate; // e.g. "2026-05-31"

  UserProfile({
    this.name = 'Soumya',
    this.streakFreezes = 1,
    this.subscriptionTier = 'free',
    this.themeMode = 'dark',
    this.themeBackground = 'aurora',
    this.userLevel = 1,
    this.userSparks = 0,
    this.bossHp = 200,
    this.maxBossHp = 200,
    this.bossTier = 1,
    this.lastStreakFreezeDate,
  });
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 2;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      name: fields[0] as String? ?? 'Soumya',
      streakFreezes: fields[1] as int? ?? 1,
      subscriptionTier: fields[2] as String? ?? 'free',
      themeMode: fields[3] as String? ?? 'dark',
      themeBackground: fields[4] as String? ?? 'aurora',
      userLevel: fields[5] as int? ?? 1,
      userSparks: fields[6] as int? ?? 0,
      bossHp: fields[7] as int? ?? 200,
      maxBossHp: fields[8] as int? ?? 200,
      bossTier: fields[9] as int? ?? 1,
      lastStreakFreezeDate: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)..write(obj.name)
      ..writeByte(1)..write(obj.streakFreezes)
      ..writeByte(2)..write(obj.subscriptionTier)
      ..writeByte(3)..write(obj.themeMode)
      ..writeByte(4)..write(obj.themeBackground)
      ..writeByte(5)..write(obj.userLevel)
      ..writeByte(6)..write(obj.userSparks)
      ..writeByte(7)..write(obj.bossHp)
      ..writeByte(8)..write(obj.maxBossHp)
      ..writeByte(9)..write(obj.bossTier)
      ..writeByte(10)..write(obj.lastStreakFreezeDate);
  }
}
