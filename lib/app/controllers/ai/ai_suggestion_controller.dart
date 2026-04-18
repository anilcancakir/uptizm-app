import 'package:magic/magic.dart';

import '../../helpers/http_cache.dart';
import '../../models/dashboard/ai_suggestion.dart';

/// AI inbox controller.
///
/// Owns the pending suggestion list in `rxState`. `accept` promotes a
/// suggestion to an incident (API creates both sides), returning the new
/// incident id so the view can navigate into it. `skip` archives the row.
class AiSuggestionController extends MagicController
    with MagicStateMixin<List<AiSuggestion>>, ValidatesRequests {
  static AiSuggestionController get instance =>
      Magic.findOrPut(AiSuggestionController.new);

  List<AiSuggestion> get suggestions => rxState ?? const [];

  /// Loads the pending AI suggestion inbox into `rxState`. Empty responses
  /// flip to `empty` (not `success`) so the view can render the zero-state.
  Future<void> load() async {
    clearErrors();
    setLoading();
    final response = await HttpCache.get('/dashboard/ai-inbox');
    if (!response.successful) {
      setError(response.errorMessage ?? trans('errors.generic_load'));
      return;
    }
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      setEmpty();
      return;
    }
    final raw = payload['data'];
    if (raw is! List || raw.isEmpty) {
      setEmpty();
      return;
    }
    final items = raw
        .whereType<Map<String, dynamic>>()
        .map(AiSuggestion.fromMap)
        .toList();
    setSuccess(items);
  }

  /// Accepts a suggestion, which promotes it to an incident on the server
  /// and removes it from the inbox locally. Returns the new incident id so
  /// the caller can navigate to the incident detail.
  Future<String?> accept(String id) async {
    clearErrors();
    final previous = List<AiSuggestion>.from(suggestions);
    final response = await Http.post('/ai/suggestions/$id/accept');
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('ai.suggestions.errors.generic_accept'),
      );
      setState(previous, status: rxStatus, notify: false);
      return null;
    }
    final data = response.data?['data'];
    final incidentId = data is Map<String, dynamic>
        ? data['id']?.toString()
        : null;
    setSuccess(previous.where((s) => s.id != id).toList());
    return incidentId;
  }

  /// Archives a suggestion from the inbox without creating an incident.
  /// Restores the previous list on failure.
  Future<bool> skip(String id) async {
    clearErrors();
    final previous = List<AiSuggestion>.from(suggestions);
    final response = await Http.post('/ai/suggestions/$id/skip');
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('ai.suggestions.errors.generic_skip'),
      );
      setState(previous, status: rxStatus, notify: false);
      return false;
    }
    setSuccess(previous.where((s) => s.id != id).toList());
    return true;
  }
}
