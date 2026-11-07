/// A feedback item as the backend sends it.
Map<String, dynamic> feedbackJson(
  int number, {
  String? status,
  String type = 'idea',
  int reactionCount = 0,
  bool reacted = false,
}) => {
  'number': number,
  'type': type,
  'text': 'Feedback $number',
  'lang': 'en',
  'status': status,
  'costCents': null,
  'githubUrl': null,
  'screenPath': null,
  'steps': null,
  'description': null,
  'osVersion': null,
  'appVersion': null,
  'deviceModel': null,
  'reactionCount': reactionCount,
  'commentCount': 0,
  'reacted': reacted,
  'isMine': false,
  'createdAt': '2026-11-0${number % 9 + 1}T10:00:00.000Z',
  'updatedAt': '2026-11-0${number % 9 + 1}T10:00:00.000Z',
};

/// A list page as the backend sends it.
Map<String, dynamic> pageJson(List<int> numbers, {String? nextCursor}) => {
  'items': [for (final n in numbers) feedbackJson(n)],
  'nextCursor': nextCursor,
};
