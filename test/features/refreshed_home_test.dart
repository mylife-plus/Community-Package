import 'package:community_package/src/core/l10n/community_localizations.dart';
import 'package:community_package/src/core/theme/refresh_style.dart';
import 'package:community_package/src/core/widgets/community_link_row.dart';
import 'package:community_package/src/data/repositories/identity_repository.dart';
import 'package:community_package/src/features/community_home/presentation/community_home_screen.dart';
import 'package:community_package/src/features/privacy/presentation/post_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_anon_id_source.dart';
import '../helpers/host_themes.dart';
import '../helpers/localized_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget screen() {
    final identity = IdentityRepository(FakeAnonIdSource());
    addTearDown(identity.dispose);
    return CommunityHomeScreen(postGate: PostGate(identity: identity));
  }

  testWidgets('link rows sit in one card: radius 16, rows 56 high, rounded chevrons', (tester) async {
    await pumpLocalized(tester, screen());

    final group = find.byType(CommunityLinkGroup);
    final card = tester.widget<Material>(find.descendant(of: group, matching: find.byType(Material)).first);
    final shape = card.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(16));
    final rows = find.byType(CommunityLinkRow);
    final count = rows.evaluate().length;
    expect(count, greaterThanOrEqualTo(1));
    for (final row in rows.evaluate()) {
      expect(tester.getSize(find.byWidget(row.widget)).height, greaterThanOrEqualTo(56));
    }
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(count));
    // A divider between each pair of rows.
    expect(find.descendant(of: group, matching: find.byType(Divider)), findsNWidgets(count - 1));
  });

  testWidgets('intro at 15, the Privacy Notice a 48 high button', (tester) async {
    await pumpLocalized(tester, screen());

    final l = CommunityLocalizations.forLocale(const Locale('en'));
    expect(tester.widget<Text>(find.text(l.communityIntro)).style?.fontSize, 15);
    final privacy = find.ancestor(of: find.text(l.privacyNotice), matching: find.byType(TextButton));
    expect(tester.getSize(privacy).height, greaterThanOrEqualTo(48));
    // The 56 high header.
    expect(tester.getSize(find.byType(AppBar)).height, 56);
  });

  for (final MapEntry(key: name, value: theme) in hostThemes.entries) {
    for (final code in communityLanguages) {
      testWidgets('$name, $code at 320 px: fits; text reads at 4.5:1', (tester) async {
        await pumpLocalized(tester, screen(), theme: theme, locale: code, size: const Size(320, 568));
        expect(tester.takeException(), isNull);

        final l = CommunityLocalizations.forLocale(Locale(code));
        final background = theme.scaffoldBackgroundColor;
        final context = tester.element(find.byType(CommunityLinkGroup));
        final card = RefreshColors.card(context);
        expect(card, isNot(background));
        expect(RefreshColors.contrast(textColor(tester, find.text(l.allFeedback)), card), greaterThanOrEqualTo(4.5));
        expect(RefreshColors.contrast(textColor(tester, find.text(l.communityIntro)), background), greaterThanOrEqualTo(4.5));
        expect(RefreshColors.contrast(textColor(tester, find.text(l.privacyNotice)), background), greaterThanOrEqualTo(4.5));
        final chevron = tester.widget<Icon>(find.byIcon(Icons.chevron_right_rounded).first);
        expect(RefreshColors.contrast(chevron.color!, card), greaterThanOrEqualTo(4.5));
      });
    }
  }
}
