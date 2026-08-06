import 'package:floor/floor.dart';

/// One badge earned by the child. `badgeId` is globally unique across
/// modules (defined in the module's content manifest), so it is the key.
@Entity(tableName: 'badges', primaryKeys: ['badgeId'])
class BadgeEntity {
  const BadgeEntity({
    required this.badgeId,
    required this.moduleId,
    required this.earnedAt,
  });

  final String badgeId;
  final String moduleId;

  /// Epoch millis.
  final int earnedAt;
}
