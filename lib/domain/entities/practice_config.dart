import 'package:equatable/equatable.dart';

import 'localized_text.dart';
import 'practice_item.dart';

/// Generic configuration for a [PracticeBeat]'s mini-game. The same shape —
/// [instructions] plus a list of [items] — is interpreted differently by
/// each registered `PracticeGame`, so adding a new mini-game never requires
/// a new config type, only a new reading of [items].
final class PracticeConfig extends Equatable {
  const PracticeConfig({required this.instructions, required this.items});

  final LocalizedText instructions;
  final List<PracticeItem> items;

  @override
  List<Object?> get props => [instructions, items];
}
