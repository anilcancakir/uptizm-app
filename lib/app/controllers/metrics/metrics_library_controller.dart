import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

import '../../../resources/views/settings/settings_metrics_library_view.dart';
import '../../models/monitor_metric.dart';

/// Read-only list of every custom metric declared across the current
/// team's monitors. Powers the settings metrics library screen.
class MetricsLibraryController extends MagicController
    with MagicStateMixin<List<MonitorMetric>> {
  static MetricsLibraryController get instance =>
      Magic.findOrPut(MetricsLibraryController.new);

  /// Route entry point for `/settings/metrics-library`.
  Widget index() => const SettingsMetricsLibraryView();

  List<MonitorMetric> get metrics => rxState ?? const [];

  /// Loads the team-wide metrics catalog into `rxState`.
  Future<void> load() =>
      fetchList('/settings/metrics-library', MonitorMetric.fromMap);
}
