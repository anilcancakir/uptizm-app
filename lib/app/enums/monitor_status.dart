/// Lifecycle state of a monitor at the moment it is rendered.
///
/// Values map 1:1 to Wind tone tokens registered in `lib/config/wind.dart`,
/// so [toneKey] can be fed directly into a widget's `states` parameter.
enum MonitorStatus {
  up,
  down,
  degraded,
  paused;

  /// Wind state key, usable with the `up:` / `down:` / `degraded:` / `paused:`
  /// className prefixes to drive tone-aware styling without interpolation.
  String get toneKey => name;

  /// i18n key resolving to the user-facing label (e.g. "Up", "Down").
  String get labelKey => 'monitor.status.$name';
}
