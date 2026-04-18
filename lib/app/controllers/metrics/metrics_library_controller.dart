import 'package:magic/magic.dart';

import '../../models/monitor_metric.dart';

/// Read-only list of every custom metric declared across the current
/// team's monitors. Powers the settings metrics library screen.
class MetricsLibraryController extends MagicController
    with MagicStateMixin<List<MonitorMetric>> {
  static MetricsLibraryController get instance =>
      Magic.findOrPut(MetricsLibraryController.new);

  List<MonitorMetric> get metrics => rxState ?? const [];

  Future<void> load() =>
      fetchList('/settings/metrics-library', MonitorMetric.fromMap);
}
