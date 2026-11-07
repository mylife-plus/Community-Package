import 'package:freezed_annotation/freezed_annotation.dart';

import 'feedback_item.dart';

part 'feedback_query.freezed.dart';

/// The orders a feedback list can be sorted in.
enum FeedbackSort { newest, oldest, reactions, comments }

/// What a feedback list shows: its sort, filters and search text.
@freezed
abstract class FeedbackQuery with _$FeedbackQuery {
  const FeedbackQuery._();

  const factory FeedbackQuery({
    @Default(FeedbackSort.newest) FeedbackSort sort,

    /// Empty means every type.
    @Default(<FeedbackType>{}) Set<FeedbackType> types,

    /// Empty means any status, including none.
    @Default(<FeedbackStatus>{}) Set<FeedbackStatus> statuses,

    /// Trimmed. Empty means no search.
    @Default('') String search,
  }) = _FeedbackQuery;

  /// Newest first, no filter, no search: the list as it opens.
  bool get isDefault => this == const FeedbackQuery();

  bool get hasFilter => types.isNotEmpty || statuses.isNotEmpty;

  /// The list request's query parameters. Values in a fixed order, so the
  /// same query always makes the same request.
  Map<String, String?> toQueryParameters() => {
    if (sort != FeedbackSort.newest) 'sort': sort.name,
    if (types.isNotEmpty)
      'type': FeedbackType.values.where(types.contains).map((t) => t.name).join(','),
    if (statuses.isNotEmpty)
      'status': FeedbackStatus.values.where(statuses.contains).map(_statusParam).join(','),
    if (search.isNotEmpty) 'q': search,
  };

  static String _statusParam(FeedbackStatus status) => switch (status) {
    FeedbackStatus.planned => 'planned',
    FeedbackStatus.inProgress => 'in_progress',
    FeedbackStatus.done => 'done',
  };
}

/// Every page of [query] loaded so far, as published on the list stream.
class FeedbackList {
  const FeedbackList(this.query, this.page);

  final FeedbackQuery query;
  final FeedbackPage page;
}
