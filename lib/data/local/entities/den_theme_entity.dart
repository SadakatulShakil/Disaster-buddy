import 'package:floor/floor.dart';

/// Single-row table (id always 0) holding the child's chosen free room
/// theme for Tuku's Den — same "one persisted row" pattern as
/// `StreakStateEntity`.
@Entity(tableName: 'den_theme', primaryKeys: ['id'])
class DenThemeEntity {
  const DenThemeEntity({this.id = 0, required this.themeId});

  final int id;
  final String themeId;
}
