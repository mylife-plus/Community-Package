/// A feedback item as the backend sends it.
Map<String, dynamic> feedbackJson(
  int number, {
  String? status,
  String type = 'idea',
  int reactionCount = 0,
  bool reacted = false,
  int commentCount = 0,
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
  'commentCount': commentCount,
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

/// A comment as the backend sends it. Replies are passed as JSON too.
Map<String, dynamic> commentJson(
  int id, {
  int? parentId,
  String? text,
  bool isMine = false,
  bool isAdmin = false,
  bool deleted = false,
  bool edited = false,
  List<Map<String, dynamic>> replies = const [],
  int day = 1,
}) => {
  'id': id,
  'parentId': parentId,
  'text': deleted ? '' : (text ?? 'Comment $id'),
  'lang': 'en',
  'isAdmin': isAdmin,
  'isMine': isMine && !deleted,
  'deleted': deleted,
  'edited': edited,
  'createdAt': '2026-11-0${day}T10:00:00.000Z',
  'updatedAt': '2026-11-0${day}T10:00:00.000Z',
  'replyCount': replies.length,
  'replies': replies,
};

/// A page of comments as the backend sends it.
Map<String, dynamic> commentPageJson(List<Map<String, dynamic>> comments, {String? nextCursor}) => {
  'items': comments,
  'nextCursor': nextCursor,
};
