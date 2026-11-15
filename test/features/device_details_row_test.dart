import 'package:community_package/community_package.dart';
import 'package:community_package/src/core/identity/device_details.dart';
import 'package:community_package/src/features/new_feedback/presentation/problem_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The test font draws every glyph 1 em wide, so a 20 px value needs 20 px
  // per character. 353 is the form width on a 375 px phone.
  Future<void> pumpRow(WidgetTester tester, DeviceDetails details, {double textScale = 1}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          CommunityLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Material(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 353, child: DeviceDetailsRow(details: details)),
            ),
          ),
        ),
      ),
    );
  }

  double top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text)).dy;

  testWidgets('short values stay on one row in Figma\'s widths', (tester) async {
    await pumpRow(tester, const DeviceDetails(osVersion: '1', appVersion: '2', deviceModel: 'P'));

    expect(top(tester, '2'), top(tester, '1'));
    expect(top(tester, 'P'), top(tester, '1'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long phone name moves to its own line at full size', (tester) async {
    const phone = 'iPhone SE (2nd generation)';
    await pumpRow(tester, const DeviceDetails(osVersion: '1', appVersion: '2', deviceModel: phone));

    expect(top(tester, '2'), top(tester, '1'));
    expect(top(tester, phone), greaterThan(top(tester, '1')));
    // Not shrunk: as high as the other values, and as wide as the form.
    expect(tester.getSize(find.text(phone)).height, tester.getSize(find.text('1')).height);
    expect(tester.getSize(find.byType(DeviceDetailsRow)).width, 353);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with very large text every box gets its own line', (tester) async {
    await pumpRow(
      tester,
      const DeviceDetails(osVersion: 'iOS 27.0', appVersion: '1.0.0', deviceModel: 'iPhone 18 Pro'),
      textScale: 3,
    );

    expect(top(tester, '1.0.0'), greaterThan(top(tester, 'iOS 27.0')));
    expect(top(tester, 'iPhone 18 Pro'), greaterThan(top(tester, '1.0.0')));
    expect(tester.takeException(), isNull);
  });
}
