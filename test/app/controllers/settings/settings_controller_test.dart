import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

import 'package:app/app/controllers/settings/settings_controller.dart';
import 'package:app/resources/views/settings/settings_hub_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsController', () {
    setUp(() {
      MagicApp.reset();
      Magic.flush();
    });

    test('index() returns SettingsHubView', () {
      expect(SettingsController().index(), isA<SettingsHubView>());
    });
  });
}
