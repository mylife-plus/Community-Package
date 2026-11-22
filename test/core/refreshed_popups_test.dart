import 'package:community_package/src/core/l10n/community_localizations.dart';
import 'package:community_package/src/core/theme/refresh_style.dart';
import 'package:community_package/src/core/widgets/community_menu.dart';
import 'package:community_package/src/core/widgets/community_popups.dart';
import 'package:community_package/src/core/widgets/feedback_query_menus.dart';
import 'package:community_package/src/core/utils/formatters.dart';
import 'package:community_package/src/data/models/feedback_item.dart';
import 'package:community_package/src/data/models/feedback_query.dart';
import 'package:community_package/src/core/widgets/refresh_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/host_themes.dart';

const _languages = ['en', 'de', 'es', 'fr', 'pt'];

/// Pumps an app with [theme] and [locale] at [size] and returns a context
/// below the localizations to open popups from.
Future<BuildContext> _pump(
  WidgetTester tester, {
  ThemeData? theme,
  String locale = 'en',
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      locale: Locale(locale),
      supportedLocales: [for (final code in _languages) Locale(code)],
      localizationsDelegates: const [
        CommunityLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  return context;
}

void main() {
  group('confirm dialog', () {
    Future<void> openDelete(BuildContext context) async {
      final l = CommunityLocalizations.of(context);
      showCommunityConfirm(
        context,
        title: l.deleteCommentKeepsReplies,
        confirmLabel: l.delete,
        cancelLabel: l.cancel,
      );
    }

    testWidgets('Cancel on the left, the red action on the right, 48 high', (tester) async {
      final context = await _pump(tester);
      openDelete(context);
      await tester.pumpAndSettle();

      final cancel = tester.getRect(find.widgetWithText(RefreshButton, 'Cancel'));
      final delete = tester.getRect(find.widgetWithText(RefreshButton, 'Delete'));
      expect(cancel.height, 48);
      expect(delete.height, 48);
      expect(cancel.top, delete.top);
      expect(cancel.right, lessThan(delete.left));
      expect(delete.left - cancel.right, 12);
      expect(cancel.width, delete.width);
      final kind = tester.widget<RefreshButton>(find.widgetWithText(RefreshButton, 'Delete')).kind;
      expect(kind, RefreshButtonKind.destructive);
    });

    testWidgets('the sheet colour, radius 24, 16 from the screen sides', (tester) async {
      final context = await _pump(tester);
      openDelete(context);
      await tester.pumpAndSettle();

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.backgroundColor, RefreshColors.sheet(context));
      expect(dialog.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)));
      final rect = tester.getRect(find.descendant(of: find.byType(Dialog), matching: find.byType(Material)).first);
      // Dialog's own max width is 560; at 390 the inset decides.
      expect(rect.left, 16);
      expect(390 - rect.right, 16);
    });

    for (final MapEntry(key: name, value: theme) in hostThemes.entries) {
      for (final code in _languages) {
        testWidgets('$name, $code at 320 px: fits, and the labels read at 4.5:1', (tester) async {
          final context = await _pump(tester, theme: theme, locale: code, size: const Size(320, 568));
          openDelete(context);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final l = CommunityLocalizations.of(context);
          final dialogContext = tester.element(find.byType(RefreshButtonPair));
          final sheet = RefreshColors.sheet(dialogContext);
          final scheme = theme.colorScheme;
          expect(RefreshColors.contrast(scheme.onSurface, sheet), greaterThanOrEqualTo(4.5));
          final red = tester.widget<RefreshButton>(find.widgetWithText(RefreshButton, sentenceCase(l.delete)));
          final redColor =
              DefaultTextStyle.of(
                tester.element(find.descendant(of: find.byWidget(red), matching: find.text(sentenceCase(l.delete)))),
              ).style.color!;
          expect(
            RefreshColors.contrast(redColor, RefreshColors.errorTonal(dialogContext)),
            greaterThanOrEqualTo(4.5),
            reason: 'red ${sentenceCase(l.delete)} on its tonal background',
          );
          // Both buttons in full, side by side or stacked.
          for (final label in [l.cancel, l.delete]) {
            final text = find.descendant(of: find.byType(RefreshButtonPair), matching: find.text(sentenceCase(label)));
            expect(tester.renderObject<RenderParagraph>(text).didExceedMaxLines, isFalse);
          }
        });
      }
    }

    testWidgets('a label too long for half the width stacks both, Cancel first', (tester) async {
      final context = await _pump(tester, size: const Size(320, 568));
      showCommunityConfirm(
        context,
        title: 'Leave?',
        confirmLabel: 'discard everything written so far',
        cancelLabel: 'keep',
      );
      await tester.pumpAndSettle();

      final keep = tester.getRect(find.widgetWithText(RefreshButton, 'Keep'));
      final discard = tester.getRect(find.widgetWithText(RefreshButton, 'Discard everything written so far'));
      expect(keep.width, discard.width);
      expect(discard.top - keep.bottom, 12);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cancel gives false, the action true, tapping outside false', (tester) async {
      final context = await _pump(tester);
      for (final (tap, expected) in [('Cancel', false), ('Delete', true), (null, false)]) {
        final result = showCommunityConfirm(context, title: 'Delete?', confirmLabel: 'delete', cancelLabel: 'cancel');
        await tester.pumpAndSettle();
        if (tap != null) {
          await tester.tap(find.text(tap));
        } else {
          await tester.tapAt(const Offset(10, 10));
        }
        await tester.pumpAndSettle();
        expect(await result, expected);
      }
    });
  });

  group('sort and filter menus', () {
    Future<void> openFilter(BuildContext context) => showFeedbackFilterMenu(
      context,
      types: {FeedbackType.problem},
      statuses: {FeedbackStatus.planned},
      onToggleType: (_) {},
      onToggleStatus: (_) {},
      onReset: () {},
    );

    testWidgets('48 px rows, radius 12, a faint edge and no primary dividers', (tester) async {
      final context = await _pump(tester);
      showFeedbackSortMenu(context, selected: FeedbackSort.values.first, onSelected: (_) {});
      await tester.pumpAndSettle();

      for (final row in tester.widgetList(find.byType(CommunityMenuRow))) {
        expect(tester.getSize(find.byWidget(row)).height, 48);
      }
      final frame = tester.widget<Material>(
        find.descendant(of: find.byType(CommunityMenuFrame), matching: find.byType(Material)).first,
      );
      final shape = frame.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(12));
      expect(shape.side.color, isNot(Theme.of(context).colorScheme.primary));
      expect(frame.elevation, greaterThan(0));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    for (final MapEntry(key: name, value: theme) in hostThemes.entries) {
      for (final code in _languages) {
        testWidgets('$name, $code at 320 px: the filter menu fits; titles and statuses read at 4.5:1', (tester) async {
          final context = await _pump(tester, theme: theme, locale: code, size: const Size(320, 568));
          openFilter(context);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final menuContext = tester.element(find.byType(CommunityMenuFrame));
          final background = CommunityMenuFrame.background(menuContext);
          final l = CommunityLocalizations.of(context);
          final header = tester.widget<Text>(find.text(l.filterType));
          expect(RefreshColors.contrast(header.style!.color!, background), greaterThanOrEqualTo(4.5));
          for (final status in FeedbackStatus.values) {
            final label = find.text(feedbackStatusLabel(l, status));
            final color =
                DefaultTextStyle.of(tester.element(label)).style.merge(tester.widget<Text>(label).style).color!;
            expect(RefreshColors.contrast(color, background), greaterThanOrEqualTo(4.5), reason: status.name);
          }
          final reset = find.text(l.resetFilter);
          final resetColor = tester.widget<Text>(reset).style!.color!;
          expect(RefreshColors.contrast(resetColor, background), greaterThanOrEqualTo(4.5));
        });
      }
    }
  });

  group('snackbar', () {
    for (final MapEntry(key: name, value: theme) in hostThemes.entries) {
      for (final code in _languages) {
        testWidgets('$name, $code at 320 px: a long message wraps and reads at 4.5:1', (tester) async {
          final context = await _pump(tester, theme: theme, locale: code, size: const Size(320, 568));
          final l = CommunityLocalizations.of(context);
          final message = '${l.offlineShowingSaved} ${l.deleteCommentKeepsReplies}';
          showCommunitySnackBar(context, message);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
          final text = tester.widget<Text>(find.text(message));
          expect(RefreshColors.contrast(text.style!.color!, snackBar.backgroundColor!), greaterThanOrEqualTo(4.5));
          final box = tester.getRect(find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first);
          expect(box.left, 16);
          expect(320 - box.right, 16);
        });
      }
    }

    testWidgets('bottomClearance lifts it above buttons at the bottom', (tester) async {
      final context = await _pump(tester);
      showCommunitySnackBar(context, 'Saved', bottomClearance: 80);
      await tester.pumpAndSettle();
      expect(tester.widget<SnackBar>(find.byType(SnackBar)).margin, const EdgeInsets.fromLTRB(16, 0, 16, 92));
    });
  });
}
