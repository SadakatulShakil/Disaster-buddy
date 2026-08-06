import 'package:floor/floor.dart';

/// One completed beat within one module. Composite primary key means
/// completing the same beat twice is a no-op update, not a duplicate row.
@Entity(tableName: 'progress', primaryKeys: ['moduleId', 'beatId'])
class ProgressEntity {
  const ProgressEntity({
    required this.moduleId,
    required this.beatId,
    required this.completedAt,
  });

  final String moduleId;
  final String beatId;

  /// Epoch millis.
  final int completedAt;
}
