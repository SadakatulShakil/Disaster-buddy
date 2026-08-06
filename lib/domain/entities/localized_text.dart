import 'package:equatable/equatable.dart';

import '../../core/constants/app_constants.dart';

/// A piece of user-facing text with a Bangla and an English rendering.
///
/// Content manifests always provide both; the app picks one via [resolve]
/// based on the active locale, and narration is spoken from whichever
/// string is resolved.
final class LocalizedText extends Equatable {
  const LocalizedText({required this.bn, required this.en});

  final String bn;
  final String en;

  /// Returns [en] when [langCode] is [AppConstants.langEn], otherwise [bn].
  String resolve(String langCode) => langCode == AppConstants.langEn ? en : bn;

  @override
  List<Object?> get props => [bn, en];
}
