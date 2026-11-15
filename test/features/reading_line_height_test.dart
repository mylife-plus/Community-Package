import 'package:community_package/community_package.dart';
import 'package:community_package/src/core/theme/community_theme.dart';
import 'package:community_package/src/core/theme/community_tokens.dart';
import 'package:community_package/src/features/privacy/presentation/privacy_notice_sheet.dart';
import 'package:community_package/src/features/privacy/presentation/rules_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<CommunityLocalizations> pump(WidgetTester tester, Widget sheet) async {
    late CommunityLocalizations l;
    await tester.pumpWidget(
      MaterialApp(
        theme: communityTheme(ThemeData()),
        localizationsDelegates: const [
          CommunityLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Material(
          child: Builder(
            builder: (context) {
              l = CommunityLocalizations.of(context);
              return SizedBox(height: 2000, child: sheet);
            },
          ),
        ),
      ),
    );
    return l;
  }

  double? height(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style?.height;

  testWidgets('the privacy notice paragraphs use the reading line height', (tester) async {
    final l = await pump(tester, const PrivacyNoticeSheet());

    expect(height(tester, l.privacyIntro), CommunityTokens.readingLineHeight);
    // The title keeps Figma's line height.
    expect(height(tester, l.privacyNotice), CommunityTokens.lineHeight);
  });

  testWidgets('the rules and the warning use the reading line height', (tester) async {
    final l = await pump(tester, const RulesSheet());

    expect(height(tester, l.ruleNoPrivateInfo), CommunityTokens.readingLineHeight);
    expect(height(tester, l.rulesWarning), CommunityTokens.readingLineHeight);
    expect(height(tester, l.rulesTitle), CommunityTokens.lineHeight);
  });
}
