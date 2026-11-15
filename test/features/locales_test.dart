import 'dart:async';

import 'package:community_package/community_package.dart';
import 'package:community_package/src/core/di/community_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_anon_id_source.dart';
import '../helpers/fake_backend.dart';
import '../helpers/fake_device_details.dart';
import '../helpers/feedback_json.dart';

const _config = CommunityConfig(
  backendUrl: 'https://example.com',
  appId: 'inventory',
  screens: [
    ScreenNode('Inventory', children: [ScreenNode('Sell Items', children: [ScreenNode('Add Items')])]),
  ],
);

const _locales = [Locale('en'), Locale('de'), Locale('es'), Locale('fr'), Locale('pt')];

/// The longest card: a Problem with a status, a cost, path, steps and device.
Map<String, dynamic> _problem(int number) => {
  ...feedbackJson(number, type: 'problem', status: 'in_progress', commentCount: 12, reactionCount: 30),
  'text': 'Nothing happens\n\n1. Tap plus\n2. Add an item',
  'costCents': 125050,
  'screenPath': 'Inventory > Sell Items > Add Items',
  'steps': ['Tap plus', 'Add an item'],
  'description': 'Nothing happens',
  'osVersion': 'iOS 26.1',
  'appVersion': '3.2.0',
  'deviceModel': 'iPhone 17 Pro Max',
};

Map<String, dynamic> _list() => {
  'items': [
    _problem(3),
    feedbackJson(2, status: 'done', commentCount: 2, reactionCount: 4),
    feedbackJson(1, status: 'planned'),
  ],
  'nextCursor': null,
};

/// A widget whose own Semantics carries [label], such as a replies chip.
Finder _semantics(String label) =>
    find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == label);

void main() {
  late FakeBackend backend;
  late BuildContext hostContext;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
  });
  tearDown(CommunityPackage.reset);

  Future<void> host(WidgetTester tester, Locale locale, ThemeData theme) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await CommunityPackage.init(_config);
    CommunityDependencies.register(
      _config,
      httpClient: backend.client,
      anonIdSource: FakeAnonIdSource(),
      deviceDetails: FakeDeviceDetailsSource(details: FakeDeviceDetailsSource.sample),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: locale,
        supportedLocales: _locales,
        localizationsDelegates: const [
          CommunityLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (c) {
            hostContext = c;
            return const Scaffold();
          },
        ),
      ),
    );
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Closes the sheet or menu that shows [inside].
  Future<void> dismiss(WidgetTester tester, Finder inside) async {
    Navigator.of(tester.element(inside.first)).pop();
    await tester.pumpAndSettle();
  }

  void expectNoOverflow(WidgetTester tester, String where) =>
      expect(tester.takeException(), isNull, reason: where);

  for (final locale in _locales) {
    final l = CommunityLocalizations.forLocale(locale);
    for (final (name, theme) in [('light', ThemeData.light()), ('dark', ThemeData.dark())]) {
      testWidgets('${locale.languageCode} $name: every M1 screen lays out at 320 px', (tester) async {
        await host(tester, locale, theme);
        unawaited(CommunityPackage.openCommunity(hostContext));
        await tester.pumpAndSettle();
        expect(find.text(l.communityTitle), findsWidgets);
        expectNoOverflow(tester, 'Community App');

        await tapAndSettle(tester, find.text(l.privacyNotice));
        expect(find.text(l.decline), findsOneWidget);
        expectNoOverflow(tester, 'privacy notice');
        await tapAndSettle(tester, find.text(l.decline));

        backend.answerAt('GET', '/v1/feedback', _list());
        await tapAndSettle(tester, find.text(l.allFeedback));
        expect(find.text(l.statusInProgress), findsOneWidget);
        expectNoOverflow(tester, 'All Feedback');

        await tapAndSettle(tester, find.byTooltip(l.sortTooltip));
        expect(find.text(l.sortComments), findsOneWidget);
        expectNoOverflow(tester, 'sort menu');
        await dismiss(tester, find.text(l.sortComments));

        await tapAndSettle(tester, find.byTooltip(l.filterTooltip));
        expect(find.text(l.filterProgress), findsOneWidget);
        expectNoOverflow(tester, 'filter menu');
        await dismiss(tester, find.text(l.filterProgress));

        await tapAndSettle(tester, find.byTooltip(l.searchTooltip));
        expect(find.text(l.searchHint), findsOneWidget);
        expectNoOverflow(tester, 'search');
        await tapAndSettle(tester, find.byTooltip(l.closeSearch));

        await tapAndSettle(tester, find.byTooltip(l.newFeedbackTitle));
        expect(find.text(l.chooseTopic), findsWidgets);
        expectNoOverflow(tester, 'topic list');
        await tapAndSettle(tester, find.text(l.typeProblem));
        expectNoOverflow(tester, 'Problem form');
        await tapAndSettle(tester, find.text(l.selectScreen));
        expectNoOverflow(tester, 'screen picker');
        await dismiss(tester, find.text('Sell Items'));
        await tapAndSettle(tester, find.text(l.agreeToRules));
        expect(find.text(l.rulesThanks), findsOneWidget);
        expectNoOverflow(tester, 'rules');
        await dismiss(tester, find.text(l.rulesThanks));
        await tapAndSettle(tester, find.byTooltip(l.cancel));

        backend.answerAt('GET', '/v1/feedback/2', feedbackJson(2, status: 'done', commentCount: 2));
        backend.answerAt(
          'GET',
          '/v1/feedback/2/comments',
          commentPageJson([
            commentJson(
              2,
              text: 'Any update?',
              isMine: true,
              edited: true,
              replies: [commentJson(5, parentId: 2, text: 'Working on it', isAdmin: true)],
            ),
            commentJson(1, deleted: true, replies: [commentJson(4, parentId: 1)]),
          ]),
        );
        await tapAndSettle(tester, find.text('Feedback 2'));
        expect(find.text(l.commentDeleted), findsOneWidget);
        expectNoOverflow(tester, 'Feedback Detail');
        await tapAndSettle(tester, _semantics(l.showReplies(1)).first);
        await tapAndSettle(tester, find.byTooltip(l.reply));
        await tapAndSettle(tester, find.byTooltip(l.writeComment));
        expectNoOverflow(tester, 'replies and comment field');
        await tapAndSettle(tester, find.byTooltip(l.editComment).first);
        expect(find.text(l.editCommentTitle), findsWidgets);
        expectNoOverflow(tester, 'Edit Comment');
        await dismiss(tester, find.text(l.editCommentTitle));
        await tapAndSettle(tester, find.byTooltip(l.back));

        // #1 is known from the list, so it shows while the connection is gone.
        backend.offlineAt('GET', '/v1/feedback/1');
        backend.offlineAt('GET', '/v1/feedback/1/comments');
        await tapAndSettle(tester, find.text('Feedback 1'));
        expect(find.textContaining(l.offlineShowingSaved, findRichText: true), findsOneWidget);
        // Under the card; long languages push it below the fold.
        await tester.scrollUntilVisible(find.text(l.errorOffline), 100, scrollable: find.byType(Scrollable).first);
        expect(find.text(l.errorOffline), findsOneWidget);
        expectNoOverflow(tester, 'detail offline');
      });

      testWidgets('${locale.languageCode} $name: offline, empty and no-match messages fit', (tester) async {
        await host(tester, locale, theme);
        backend.offlineAt('GET', '/v1/feedback');
        unawaited(CommunityPackage.openCommunity(hostContext));
        await tester.pumpAndSettle();
        await tapAndSettle(tester, find.text(l.allFeedback));
        expect(find.text(l.errorOffline), findsOneWidget);
        expectNoOverflow(tester, 'offline');

        backend.answerAt('GET', '/v1/feedback', pageJson([]));
        await tapAndSettle(tester, find.text(l.retry));
        expect(find.text(l.emptyFeedbackTitle), findsOneWidget);
        expectNoOverflow(tester, 'empty');

        backend.answerAt('GET', '/v1/feedback', pageJson([]));
        await tapAndSettle(tester, find.byTooltip(l.filterTooltip));
        await tapAndSettle(tester, find.text(l.typeIdea));
        await dismiss(tester, find.text(l.filterProgress));
        expect(find.text(l.noMatchesTitle), findsOneWidget);
        expectNoOverflow(tester, 'no match');
      });
    }
  }

  test('every language has its own labels; others get English', () {
    expect(CommunityLocalizations.forLocale(const Locale('de')).cancel, 'abbrechen');
    expect(CommunityLocalizations.forLocale(const Locale('de', 'AT')).cancel, 'abbrechen');
    expect(CommunityLocalizations.forLocale(const Locale('es')).feedbackTitle, 'Sugerencias');
    expect(CommunityLocalizations.forLocale(const Locale('fr', 'CA')).cancel, 'annuler');
    expect(CommunityLocalizations.forLocale(const Locale('pt', 'BR')).save, 'guardar');
    expect(CommunityLocalizations.forLocale(const Locale('ja')).cancel, 'cancel');
  });

  testWidgets('the delegate loads the app language', (tester) async {
    late CommunityLocalizations labels;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: _locales,
        localizationsDelegates: const [
          CommunityLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (c) {
            labels = CommunityLocalizations.of(c);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(labels.sortTooltip, 'Trier');
  });

  test('numbers, ages and costs per language', () {
    final de = CommunityLocalizations.forLocale(const Locale('de'));
    final es = CommunityLocalizations.forLocale(const Locale('es'));
    final fr = CommunityLocalizations.forLocale(const Locale('fr'));
    final pt = CommunityLocalizations.forLocale(const Locale('pt'));

    expect(de.daysAgo(3), 'vor 3 T.');
    expect(es.monthsAgo(1), 'hace 1 mes');
    expect(es.monthsAgo(2), 'hace 2 meses');
    expect(fr.yearsAgo(1), 'il y a 1 an');
    expect(pt.yearsAgo(2), 'há 2 anos');

    expect(de.costUsd('12.50'), '12,50 \$');
    expect(fr.costUsd('50'), '50 \$');

    expect(de.commentCount(1), '1 Kommentar');
    expect(fr.commentCount(0), '0 commentaire');
    expect(pt.showReplies(2), 'Mostrar 2 respostas');
    expect(fr.postedAs(21), 'Merci ! Publié en tant que #21');
  });

  test('every label is filled in every language', () {
    for (final locale in _locales) {
      final l = CommunityLocalizations.forLocale(locale);
      final texts = [
        l.feedbackTitle, l.errorOffline, l.privacyWhyBody, l.privacyRightsBody, l.rulesTitle,
        l.offlineShowingSaved, l.loadMoreCommentsFailed, l.deleteCommentKeepsReplies,
      ];
      for (final text in texts) {
        expect(text.trim(), isNotEmpty, reason: '${locale.languageCode}: $text');
      }
    }
  });

  test('the legal reference is the agreed one in each language', () {
    final refs = {
      'en': 'Art. 6(1)(f) GDPR',
      'de': 'Art. 6 Abs. 1 lit. f DSGVO',
      'es': 'art. 6.1.f) RGPD',
      'fr': 'art. 6, paragraphe 1, point f) du RGPD',
      'pt': 'art. 6.º, n.º 1, alínea f), do RGPD',
    };
    for (final MapEntry(key: code, value: ref) in refs.entries) {
      expect(CommunityLocalizations.forLocale(Locale(code)).privacyWhyBody, contains(ref));
    }
    // Only en and de name the German authority.
    for (final code in ['es', 'fr', 'pt']) {
      expect(
        CommunityLocalizations.forLocale(Locale(code)).privacyRightsBody,
        isNot(contains('Bundes')),
      );
    }
  });
}
