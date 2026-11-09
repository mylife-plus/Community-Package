import 'package:freezed_annotation/freezed_annotation.dart';

import 'feedback_comment.dart';

part 'comment_query.freezed.dart';

/// The orders top-level comments can be sorted in. Replies are always
/// oldest first.
enum CommentSort { newest, oldest, replies }

/// Which comments a filter keeps: the user's own, or the admin's.
enum CommentFilter { mine, admin }

/// What a feedback's comment list shows: its sort, filters and search text.
@freezed
abstract class CommentQuery with _$CommentQuery {
  const CommentQuery._();

  const factory CommentQuery({
    @Default(CommentSort.newest) CommentSort sort,

    /// Empty means every comment.
    @Default(<CommentFilter>{}) Set<CommentFilter> filters,

    /// Trimmed. Empty means no search.
    @Default('') String search,
  }) = _CommentQuery;

  /// Newest first, no filter, no search: the list as it opens.
  bool get isDefault => this == const CommentQuery();

  bool get hasFilter => filters.isNotEmpty;

  /// A filter or search narrows the list; threads it keeps because of a
  /// reply open by themselves.
  bool get narrows => filters.isNotEmpty || search.isNotEmpty;

  /// The request's query parameters, in a fixed order, so the same query
  /// always makes the same request.
  Map<String, String?> toQueryParameters() => {
    if (sort != CommentSort.newest) 'sort': sort.name,
    if (filters.isNotEmpty)
      'filter': CommentFilter.values.where(filters.contains).map((f) => f.name).join(','),
    if (search.isNotEmpty) 'q': search,
  };
}

/// Every page of a feedback's comments for [query], as published on the
/// comment stream.
class CommentList {
  const CommentList(this.number, this.query, this.page);

  /// The feedback's number.
  final int number;
  final CommentQuery query;
  final CommentPage page;
}
