/// Thrown while parsing a content manifest when a required field is missing
/// or has the wrong shape. Always caught by `ContentAssetSource` and
/// converted into a `ContentParseFailure` — never allowed to crash the app.
class ManifestValidationException implements Exception {
  const ManifestValidationException(this.message);

  final String message;

  @override
  String toString() => 'ManifestValidationException: $message';
}
