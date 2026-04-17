import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../app/enums/ai_confidence.dart';
import '../../../app/enums/ai_trigger.dart';
import '../../../app/enums/incident_severity.dart';
import '../../../app/enums/incident_status.dart';
import '../../../app/enums/signal_source.dart';
import '../../../app/enums/metric_source.dart';
import '../../../app/enums/metric_type.dart';
import '../../../app/models/mock/incident.dart';
import '../../../app/models/mock/monitor_metric.dart';
import '../components/common/empty_state.dart';
import '../components/incidents/incident_create_sheet.dart';
import '../components/incidents/incident_detail_panel.dart';
import '../components/incidents/incident_list_item.dart';
import '../components/incidents/incident_note_composer.dart';

/// Incidents tab.
///
/// Responsive split-view: on `lg+` the list sits on the left and the
/// selected incident renders inline on the right. On smaller widths the
/// list takes the full width and tapping a row opens the detail panel in
/// a modal bottom sheet.
class MonitorIncidentsTab extends StatefulWidget {
  const MonitorIncidentsTab({super.key});

  @override
  State<MonitorIncidentsTab> createState() => _MonitorIncidentsTabState();
}

enum _IncidentTab { triggered, acknowledged, resolved, all }

class _MonitorIncidentsTabState extends State<MonitorIncidentsTab> {
  _IncidentTab _tab = _IncidentTab.triggered;
  bool _aiOnly = false;

  late final List<Incident> _incidents = _mockIncidents();
  late final List<MonitorMetric> _metrics = _mockMetrics();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered(_incidents);

    return WDiv(
      className: 'flex flex-col gap-4',
      children: [
        _toolbar(),
        WDiv(
          className: '''
            rounded-xl overflow-hidden
            bg-white dark:bg-gray-800
            border border-gray-200 dark:border-gray-700
            flex flex-col
          ''',
          child: filtered.isEmpty ? _emptyList() : _list(filtered),
        ),
      ],
    );
  }

  Widget _toolbar() {
    return WDiv(
      className: '''
        flex flex-col items-stretch gap-3
        sm:flex-row sm:items-center
      ''',
      children: [
        WDiv(className: 'w-full sm:flex-1', child: _statusTabs()),
        WButton(
          onTap: () => setState(() => _aiOnly = !_aiOnly),
          states: _aiOnly ? {'active'} : {},
          className: '''
            px-3 py-2.5 rounded-lg
            border border-gray-200 dark:border-gray-700
            bg-white dark:bg-gray-800
            hover:bg-gray-100 dark:hover:bg-gray-700
            active:bg-primary-50 dark:active:bg-primary-900/30
            active:border-primary-300 dark:active:border-primary-700
            flex flex-row items-center justify-center gap-1.5
          ''',
          child: WDiv(
            className: 'flex flex-row items-center gap-1.5',
            children: [
              WIcon(
                Icons.auto_awesome_rounded,
                states: _aiOnly ? {'active'} : {},
                className: '''
                  text-sm text-gray-500 dark:text-gray-400
                  active:text-primary-600 dark:active:text-primary-400
                ''',
              ),
              WText(
                trans('incident.filter.ai_owned'),
                states: _aiOnly ? {'active'} : {},
                className: '''
                  text-sm font-semibold
                  text-gray-700 dark:text-gray-200
                  active:text-primary-700 dark:active:text-primary-300
                ''',
              ),
            ],
          ),
        ),
        WButton(
          onTap: () => IncidentCreateSheet.show(
            context,
            monitorTitle: 'Production API',
            monitorId: 'sample',
            metrics: _metrics,
          ),
          className: '''
            px-4 py-2.5 rounded-lg
            border border-gray-200 dark:border-gray-700
            bg-white dark:bg-gray-800
            hover:bg-gray-100 dark:hover:bg-gray-700
            flex flex-row items-center justify-center gap-1.5
          ''',
          child: WDiv(
            className: 'flex flex-row items-center gap-1.5',
            children: [
              WIcon(
                Icons.add_rounded,
                className: 'text-sm text-gray-700 dark:text-gray-200',
              ),
              WText(
                trans('incident.report_button'),
                className: '''
                  text-sm font-semibold
                  text-gray-700 dark:text-gray-200
                ''',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _list(List<Incident> items) {
    if (items.isEmpty) return _emptyList();
    return WDiv(
      className: 'flex flex-col',
      children: [
        for (final i in items)
          IncidentListItem(incident: i, onTap: () => _openSheet(i)),
      ],
    );
  }

  Future<void> _openSheet(Incident incident) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => IncidentDetailPanel(
          incident: incident,
          onClose: () => MagicRoute.back(),
          onAcknowledge: () {
            MagicRoute.back();
            _acknowledge(incident);
          },
          onResolve: () {
            MagicRoute.back();
            _resolve(incident);
          },
          onAddNote: () =>
              IncidentNoteComposer.show(ctx, incidentTitle: incident.title),
        ),
      ),
    );
  }

  void _acknowledge(Incident incident) {
    Magic.toast(trans('incident.toast.acknowledged'));
  }

  void _resolve(Incident incident) {
    Magic.toast(trans('incident.toast.resolved'));
  }

  Widget _statusTabs() {
    return WDiv(
      className: '''
        rounded-xl p-1
        bg-gray-100 dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-row gap-1
        overflow-x-auto sm:overflow-visible
      ''',
      children: [
        for (final t in _IncidentTab.values)
          WButton(
            onTap: () => setState(() => _tab = t),
            states: _tab == t ? {'active'} : {},
            className: '''
              sm:flex-1 px-3 py-2 rounded-lg
              hover:bg-gray-200/60 dark:hover:bg-gray-700/60
              active:bg-white dark:active:bg-gray-900
              active:shadow-sm
              flex flex-row items-center justify-center gap-2
            ''',
            child: _statusTabChild(t),
          ),
      ],
    );
  }

  Widget _statusTabChild(_IncidentTab t) {
    return WDiv(
      className: 'flex flex-row items-center gap-2',
      children: [
        WText(
          trans('incident.tab.${t.name}'),
          states: _tab == t ? {'active'} : {},
          className: '''
            text-sm font-semibold
            text-gray-500 dark:text-gray-400
            active:text-gray-900 dark:active:text-white
          ''',
        ),
        WDiv(
          states: _tab == t ? {'active'} : {},
          className: '''
            px-1.5 py-0.5 rounded-full
            bg-gray-200 dark:bg-gray-700
            active:bg-primary-100 dark:active:bg-primary-900/40
          ''',
          child: WText(
            '${_countFor(t)}',
            states: _tab == t ? {'active'} : {},
            className: '''
              text-[10px] font-bold
              text-gray-600 dark:text-gray-300
              active:text-primary-700 dark:active:text-primary-300
            ''',
          ),
        ),
      ],
    );
  }

  bool _matchesTab(Incident i, _IncidentTab t) {
    return switch (t) {
      _IncidentTab.triggered => i.status == IncidentStatus.detected,
      _IncidentTab.acknowledged =>
        i.status == IncidentStatus.investigating ||
            i.status == IncidentStatus.mitigated,
      _IncidentTab.resolved => i.status == IncidentStatus.resolved,
      _IncidentTab.all => true,
    };
  }

  int _countFor(_IncidentTab t) {
    return _incidents
        .where((i) => _matchesTab(i, t) && (!_aiOnly || i.aiOwned))
        .length;
  }

  List<Incident> _filtered(List<Incident> all) {
    return all
        .where((i) => _matchesTab(i, _tab) && (!_aiOnly || i.aiOwned))
        .toList();
  }

  Widget _emptyList() {
    return const EmptyState(
      icon: Icons.shield_moon_rounded,
      titleKey: 'incident.empty.title',
      subtitleKey: 'incident.empty.subtitle',
      tone: 'up',
      variant: 'plain',
    );
  }

  List<Incident> _mockIncidents() {
    final now = DateTime.now();
    return [
      Incident(
        id: 'i1',
        monitorId: 'm1',
        title: 'Database connection pool degraded',
        severity: IncidentSeverity.warn,
        status: IncidentStatus.investigating,
        startedAt: now.subtract(const Duration(minutes: 18)),
        signalSource: SignalSource.userThreshold,
        triggerRef: 'db_conn_ms',
        metricKey: 'db_conn_ms',
        metricLabel: 'db.conn_ms',
        aiOwned: true,
        aiAnalysis: AiAnalysis(
          tldr:
              'DB connection latency crossed the warn band 3 checks in a row. '
              'Matches the pattern from two prior pool exhaustion incidents.',
          confidence: AiConfidence.high,
          trigger: AiTrigger.threshold,
          evidence: const [
            AiEvidence(
              label: 'db.conn_ms above warn',
              detail: '312 ms avg (warn: 250 ms) across 3 checks',
              metricKey: 'db_conn_ms',
            ),
            AiEvidence(
              label: 'Error rate unchanged',
              detail: '2xx responses still 99.4%',
            ),
            AiEvidence(
              label: 'Pattern match',
              detail: 'Similar shape to incident #i-prev-04 (pool exhaustion)',
            ),
          ],
          suggestedActions: const [
            AiSuggestedAction(
              title: 'Raise pool size to 40',
              rationale:
                  'Last two incidents resolved after bumping max connections.',
            ),
            AiSuggestedAction(
              title: 'Check slow query log',
              rationale:
                  'A single slow query can saturate the pool within minutes.',
            ),
          ],
        ),
        similarIncidents: [
          SimilarIncident(
            id: 'i-prev-04',
            title: 'Pool exhaustion after deploy',
            occurredAt: now.subtract(const Duration(days: 12)),
            resolutionNote: 'Pool size bumped 20 → 40; auto-resolved in 6m.',
          ),
          SimilarIncident(
            id: 'i-prev-02',
            title: 'Slow query saturated pool',
            occurredAt: now.subtract(const Duration(days: 34)),
            resolutionNote: 'Killed runaway query; added index.',
          ),
        ],
        events: [
          IncidentEvent(
            at: now.subtract(const Duration(minutes: 18)),
            actor: 'ai',
            type: 'opened',
            message:
                'Opened incident: db.conn_ms crossed warn band for 3 checks.',
          ),
          IncidentEvent(
            at: now.subtract(const Duration(minutes: 17)),
            actor: 'ai',
            type: 'ai_suggestion',
            message:
                'Running similarity search against 90-day history. High '
                'confidence match with i-prev-04.',
          ),
          IncidentEvent(
            at: now.subtract(const Duration(minutes: 15)),
            actor: 'system',
            type: 'status_changed',
            message: 'Status: detected → investigating.',
          ),
          IncidentEvent(
            at: now.subtract(const Duration(minutes: 12)),
            actor: 'ai',
            type: 'note',
            message:
                'Watching next 5 checks. Will auto-resolve if db.conn_ms '
                'stays below 200 ms.',
          ),
        ],
      ),
      Incident(
        id: 'i2',
        monitorId: 'm1',
        title: 'eu-central-1 probe failing',
        severity: IncidentSeverity.critical,
        status: IncidentStatus.detected,
        startedAt: now.subtract(const Duration(minutes: 6)),
        signalSource: SignalSource.aiAnomaly,
        triggerRef: 'uptime',
        metricKey: 'uptime',
        metricLabel: 'uptime',
        aiOwned: true,
        aiAnalysis: AiAnalysis(
          tldr:
              'Single-region failure from eu-central-1. Other 3 regions are '
              'green, likely a regional routing blip rather than app outage.',
          confidence: AiConfidence.medium,
          trigger: AiTrigger.anomaly,
          evidence: const [
            AiEvidence(
              label: '1 of 4 regions down',
              detail:
                  'eu-central-1 timing out; eu-west-1 / us-east-1 / ap-southeast-1 green',
            ),
            AiEvidence(
              label: 'Connection timeout',
              detail: 'Last error: connect ETIMEDOUT after 30s',
            ),
          ],
          suggestedActions: const [
            AiSuggestedAction(
              title: 'Wait 2 more checks',
              rationale:
                  'Short regional blips usually self-recover within 3 checks.',
            ),
            AiSuggestedAction(
              title: 'Check cloud provider status page',
              rationale: 'Could be upstream network issue, not your app.',
            ),
          ],
        ),
        events: [
          IncidentEvent(
            at: now.subtract(const Duration(minutes: 6)),
            actor: 'ai',
            type: 'opened',
            message: 'Opened incident: eu-central-1 probe timed out.',
          ),
          IncidentEvent(
            at: now.subtract(const Duration(minutes: 5)),
            actor: 'ai',
            type: 'note',
            message:
                '3/4 regions still green. Holding status at detected pending '
                'next 2 checks.',
          ),
        ],
      ),
      Incident(
        id: 'i3',
        monitorId: 'm1',
        title: 'Response time spike recovered',
        severity: IncidentSeverity.info,
        status: IncidentStatus.resolved,
        startedAt: now.subtract(const Duration(hours: 5, minutes: 22)),
        resolvedAt: now.subtract(const Duration(hours: 5, minutes: 4)),
        signalSource: SignalSource.aiAnomaly,
        triggerRef: 'avg_response',
        metricKey: 'avg_response',
        metricLabel: 'avg_response',
        aiOwned: true,
        aiAnalysis: AiAnalysis(
          tldr:
              'Response time briefly doubled then recovered on its own. No '
              'action taken: auto-resolved after 5 healthy checks.',
          confidence: AiConfidence.high,
          trigger: AiTrigger.anomaly,
          evidence: const [
            AiEvidence(
              label: 'Anomaly score peaked',
              detail: 'p95 response hit 1.8s (baseline 240ms)',
            ),
            AiEvidence(
              label: 'Recovered within 18 min',
              detail: '5 consecutive checks below warn band',
            ),
          ],
        ),
        events: [
          IncidentEvent(
            at: now.subtract(const Duration(hours: 5, minutes: 22)),
            actor: 'ai',
            type: 'opened',
            message: 'Opened incident: anomalous response time detected.',
          ),
          IncidentEvent(
            at: now.subtract(const Duration(hours: 5, minutes: 4)),
            actor: 'ai',
            type: 'ai_auto_resolved',
            message:
                'Auto-resolved: 5 consecutive healthy checks, no user action '
                'required.',
          ),
        ],
      ),
      Incident(
        id: 'i4',
        monitorId: 'm1',
        title: 'SSL certificate expiring soon',
        severity: IncidentSeverity.warn,
        status: IncidentStatus.mitigated,
        startedAt: now.subtract(const Duration(days: 1, hours: 3)),
        signalSource: SignalSource.userThreshold,
        triggerRef: 'ssl_days_to_expiry',
        metricKey: 'ssl_days_to_expiry',
        metricLabel: 'ssl.days_to_expiry',
        aiOwned: false,
        events: [
          IncidentEvent(
            at: now.subtract(const Duration(days: 1, hours: 3)),
            actor: 'ai',
            type: 'opened',
            message: 'Opened incident: SSL cert expires in 14 days.',
          ),
          IncidentEvent(
            at: now.subtract(const Duration(hours: 22)),
            actor: 'u-1',
            actorLabel: 'Anıl',
            type: 'acknowledged',
            message: 'Picking this up, renewal scheduled for next Monday.',
          ),
          IncidentEvent(
            at: now.subtract(const Duration(hours: 2)),
            actor: 'u-1',
            actorLabel: 'Anıl',
            type: 'status_changed',
            message: 'Renewal queued, marking mitigated.',
          ),
        ],
      ),
      Incident(
        id: 'i5',
        monitorId: 'm1',
        title: 'Checkout 5xx spike reported by support',
        severity: IncidentSeverity.warn,
        status: IncidentStatus.investigating,
        startedAt: now.subtract(const Duration(minutes: 42)),
        signalSource: SignalSource.manual,
        metricLabel: null,
        aiOwned: false,
        aiAnalysis: AiAnalysis(
          tldr:
              'No matching threshold or anomaly fired for this monitor yet. '
              'Based on note keywords (checkout, 5xx) I checked related '
              'metrics and found nothing anomalous. Likely regional or '
              'client-side; keep watching.',
          confidence: AiConfidence.low,
          trigger: AiTrigger.manualAssist,
          evidence: const [
            AiEvidence(
              label: 'No metric crossed',
              detail: 'avg_response, error_rate, uptime all within band',
            ),
            AiEvidence(
              label: 'Support ticket correlation',
              detail: '2 tickets in last 30 min from TR region',
            ),
          ],
        ),
        events: [
          IncidentEvent(
            at: now.subtract(const Duration(minutes: 42)),
            actor: 'u-1',
            actorLabel: 'Anıl',
            type: 'opened',
            message: 'Opened manually: support sees 5xx on checkout.',
          ),
          IncidentEvent(
            at: now.subtract(const Duration(minutes: 40)),
            actor: 'ai',
            type: 'ai_suggestion',
            message:
                'No server-side metric is firing. Suggest inspecting regional '
                'traffic and client logs next.',
          ),
        ],
      ),
    ];
  }

  List<MonitorMetric> _mockMetrics() {
    return const [
      MonitorMetric(
        group: 'Response',
        label: 'avg_response',
        key: 'avg_response',
        type: MetricType.numeric,
        unit: 'ms',
      ),
      MonitorMetric(
        group: 'Response',
        label: 'uptime',
        key: 'uptime',
        type: MetricType.numeric,
        unit: '%',
      ),
      MonitorMetric(
        group: 'Database',
        label: 'db.conn_ms',
        key: 'db_conn_ms',
        type: MetricType.numeric,
        source: MetricSource.jsonPath,
        unit: 'ms',
      ),
      MonitorMetric(
        group: 'SSL',
        label: 'ssl.days_to_expiry',
        key: 'ssl_days_to_expiry',
        type: MetricType.numeric,
        source: MetricSource.header,
        unit: 'd',
      ),
    ];
  }

  /// AI-authored suggestions not yet promoted to incidents.
  ///
  /// Produced in AiMode=suggest. Auto-promoted in AiMode=auto, never created
  /// in AiMode=off. Rendering is deferred to a later decision turn; this
  /// list only exists so downstream work can wire it in.
  // ignore: unused_element
  List<AiSuggestion> _mockSuggestions() {
    final now = DateTime.now();
    return [
      AiSuggestion(
        id: 's1',
        monitorId: 'm1',
        suggestedTitle: 'Cache hit rate drifting down',
        suggestedSeverity: IncidentSeverity.info,
        confidence: AiConfidence.medium,
        tldr:
            'x-cache HIT ratio dropped from 82% to 61% over the last 2 hours. '
            'Not yet a threshold breach, but worth a look.',
        metricKey: 'cache_hit_ratio',
        createdAt: now.subtract(const Duration(minutes: 9)),
      ),
    ];
  }
}
