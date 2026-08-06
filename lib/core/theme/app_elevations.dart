/// Elevation scale for Material widgets that take a raw `elevation` value.
/// Prefer [AppShadows] for custom containers; use this only where a widget's
/// API requires a bare double (e.g. `Card.elevation`).
class AppElevations {
  AppElevations._();

  static const double none = 0;
  static const double low = 2;
  static const double medium = 4;
  static const double high = 8;
}
