import 'dart:async';
import 'dart:convert';

import 'package:community_package/community_package.dart';
import 'package:community_package/src/core/di/community_dependencies.dart';
import 'package:community_package/src/core/identity/device_details.dart';
import 'package:community_package/src/data/repositories/identity_repository.dart';
import 'package:community_package/src/features/feedback_list/presentation/feedback_list_screen.dart';
import 'package:community_package/src/features/new_feedback/presentation/new_feedback_screen.dart';
import 'package:community_package/src/features/new_feedback/presentation/problem_fields.dart';
import 'package:community_package/src/features/new_feedback/presentation/screen_picker_sheet.dart';
import 'package:flutter/material.dart';
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
    ScreenNode('Settings'),
  ],
);

Map<String, dynamic> _problemJson(int number) => {
  ...feedbackJson(number, type: 'problem'),
  'text': 'Nothing happens\n\n1. Tap plus\n2. Add an item',
  'screenPath': 'Inventory > Sell Items > Add Items',
  'steps': ['Tap plus', 'Add an item'],
  'description': 'Nothing happens',
  'osVersion': 'iOS 18.1',
  'appVersion': '3.2.0',
  'deviceModel': 'iPhone 15 Pro',
};

void main() {
  late FakeBackend backend;
  late BuildContext hostContext;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
  });
  tearDown(CommunityPackage.reset);

  final formScreens = find.byType(NewFeedbackScreen, skipOffstage: false);
  final listScreens = find.byType(FeedbackListScreen, skipOffstage: false);
  final submit = find.byTooltip('submit');
  final cancel = find.byTooltip('cancel');
  final picker = find.byType(ScreenPickerSheet);

  Finder stepField(int index) =>
      find.descendant(of: find.byType(ProblemStepField).at(index), matching: find.byType(TextField));

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Settings → "Give feedback" → Problem. [agreed]: privacy and rules
  /// were agreed before.
  Future<void> openProblem(
    WidgetTester tester, {
    bool agreed = true,
    CommunityConfig config = _config,
    DeviceDetails device = FakeDeviceDetailsSource.sample,
    ThemeData? theme,
  }) async {
    if (agreed) {
      SharedPreferences.setMockInitialValues({IdentityRepository.rulesAgreedKey: true});
    }
    await CommunityPackage.init(config);
    CommunityDependencies.register(
      config,
      httpClient: backend.client,
      anonIdSource: FakeAnonIdSource(id: agreed ? FakeAnonIdSource.createdId : null),
      deviceDetails: FakeDeviceDetailsSource(details: device),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (c) {
            hostContext = c;
            return const Scaffold();
          },
        ),
      ),
    );
    unawaited(CommunityPackage.openNewFeedback(hostContext));
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Problem'));
  }

  Future<void> pickScreen(WidgetTester tester, String name) async {
    await tapAndSettle(tester, find.byType(ScreenPickerField));
    await tapAndSettle(tester, find.descendant(of: picker, matching: find.text(name)));
  }

  Future<void> typeStep(WidgetTester tester, int index, String text) async {
    await tester.enterText(stepField(index), text);
    await tester.pumpAndSettle();
  }

  /// The number shown before step [index].
  Text stepNumber(WidgetTester tester, int index) => tester.widget<Text>(
    find.descendant(of: find.byType(ProblemStepField).at(index), matching: find.text('${index + 1}.')),
  );

  /// Flutter keeps the hint in the tree at opacity 0 once there is text, so
  /// read the decoration rather than look for the text.
  String? stepHint(WidgetTester tester, int index) => tester.widget<TextField>(stepField(index)).decoration!.hintText;

  bool submitEnabled(WidgetTester tester) =>
      tester.widget<InkWell>(find.descendant(of: submit, matching: find.byType(InkWell))).onTap != null;

  testWidgets('shows the screen picker, one step, the description and the device', (tester) async {
    await openProblem(tester);

    expect(find.text('select a screen'), findsOneWidget);
    expect(find.byType(ProblemStepField), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('Step to reproduce the Problem'), findsOneWidget);
    expect(find.text('What went wrong?'), findsOneWidget);
    expect(find.text("What's your idea?"), findsNothing);
    for (final text in ['OS', 'iOS 18.1', 'App', '3.2.0', 'Phone', 'iPhone 15 Pro']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(submitEnabled(tester), isFalse);
  });

  testWidgets('asks what went wrong first, with a ⚠️, then the screen, the steps and the device', (tester) async {
    await openProblem(tester);

    final description = find.widgetWithText(TextField, 'What went wrong?');
    double top(Finder finder) => tester.getTopLeft(finder).dy;
    expect(top(description), lessThan(top(find.byType(ScreenPickerField))));
    expect(top(find.byType(ScreenPickerField)), lessThan(top(find.byType(ProblemStepField))));
    expect(top(find.byType(ProblemStepField)), lessThan(top(find.text('OS'))));

    final warning = find.descendant(of: description, matching: find.text('⚠️'));
    expect(warning, findsOneWidget);
    expect(tester.getCenter(warning).dx, lessThan(tester.getTopLeft(find.text('What went wrong?')).dx));

    await tester.enterText(description, 'Nothing happens');
    await tester.pumpAndSettle();
    expect(warning, findsOneWidget);
  });

  // Settings-3: the first field 28 under the pill, fields 47 high and 4
  // apart; a device box's caption at (6, 3) and its value at (9, 18).
  testWidgets('the Problem form is spaced like Figma', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await openProblem(tester);

    final description = find.widgetWithText(TextField, 'What went wrong?');
    final pill = find.text('Problem');
    final pillBottom = tester.getCenter(pill).dy + 43 / 2;
    final first = tester.getRect(description);
    final screen = tester.getRect(find.byType(ScreenPickerField));
    expect(first.top - pillBottom, moreOrLessEquals(28, epsilon: 0.5));
    // The test font is wide enough to wrap the first hint onto two lines.
    expect((first.left, first.width), (11.0, 368.0));
    expect(screen.height, 47);
    expect(screen.top - first.bottom, 4);

    final box = tester.getRect(find.ancestor(of: find.text('OS'), matching: find.byType(Container)).first);
    expect(tester.getTopLeft(find.text('OS')) - box.topLeft, const Offset(6, 3));
    expect(tester.getTopLeft(find.text('iOS 18.1')) - box.topLeft, const Offset(9, 18));
    expect(box.height, 47);
  });

  testWidgets('a detail that cannot be read shows a dash', (tester) async {
    await openProblem(tester, device: const DeviceDetails(appVersion: '3.2.0'));

    expect(find.text('–'), findsNWidgets(2));
    expect(find.text('3.2.0'), findsOneWidget);
  });

  testWidgets('without screens from the host there is no screen picker', (tester) async {
    await openProblem(tester, config: const CommunityConfig(backendUrl: 'https://example.com', appId: 'inventory'));

    expect(find.byType(ScreenPickerField), findsNothing);
    await typeStep(tester, 0, 'Tap plus');
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('the picker lists every screen, indented, with the package screens last', (tester) async {
    await openProblem(tester);

    await tapAndSettle(tester, find.byType(ScreenPickerField));

    expect(picker, findsOneWidget);
    final names = [
      for (final t in tester.widgetList<Text>(find.descendant(of: picker, matching: find.byType(Text))))
        t.data,
    ];
    expect(names, [
      '📲',
      'select a screen',
      'Inventory',
      'Sell Items',
      'Add Items',
      'Settings',
      'Community',
      'Community App',
      'All Feedback',
      'Feedback Detail',
      'New Feedback',
    ]);
    double left(String name) => tester.getTopLeft(find.descendant(of: picker, matching: find.text(name))).dx;
    expect(left('Sell Items'), greaterThan(left('Inventory')));
    expect(left('Add Items'), greaterThan(left('Sell Items')));
    expect(left('Settings'), left('Inventory'));
  });

  testWidgets('picking a screen shows its path and marks it in the picker', (tester) async {
    await openProblem(tester);

    await pickScreen(tester, 'Add Items');

    expect(picker, findsNothing);
    expect(find.text('Inventory → Sell Items → Add Items'), findsOneWidget);

    await tapAndSettle(tester, find.byType(ScreenPickerField));
    final selectedRow = find.ancestor(
      of: find.descendant(of: picker, matching: find.byIcon(Icons.check)),
      matching: find.byType(Row),
    );
    expect(find.descendant(of: selectedRow.first, matching: find.text('Add Items')), findsOneWidget);

    // A parent row can be picked too.
    await tapAndSettle(tester, find.descendant(of: picker, matching: find.text('Inventory')));
    expect(find.text('Inventory'), findsOneWidget);
  });

  testWidgets('dragging the picker away keeps the screen as it was', (tester) async {
    await openProblem(tester);
    await pickScreen(tester, 'Settings');

    await tapAndSettle(tester, find.byType(ScreenPickerField));
    await tester.drag(find.text('select a screen').last, const Offset(0, 600));
    await tester.pumpAndSettle();

    expect(picker, findsNothing);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('the step number shows in the primary colour before anything is typed', (tester) async {
    final theme = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal));
    await openProblem(tester, theme: theme);

    expect(stepNumber(tester, 0).style?.color, theme.colorScheme.primary);
    expect(tester.widget<TextField>(stepField(0)).controller!.text, isEmpty);
    // Before the hint, on the same line.
    final number = find.descendant(of: find.byType(ProblemStepField), matching: find.text('1.'));
    final hint = find.text('Step to reproduce the Problem');
    expect(tester.getTopLeft(number).dx, lessThan(tester.getTopLeft(hint).dx));
    expect(tester.getCenter(number).dy, moreOrLessEquals(tester.getCenter(hint).dy, epsilon: 2));
  });

  testWidgets("the host's input theme draws no second box inside a step", (tester) async {
    final outline = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    // Like Inventory's theme.
    final theme = ThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey,
        contentPadding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minHeight: 80),
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline,
      ),
    );
    await openProblem(tester, theme: theme);

    void expectNoBox() {
      final decorator = tester.widget<InputDecorator>(
        find.descendant(of: find.byType(ProblemStepField).first, matching: find.byType(InputDecorator)),
      );
      final decoration = decorator.decoration;
      expect(decoration.filled, isFalse);
      expect(decoration.enabledBorder, InputBorder.none);
      expect(decoration.focusedBorder, InputBorder.none);
      expect(decoration.constraints, const BoxConstraints());
    }

    expectNoBox();
    await tester.tap(stepField(0));
    await tester.pumpAndSettle();
    expectNoBox();
    expect(tester.getSize(find.byType(ProblemStepField).first).height, lessThan(80));
  });

  testWidgets('filling a step adds the next one, numbered', (tester) async {
    await openProblem(tester);

    await typeStep(tester, 0, 'Tap plus');

    expect(find.byType(ProblemStepField), findsNWidgets(2));
    expect(stepNumber(tester, 0).data, '1.');
    expect(stepHint(tester, 0), isNull);
    expect(stepNumber(tester, 1).data, '2.');
    expect(stepHint(tester, 1), 'Step to reproduce the Problem');
  });

  testWidgets('a filled step is as tall as its text, even where the hint wraps', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await openProblem(tester);

    await typeStep(tester, 0, 'Tap');

    // The empty step's hint wraps onto a second line at this width.
    expect(tester.getSize(stepField(0)).height, lessThan(tester.getSize(stepField(1)).height));
  });

  testWidgets('Enter on a step moves on to the next step', (tester) async {
    await openProblem(tester);
    await typeStep(tester, 0, 'Tap plus');

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(stepField(1)).focusNode!.hasFocus, isTrue);
  });

  testWidgets('a step emptied and left is removed, and the rest renumber', (tester) async {
    await openProblem(tester);
    await typeStep(tester, 0, 'Tap plus');
    await typeStep(tester, 1, 'Add an item');
    expect(find.byType(ProblemStepField), findsNWidgets(3));

    await typeStep(tester, 0, '');
    await tester.tap(stepField(2)); // leave step 1
    await tester.pumpAndSettle();

    expect(find.byType(ProblemStepField), findsNWidgets(2));
    expect(tester.widget<TextField>(stepField(0)).controller!.text, 'Add an item');
    expect(stepNumber(tester, 0).data, '1.');
    expect(stepNumber(tester, 1).data, '2.');
    expect(stepHint(tester, 1), 'Step to reproduce the Problem');
  });

  testWidgets('✓ needs a screen and a step', (tester) async {
    await openProblem(tester);

    await typeStep(tester, 0, 'Tap plus');
    expect(submitEnabled(tester), isFalse);

    await pickScreen(tester, 'Add Items');
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('submit posts the Problem and its card shows path, description, steps and device', (
    tester,
  ) async {
    await openProblem(tester);
    await pickScreen(tester, 'Add Items');
    await typeStep(tester, 0, 'Tap plus');
    await typeStep(tester, 1, 'Add an item');
    await tester.enterText(find.widgetWithText(TextField, 'What went wrong?'), 'Nothing happens');
    await tester.pumpAndSettle();
    final page = {
      'items': [_problemJson(26), feedbackJson(25)],
      'nextCursor': null,
    };
    backend.answer(_problemJson(26), status: 201);
    backend.answer(page); // the list, loaded after the post
    backend.answer(page); // its revalidation when the list opens

    await tapAndSettle(tester, submit);

    expect(jsonDecode(backend.requests.first.body), {
      'type': 'problem',
      'steps': ['Tap plus', 'Add an item'],
      'screenPath': 'Inventory > Sell Items > Add Items',
      'description': 'Nothing happens',
      'osVersion': 'iOS 18.1',
      'appVersion': '3.2.0',
      'deviceModel': 'iPhone 15 Pro',
    });
    expect(find.text('Thanks! Posted as #26'), findsOneWidget);
    expect(formScreens, findsNothing);
    expect(listScreens, findsOneWidget);
    expect(find.textContaining('Inventory → Sell Items → Add Items', findRichText: true), findsOneWidget);
    expect(find.text('Nothing happens'), findsOneWidget);
    expect(find.textContaining('Tap plus → 2. Add an item', findRichText: true), findsOneWidget);
    expect(find.text('iOS 18.1  App 3.2.0  iPhone 15 Pro'), findsOneWidget);
  });

  testWidgets('the picker, the field and the card show the labels; the English path is saved', (
    tester,
  ) async {
    final labelled = CommunityConfig(
      backendUrl: 'https://example.com',
      appId: 'inventory',
      screens: [
        ScreenNode(
          'Inventory',
          label: (_) => 'Lager',
          children: [
            ScreenNode(
              'Sell Items',
              label: (_) => 'Verkaufen',
              children: [ScreenNode('Add Items', label: (_) => 'Artikel hinzufügen')],
            ),
          ],
        ),
        const ScreenNode('Settings'),
      ],
    );
    await openProblem(tester, config: labelled);
    await tapAndSettle(tester, find.byType(ScreenPickerField));
    expect(find.descendant(of: picker, matching: find.text('Lager')), findsOneWidget);
    expect(find.descendant(of: picker, matching: find.text('Settings')), findsOneWidget);
    expect(find.descendant(of: picker, matching: find.text('Inventory')), findsNothing);
    await tapAndSettle(tester, find.descendant(of: picker, matching: find.text('Artikel hinzufügen')));
    expect(find.text('Lager → Verkaufen → Artikel hinzufügen'), findsOneWidget);

    await typeStep(tester, 0, 'Tap plus');
    final page = {
      'items': [_problemJson(26)],
      'nextCursor': null,
    };
    backend.answer(_problemJson(26), status: 201);
    backend.answer(page);
    backend.answer(page);
    await tapAndSettle(tester, submit);

    expect(
      (jsonDecode(backend.requests.first.body) as Map<String, dynamic>)['screenPath'],
      'Inventory > Sell Items > Add Items',
    );
    expect(find.textContaining('Lager → Verkaufen → Artikel hinzufügen', findRichText: true), findsOneWidget);
  });

  testWidgets('leaving with only a screen chosen asks first', (tester) async {
    await openProblem(tester);
    await pickScreen(tester, 'Settings');

    await tapAndSettle(tester, cancel);

    expect(find.text('Discard this feedback?'), findsOneWidget);
    await tapAndSettle(tester, find.text('Discard'));
    expect(formScreens, findsNothing);
  });

  testWidgets('leaving with only a description asks first', (tester) async {
    await openProblem(tester);
    await tester.enterText(find.widgetWithText(TextField, 'What went wrong?'), 'Broken');
    await tester.pumpAndSettle();

    await tapAndSettle(tester, cancel);

    expect(find.text('Discard this feedback?'), findsOneWidget);
  });

  for (final (name, theme) in [('light', ThemeData.light()), ('dark', ThemeData.dark())]) {
    testWidgets('lays out without overflow on a small phone in $name mode', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await openProblem(
        tester,
        theme: theme,
        device: const DeviceDetails(
          osVersion: 'Android 15',
          appVersion: '10.20.300',
          deviceModel: 'Samsung SM-F956B Galaxy Z Fold6',
        ),
      );
      expect(tester.takeException(), isNull);

      await pickScreen(tester, 'Add Items');
      for (var i = 0; i < 4; i++) {
        await typeStep(tester, i, 'A long step to reproduce the problem. ' * 4);
      }
      await tester.enterText(find.widgetWithText(TextField, 'What went wrong?'), 'It breaks. ' * 40);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
