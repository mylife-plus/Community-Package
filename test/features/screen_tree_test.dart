import 'package:community_package/community_package.dart';
import 'package:community_package/src/core/utils/formatters.dart';
import 'package:community_package/src/features/new_feedback/domain/screen_tree.dart';
import 'package:flutter_test/flutter_test.dart';

const _host = [
  ScreenNode(
    'Inventory',
    children: [
      ScreenNode('New Item'),
      ScreenNode('Sell Items', children: [ScreenNode('Add Items')]),
    ],
  ),
  ScreenNode('Settings'),
];

void main() {
  test('flattens the tree parents first, keeping the order', () {
    final rows = flattenScreens(_host);

    expect([for (final r in rows) r.savedPath], [
      'Inventory',
      'Inventory > New Item',
      'Inventory > Sell Items',
      'Inventory > Sell Items > Add Items',
      'Settings',
    ]);
    expect([for (final r in rows) r.depth], [0, 1, 1, 2, 0]);
    expect(rows[3].name, 'Add Items');
  });

  test("the picker adds the package's own screens after the host's", () {
    final rows = pickerScreens(_host);

    expect(rows.take(5), flattenScreens(_host));
    expect([for (final r in rows.skip(5)) r.savedPath], [
      'Community',
      'Community > Community App',
      'Community > All Feedback',
      'Community > Feedback Detail',
      'Community > New Feedback',
    ]);
  });

  test('the picker is empty when the host gave no screens', () {
    expect(pickerScreens(const []), isEmpty);
  });

  test('two choices with the same path are equal', () {
    expect(
      const ScreenChoice(path: ['Inventory', 'New Item']),
      const ScreenChoice(path: ['Inventory', 'New Item']),
    );
  });

  test('a saved path is shown with arrows', () {
    expect(formatScreenPath('Inventory > Sell Items > Add Items'), 'Inventory → Sell Items → Add Items');
    expect(formatScreenNames(['Inventory', 'Sell Items']), 'Inventory → Sell Items');
  });
}
