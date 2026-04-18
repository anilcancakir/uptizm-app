import 'package:magic/magic.dart';

import '../../models/ai_agent_run.dart';

/// Audit-log controller for AI agent runs.
///
/// Read-only list, backed by `/ai/agent-runs`. Basic page-based pagination
/// support for the settings activity screen; no mutations exposed.
class AiAgentRunController extends MagicController
    with MagicStateMixin<List<AiAgentRun>>, ValidatesRequests {
  static AiAgentRunController get instance =>
      Magic.findOrPut(AiAgentRunController.new);

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
