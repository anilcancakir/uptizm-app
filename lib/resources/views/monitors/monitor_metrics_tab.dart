import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../app/enums/metric_type.dart';
import '../../../app/enums/monitor_status.dart';
import '../../../app/models/mock/monitor_metric.dart';
import '../components/monitors/metric_detail_sheet.dart';
import '../components/monitors/metric_form_sheet.dart';
import '../components/monitors/metric_group_section.dart';
import '../components/monitors/metrics_empty_state.dart';

/// Metrics tab body for the monitor detail screen.
///
/// Renders user-defined metric groups with hardcoded mock samples for
/// design iteration. Wire to API/controller in a later pass.
class MonitorMetricsTab extends StatelessWidget {
  const MonitorMetricsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = _mockGroups();

    if (groups.isEmpty) {
      return const MetricsEmptyState();
    }

    final groupNames = groups.keys.toList();

    return WDiv(
      className: 'flex flex-col gap-6',
      children: [
        for (final entry in groups.entries)
          MetricGroupSection(
            group: entry.key,
            icon: _groupIcon(entry.key),
            metrics: entry.value,
            onMetricTap: (m) => MetricDetailSheet.show(context, m),
            onAddMetric: () => MetricFormSheet.show(
              context,
              mode: 'create',
              existingGroups: groupNames,
              initial: MetricFormInitial(group: entry.key),
            ),
          ),
      ],
    );
  }

  IconData _groupIcon(String group) {
    return switch (group.toLowerCase()) {
      'database' => Icons.storage_rounded,
      'queue' => Icons.layers_rounded,
      'cache' => Icons.bolt_rounded,
      'runtime' => Icons.memory_rounded,
      _ => Icons.analytics_rounded,
    };
  }

  Map<String, List<MonitorMetric>> _mockGroups() {
    return {
      'Database': [
        MonitorMetric(
          group: 'Database',
          label: 'DB Size',
          key: 'db_size',
          type: MetricType.numeric,
          path: 'data.database.size_mb',
          unit: 'MB',
          numericValue: 2480,
          band: MetricBand.ok,
          trendLabel: '+24 MB',
          trendPositive: false,
          samples: const [
            2410, 2420, 2425, 2430, 2438, 2445, 2451, 2458,
            2462, 2465, 2470, 2472, 2474, 2476, 2478, 2479,
            2480, 2480, 2480, 2480,
          ],
        ),
        MonitorMetric(
          group: 'Database',
          label: 'Active Connections',
          key: 'db_conn',
          type: MetricType.numeric,
          path: 'data.database.connections.active',
          numericValue: 47,
          band: MetricBand.warn,
          trendLabel: '+12',
          trendPositive: false,
          samples: const [
            24, 26, 28, 31, 29, 30, 33, 36,
            38, 40, 42, 41, 43, 45, 46, 47,
            47, 47, 47, 47,
          ],
        ),
        MonitorMetric(
          group: 'Database',
          label: 'Replica Lag',
          key: 'db_replica_lag',
          type: MetricType.numeric,
          path: 'data.database.replica.lag_ms',
          unit: 'ms',
          numericValue: 12,
          band: MetricBand.ok,
          trendLabel: '-3 ms',
          trendPositive: true,
          samples: const [
            18, 20, 17, 16, 22, 15, 14, 16,
            18, 14, 13, 15, 12, 11, 13, 12,
            12, 11, 12, 12,
          ],
        ),
        MonitorMetric(
          group: 'Database',
          label: 'Replica Connected',
          key: 'db_replica_up',
          type: MetricType.status,
          path: 'data.database.replica.connected',
          statusValue: MonitorStatus.up,
          statusHistory: const [
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.degraded, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up,
          ],
        ),
      ],
      'Queue': [
        MonitorMetric(
          group: 'Queue',
          label: 'Worker Running',
          key: 'queue_worker',
          type: MetricType.status,
          path: 'data.queue.worker.running',
          statusValue: MonitorStatus.up,
          statusHistory: const [
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up,
          ],
        ),
        MonitorMetric(
          group: 'Queue',
          label: 'Scheduler',
          key: 'queue_scheduler',
          type: MetricType.status,
          path: 'data.queue.scheduler.running',
          statusValue: MonitorStatus.degraded,
          statusHistory: const [
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.degraded,
            MonitorStatus.degraded, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.degraded, MonitorStatus.down,
            MonitorStatus.degraded, MonitorStatus.degraded,
            MonitorStatus.degraded, MonitorStatus.degraded,
            MonitorStatus.degraded,
          ],
        ),
        MonitorMetric(
          group: 'Queue',
          label: 'Pending Jobs',
          key: 'queue_pending',
          type: MetricType.numeric,
          path: 'data.queue.pending',
          numericValue: 342,
          band: MetricBand.warn,
          trendLabel: '+58',
          trendPositive: false,
          samples: const [
            180, 195, 210, 240, 255, 268, 280, 295,
            302, 310, 318, 322, 328, 335, 338, 340,
            341, 342, 342, 342,
          ],
        ),
        MonitorMetric(
          group: 'Queue',
          label: 'Failed Jobs',
          key: 'queue_failed',
          type: MetricType.numeric,
          path: 'data.queue.failed',
          numericValue: 3,
          band: MetricBand.ok,
          trendLabel: '0',
          trendPositive: true,
          samples: const [
            2, 2, 2, 3, 3, 3, 3, 3,
            3, 3, 3, 3, 3, 3, 3, 3,
            3, 3, 3, 3,
          ],
        ),
        MonitorMetric(
          group: 'Queue',
          label: 'Last Job Finished',
          key: 'queue_last_job_ms',
          type: MetricType.numeric,
          path: 'data.queue.last_finished_ms_ago',
          unit: 'ms',
          numericValue: 12000,
        ),
      ],
      'Cache': [
        MonitorMetric(
          group: 'Cache',
          label: 'Redis Reachable',
          key: 'cache_redis',
          type: MetricType.status,
          path: 'data.cache.redis.connected',
          statusValue: MonitorStatus.up,
          statusHistory: const [
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up, MonitorStatus.up,
            MonitorStatus.up, MonitorStatus.up,
          ],
        ),
        MonitorMetric(
          group: 'Cache',
          label: 'Hit Rate',
          key: 'cache_hit_rate',
          type: MetricType.numeric,
          path: 'data.cache.hit_rate',
          unit: '%',
          numericValue: 94,
          band: MetricBand.ok,
          trendLabel: '+1%',
          trendPositive: true,
          samples: const [
            88, 89, 90, 91, 90, 92, 91, 92,
            93, 93, 93, 94, 94, 94, 94, 94,
            94, 94, 94, 94,
          ],
        ),
      ],
      'Runtime': [
        MonitorMetric(
          group: 'Runtime',
          label: 'App Version',
          key: 'app_version',
          type: MetricType.string,
          path: 'data.app.version',
          stringValue: 'v1.4.2',
        ),
        MonitorMetric(
          group: 'Runtime',
          label: 'Last Deploy',
          key: 'last_deploy_s',
          type: MetricType.numeric,
          path: 'data.app.deployed_s_ago',
          unit: 's',
          numericValue: 10800,
        ),
      ],
    };
  }
}
