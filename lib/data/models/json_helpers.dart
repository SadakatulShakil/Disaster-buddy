import 'manifest_exception.dart';

/// Defensive field readers shared by every manifest DTO. Each throws a
/// [ManifestValidationException] naming the missing/invalid field so
/// `ContentAssetSource` can convert it into a user-safe `ContentParseFailure`.

String requireString(Map<String, dynamic> json, String field, String context) {
  final value = json[field];
  if (value is String && value.isNotEmpty) return value;
  throw ManifestValidationException('Missing or invalid "$field" in $context.');
}

String? optionalString(Map<String, dynamic> json, String field) {
  final value = json[field];
  return value is String ? value : null;
}

bool optionalBool(Map<String, dynamic> json, String field, {bool defaultValue = false}) {
  final value = json[field];
  return value is bool ? value : defaultValue;
}

int? optionalInt(Map<String, dynamic> json, String field) {
  final value = json[field];
  return value is int ? value : null;
}

int requireInt(Map<String, dynamic> json, String field, String context) {
  final value = json[field];
  if (value is int) return value;
  throw ManifestValidationException('Missing or invalid "$field" in $context.');
}

/// Accepts either a JSON int or double, since a normalized `0`/`1` boundary
/// value commonly decodes as an int.
double requireDouble(Map<String, dynamic> json, String field, String context) {
  final value = json[field];
  if (value is num) return value.toDouble();
  throw ManifestValidationException('Missing or invalid "$field" in $context.');
}

bool requireBool(Map<String, dynamic> json, String field, String context) {
  final value = json[field];
  if (value is bool) return value;
  throw ManifestValidationException('Missing or invalid "$field" in $context.');
}

Map<String, dynamic> requireObject(Map<String, dynamic> json, String field, String context) {
  final value = json[field];
  if (value is Map<String, dynamic>) return value;
  throw ManifestValidationException('Missing or invalid "$field" in $context.');
}

Map<String, dynamic>? optionalObject(Map<String, dynamic> json, String field) {
  final value = json[field];
  return value is Map<String, dynamic> ? value : null;
}

/// Casts one list entry to an object, for parsing arrays of objects.
Map<String, dynamic> requireListItemObject(dynamic value, String context) {
  if (value is Map<String, dynamic>) return value;
  throw ManifestValidationException('Expected an object in $context.');
}

/// Casts one list entry to a string, for parsing arrays of strings.
String requireListItemString(dynamic value, String context) {
  if (value is String && value.isNotEmpty) return value;
  throw ManifestValidationException('Expected a non-empty string in $context.');
}

List<dynamic> requireList(Map<String, dynamic> json, String field, String context) {
  final value = json[field];
  if (value is List) return value;
  throw ManifestValidationException('Missing or invalid "$field" in $context.');
}
