import 'package:community_package/src/config/screen_node.dart';
import 'package:community_package/src/core/l10n/community_localizations.dart';
import 'package:community_package/src/core/theme/refresh_style.dart';
import 'package:community_package/src/core/widgets/community_menu.dart';
import 'package:community_package/src/core/widgets/feedback_type_picker.dart';
import 'package:community_package/src/core/widgets/refresh_buttons.dart';
import 'package:community_package/src/data/repositories/identity_repository.dart';
import 'package:community_package/src/features/new_feedback/presentation/new_feedback_controller.dart';
import 'package:community_package/src/features/new_feedback/presentation/new_feedback_screen.dart';
import 'package:community_package/src/features/privacy/presentation/post_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_anon_id_source.dart';
import '../helpers/fake_backend.dart';
import '../helpers/fake_device_details.dart';
import '../helpers/host_themes.dart';
import '../helpers/localized_app.dart';

const _screens = [
  ScreenNode('Inventory', children: [ScreenNode('Sell Items', children: [ScreenNode('Add Items')])]),
  ScreenNode('Settings'),
];

void main() {
  late FakeBackend backend;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
  });

  Widget screen() {
    final identity = IdentityRepository(FakeAnonIdSource());
    addTearDown(identity.dispose);
    return NewFeedbackScreen(
      postGate: PostGate(identity: identity),
      createController: () => NewFeedbackController(
        backend.repository(),
        identity,
        screens: _screens,
        deviceDetails: FakeDeviceDetailsSource(),
      ),
    );
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  double contrastOn(WidgetTester tester, Finder text, Color background) =>
      RefreshColors.contrast(textColor(tester, text), background);

  for (final MapEntry(key: name, value: theme) in hostThemes.entries) {
    for (final code in communityLanguages) {
      testWidgets('$name, $code at 320 px: topics, text step and Problem form fit; text reads at 4.5:1', (
        tester,
      ) async {
        await pumpLocalized(tester, screen(), theme: theme, locale: code, size: const Size(320, 568));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final l = CommunityLocalizations.forLocale(Locale(code));
        final background = theme.scaffoldBackgroundColor;

        // The open topic menu.
        final menu = find.byType(FeedbackTypeMenu);
        final menuColor = CommunityMenuFrame.background(tester.element(menu));
        expect(contrastOn(tester, find.descendant(of: menu, matching: find.text(l.typeIdea)), menuColor), greaterThanOrEqualTo(4.5));

        // The text step.
        await tapAndSettle(tester, find.descendant(of: menu, matching: find.text(l.typeIdea)));
        expect(tester.takeException(), isNull);
        final field = RefreshColors.field(tester.element(find.byType(FeedbackTypePill)));
        expect(contrastOn(tester, find.text(l.ideaPrompt), field), greaterThanOrEqualTo(4.5));
        expect(contrastOn(tester, find.text(sentenceCase(l.agreeToRules)), background), greaterThanOrEqualTo(4.5));
        expect(contrastOn(tester, find.text(sentenceCase(l.cancel)), background), greaterThanOrEqualTo(4.5));

        // The Problem form.
        await tapAndSettle(tester, find.byType(FeedbackTypePill));
        await tapAndSettle(tester, find.descendant(of: menu, matching: find.text(l.typeProblem)));
        expect(tester.takeException(), isNull);
        expect(contrastOn(tester, find.text(sentenceCase(l.selectScreen)), field), greaterThanOrEqualTo(4.5));
        expect(contrastOn(tester, find.text('1.'), field), greaterThanOrEqualTo(4.5));
        expect(contrastOn(tester, find.text(l.deviceOs), field), greaterThanOrEqualTo(4.5));
        expect(contrastOn(tester, find.text(FakeDeviceDetailsSource.sample.osVersion!), field), greaterThanOrEqualTo(4.5));

      });
    }
  }
}
