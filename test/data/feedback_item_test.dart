import 'package:community_package/src/data/models/feedback_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/feedback_json.dart';

void main() {
  test('reads a Problem as the backend sends it', () {
    final item = FeedbackItem.fromJson({
      ...feedbackJson(21, type: 'problem', status: 'in_progress'),
      'costCents': 5000,
      'screenPath': 'Inventory > Sell Item > Add Item',
      'steps': ['Tap plus', 'Add an item'],
      'osVersion': 'iOS 18.1',
      'appVersion': '1.0.0',
      'deviceModel': 'iPhone 15 Pro',
      'reactionCount': 5,
      'commentCount': 1,
    });

    expect(item.number, 21);
    expect(item.type, FeedbackType.problem);
    expect(item.status, FeedbackStatus.inProgress);
    expect(item.costCents, 5000);
    expect(item.steps, ['Tap plus', 'Add an item']);
    expect(item.deviceModel, 'iPhone 15 Pro');
    expect(item.reactionCount, 5);
    expect(item.createdAt, DateTime.utc(2026, 11, 4, 10));
  });

  test('an unknown status reads as no status', () {
    final item = FeedbackItem.fromJson(feedbackJson(1, status: 'archived'));

    expect(item.status, isNull);
  });

  test('a page survives a round trip through JSON', () {
    final page = FeedbackPage.fromJson(pageJson([3, 2, 1], nextCursor: 'abc'));

    expect(FeedbackPage.fromJson(page.toJson()), page);
    expect(page.items.map((i) => i.number), [3, 2, 1]);
  });
}
