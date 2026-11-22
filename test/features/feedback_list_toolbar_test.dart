import 'package:community_package/src/core/widgets/feedback_card.dart';
import 'package:community_package/src/core/widgets/feedback_query_menus.dart';
import 'package:community_package/src/data/repositories/identity_repository.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_controller.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_screen.dart';
import 'package:community_package/src/features/privacy/presentation/post_gate.dart';
import 'package:community_package/src/features/privacy/presentation/privacy_notice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_anon_id_source.dart';
import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

void main() {
  late FakeBackend backend;
  late FakeAnonIdSource ids;

  final sortButton = find.byTooltip('Sort');
  final filterButton = find.byTooltip('Filter');
  final searchButton = find.byTooltip('Search');
  final closeSearch = find.byTooltip('Close search');
  final sortMenu = find.byType(FeedbackSortMenu);
  final filterMenu = find.byType(FeedbackFilterMenu);
  Finder heart() => find.textContaining('❤️');

  List<Map<String, String>> listQueries() => [
    for (final r in backend.requests)
      if (r.method == 'GET') r.url.queryParameters,
  ];

  /// All Feedback with [items] (numbers) on the first page. [agreed] is a
  /// user who already agreed to the privacy notice.
  Future<void> open(
    WidgetTester tester, {
    List<int> items = const [3, 2, 1],
    bool agreed = true,
    ThemeData? theme,
  }) async {
    ids = FakeAnonIdSource(id: agreed ? FakeAnonIdSource.createdId : null);
    backend.answer(pageJson(items));
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? ThemeData.dark(),
        home: FeedbackListScreen(
          createController: () => FeedbackListController(backend.repository()),
          postGate: PostGate(identity: IdentityRepository(ids)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
  });

  testWidgets('shows sort, filter, search and + in the toolbar', (tester) async {
    await open(tester);

    expect(sortButton, findsOneWidget);
    expect(filterButton, findsOneWidget);
    expect(searchButton, findsOneWidget);
    expect(find.byTooltip('new Feedback'), findsOneWidget);
  });

  testWidgets('sort: the menu ticks the current order and a choice reloads the list', (tester) async {
    await open(tester);

    await tapAndSettle(tester, sortButton);
    expect(sortMenu, findsOneWidget);
    for (final label in ['Newest', 'Oldest', 'Most hearts', 'Most comments']) {
      expect(find.descendant(of: sortMenu, matching: find.text(label)), findsOneWidget);
    }
    expect(find.descendant(of: sortMenu, matching: find.byIcon(Icons.check_rounded)), findsOneWidget);

    backend.answer(pageJson([1, 3, 2]));
    await tapAndSettle(tester, find.text('Most hearts'));

    expect(sortMenu, findsNothing);
    expect(listQueries().last['sort'], 'reactions');
    final cards = tester.widgetList<FeedbackCard>(find.byType(FeedbackCard));
    expect([for (final c in cards) c.item.number], [1, 3, 2]);
    // The sort icon turns the primary colour while the list is not newest first.
    final icon = tester.widget<SvgPicture>(find.descendant(of: sortButton, matching: find.byType(SvgPicture)));
    expect(icon.colorFilter, ColorFilter.mode(ThemeData.dark().colorScheme.primary, BlendMode.srcIn));
  });

  testWidgets('filter: each tick applies at once, the menu stays open, reset clears', (tester) async {
    await open(tester);

    await tapAndSettle(tester, filterButton);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('reset'), findsNothing);

    backend.answer(pageJson([3]));
    await tapAndSettle(tester, find.descendant(of: filterMenu, matching: find.text('Idea')));
    backend.answer(pageJson([3]));
    await tapAndSettle(tester, find.descendant(of: filterMenu, matching: find.text('done')));

    expect(filterMenu, findsOneWidget);
    expect(find.descendant(of: filterMenu, matching: find.byIcon(Icons.check_rounded)), findsNWidgets(2));
    expect(listQueries().last, {'type': 'idea', 'status': 'done', 'lang': 'en'});

    backend.answer(pageJson([3, 2, 1]));
    await tapAndSettle(tester, find.text('reset'));
    expect(find.descendant(of: filterMenu, matching: find.byIcon(Icons.check_rounded)), findsNothing);

    // A tap outside closes the menu.
    await tester.tapAt(const Offset(200, 500));
    await tester.pumpAndSettle();
    expect(filterMenu, findsNothing);
    expect(find.byType(FeedbackCard), findsNWidgets(3));
  });

  testWidgets('search: waits for a pause in typing, then shows the results', (tester) async {
    await open(tester);

    await tapAndSettle(tester, searchButton);
    expect(sortButton, findsNothing);
    expect(find.byType(TextField), findsOneWidget);

    backend.answer(pageJson([2]));
    await tester.enterText(find.byType(TextField), 'bar');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'barc');
    await tester.pump(FeedbackListController.searchDelay - const Duration(milliseconds: 1));
    expect(listQueries(), hasLength(1));

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(listQueries(), hasLength(2));
    expect(listQueries().last['q'], 'barc');
    expect(find.byType(FeedbackCard), findsOneWidget);

    // ✗ closes the field; the full list comes back from memory.
    backend.answer(pageJson([3, 2, 1]));
    await tapAndSettle(tester, closeSearch);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FeedbackCard), findsNWidgets(3));
  });

  testWidgets('search: the keyboard search key runs it at once, also for a number', (tester) async {
    await open(tester);
    await tapAndSettle(tester, searchButton);

    backend.answer(pageJson([21]));
    await tester.enterText(find.byType(TextField), '#21');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(listQueries().last['q'], '#21');
    expect(find.text('#21'), findsWidgets);
  });

  testWidgets('nothing found offers clear, which brings every post back', (tester) async {
    await open(tester);
    await tapAndSettle(tester, searchButton);

    backend.answer(pageJson([]));
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Nothing found'), findsOneWidget);
    backend.answer(pageJson([3, 2, 1]));
    await tapAndSettle(tester, find.text('Clear'));

    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FeedbackCard), findsNWidgets(3));
  });

  testWidgets('heart: a tap adds it and shows the server count', (tester) async {
    await open(tester, items: [2]);

    backend.answer(feedbackJson(2, reactionCount: 1, reacted: true));
    await tapAndSettle(tester, heart());

    expect(backend.requests.last.method, 'PUT');
    expect(backend.requests.last.url.path, '/v1/feedback/2/reaction');
    expect(find.text('❤️ 1'), findsOneWidget);
  });

  testWidgets('heart: asks for the privacy notice first; decline sends nothing', (tester) async {
    await open(tester, items: [2], agreed: false);

    await tapAndSettle(tester, heart());
    expect(find.byType(PrivacyNoticeSheet), findsOneWidget);
    await tapAndSettle(tester, find.text('Decline'));

    expect(backend.requests.where((r) => r.method == 'PUT'), isEmpty);
    expect(find.text('❤️ 0'), findsOneWidget);

    await tapAndSettle(tester, heart());
    backend.answer(feedbackJson(2, reactionCount: 1, reacted: true));
    await tapAndSettle(tester, find.text('Agree'));

    expect(ids.creates, 1);
    expect(backend.requests.last.method, 'PUT');
    expect(find.text('❤️ 1'), findsOneWidget);
  });

  testWidgets('heart: too many hearts puts it back and says so', (tester) async {
    await open(tester, items: [2]);

    backend.fail(status: 429, code: 'rate_limited');
    await tapAndSettle(tester, heart());

    expect(find.text('Too many hearts. Try again soon.'), findsOneWidget);
    expect(find.text('❤️ 0'), findsOneWidget);
  });

  testWidgets('the heart is easy to hit: taps beside the box count too', (tester) async {
    await open(tester, items: [2]);
    final box = tester.getRect(find.ancestor(of: heart(), matching: find.byType(AnimatedContainer)));
    expect(box.height, 26);

    // Above the box and left of it, in the gap to the comment count.
    backend.answer(feedbackJson(2, reactionCount: 1, reacted: true));
    await tester.tapAt(Offset(box.left - 6, box.top - 5));
    await tester.pumpAndSettle();
    expect(backend.requests.last.method, 'PUT');

    backend.answer(feedbackJson(2));
    await tester.tapAt(Offset(box.center.dx, box.bottom + 4));
    await tester.pumpAndSettle();
    expect(backend.requests.last.method, 'DELETE');
  });

  for (final (name, theme) in [('light', ThemeData.light()), ('dark', ThemeData.dark())]) {
    testWidgets('lays out without overflow on a small phone in $name mode', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(tester, theme: theme);
      expect(tester.takeException(), isNull);

      await tapAndSettle(tester, sortButton);
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(10, 500));
      await tester.pumpAndSettle();

      await tapAndSettle(tester, filterButton);
      expect(tester.takeException(), isNull);
      final menu = tester.getRect(filterMenu);
      expect(menu.left, greaterThanOrEqualTo(0));
      expect(menu.right, lessThanOrEqualTo(320));
      expect(menu.bottom, lessThanOrEqualTo(568));
      await tester.tapAt(const Offset(300, 560));
      await tester.pumpAndSettle();

      await tapAndSettle(tester, searchButton);
      await tester.enterText(find.byType(TextField), 'A long search text that does not fit ' * 2);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
