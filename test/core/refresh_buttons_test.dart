import 'package:community_package/src/core/theme/refresh_style.dart';
import 'package:community_package/src/core/widgets/refresh_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/host_themes.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in hostThemes.entries) {
    testWidgets('$name: a red button label reads at 4.5:1 on its tonal background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: RefreshButton(label: 'delete', kind: RefreshButtonKind.destructive, onPressed: () {}),
            ),
          ),
        ),
      );
      final label = tester.element(find.text('Delete'));
      final color = DefaultTextStyle.of(label).style.color!;
      expect(RefreshColors.contrast(color, RefreshColors.errorTonal(label)), greaterThanOrEqualTo(4.5));
    });
  }
}
