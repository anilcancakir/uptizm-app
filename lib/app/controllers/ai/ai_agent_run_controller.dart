import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

import '../../../resources/views/settings/settings_ai_activity_view.dart';
import '../../models/ai_agent_run.dart';

/// Audit-log controller for AI agent runs.
///
/// Read-only list, backed by `/ai/agent-runs`. Basic page-based pagination
/// support for the settings activity screen; no mutations exposed.
class AiAgentRunController extends MagicController
    with MagicStateMixin<List<AiAgentRun>>, ValidatesRequests {
  static AiAgentRunController get instance =>
      Magic.findOrPut(AiAgentRunController.new);

  /// Route entry point for `/settings/ai/activity`.
  Widget index() => const SettingsAiActivityView();

  List<AiAgentRun> get runs => rxState ?? const [];

  Future<void> load({int? page}) async {
    clearErrors();
    await fetchList<AiAgentRun>(
      '/ai/agent-runs',
      AiAgentRun.fromMap,
      query: page == null ? null : {'page': page},
    );
  }
}
