import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

import '../../../resources/views/settings/settings_hub_view.dart';

/// Resource controller for the settings hub (`/settings`).
///
/// Stateless today: exposes a single [hub] view builder so the route file
/// can wire the hub through its controller, matching the same pattern the
/// per-sub-domain settings controllers (AI, appearance, metrics library)
/// already use.
class SettingsController extends MagicController {
  static SettingsController get instance =>
      Magic.findOrPut(SettingsController.new);

  /// Route entry point for `/settings`.
  Widget hub() => const SettingsHubView();
}
