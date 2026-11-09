import 'package:community_package/src/core/widgets/community_offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBanner(WidgetTester tester, {required String message, required String action}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityOfflineBanner(
              visible: true,
              message: message,
              actionLabel: action,
              onAction: () {},
            ),
          ),
        ),
      );

  final text = find.textContaining('📡', findRichText: true);

  testWidgets('the text starts on the left and the button sits on the right', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpBanner(tester, message: 'Hors ligne. Feedback enregistré affiché.', action: 'Réessayer');

    expect(tester.getTopLeft(text).dx, lessThan(20));
    final button = find.byType(TextButton);
    expect(tester.getTopRight(button).dx, greaterThan(370));
    // Side by side, not stacked.
    expect(tester.getTopLeft(button).dx, greaterThan(tester.getTopLeft(text).dx));
    expect(tester.getCenter(button).dy, closeTo(tester.getCenter(text).dy, 12));
  });

  testWidgets('long labels at 320 px wrap without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpBanner(tester, message: 'Offline. Gespeichertes Feedback wird angezeigt.', action: 'Erneut versuchen');

    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(text).dx, lessThan(20));
  });

  testWidgets('hidden, it takes no space', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CommunityOfflineBanner(visible: false, message: 'x', actionLabel: 'y', onAction: () {}),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(CommunityOfflineBanner)).height, 0);
  });
}
