import '../../data/models/feedback_item.dart';
import '../../data/models/feedback_query.dart';
import '../errors/app_error.dart';
import '../l10n/community_localizations.dart';

/// Short age such as `3d ago`, from [time] to [now].
String formatAge(CommunityLocalizations l, DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return l.justNow;
  if (diff.inHours < 1) return l.minutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l.hoursAgo(diff.inHours);
  if (diff.inDays < 60) return l.daysAgo(diff.inDays);
  if (diff.inDays < 365) return l.monthsAgo(diff.inDays ~/ 30);
  return l.yearsAgo(diff.inDays ~/ 365);
}

/// USD amount from cents: `50` for whole dollars, `12.50` otherwise.
String formatUsd(CommunityLocalizations l, int cents) {
  final dollars = cents ~/ 100;
  final rest = cents % 100;
  final amount = rest == 0 ? '$dollars' : '$dollars.${rest.toString().padLeft(2, '0')}';
  return l.costUsd(amount);
}

/// The message the user sees for [error].
String errorMessage(CommunityLocalizations l, AppError error) {
  switch (error.type) {
    case AppErrorType.offline:
      return l.errorOffline;
    case AppErrorType.network:
      return l.errorNetwork;
    case AppErrorType.server:
      return l.errorServer;
    case AppErrorType.storage:
      return l.errorStorage;
    case AppErrorType.rateLimited:
      return l.errorRateLimited;
    case AppErrorType.badRequest:
    case AppErrorType.unauthorized:
    case AppErrorType.blocked:
    case AppErrorType.notFound:
      return l.errorGeneric;
  }
}

/// The name of [type], for example `Improvement`.
String feedbackTypeLabel(CommunityLocalizations l, FeedbackType type) {
  switch (type) {
    case FeedbackType.improvement:
      return l.typeImprovement;
    case FeedbackType.problem:
      return l.typeProblem;
    case FeedbackType.idea:
      return l.typeIdea;
  }
}

/// The name of [status], for example `in progress`.
String feedbackStatusLabel(CommunityLocalizations l, FeedbackStatus status) {
  switch (status) {
    case FeedbackStatus.planned:
      return l.statusPlanned;
    case FeedbackStatus.inProgress:
      return l.statusInProgress;
    case FeedbackStatus.done:
      return l.statusDone;
  }
}

/// The name of a sort option, for example `Most hearts`.
String feedbackSortLabel(CommunityLocalizations l, FeedbackSort sort) {
  switch (sort) {
    case FeedbackSort.newest:
      return l.sortNewest;
    case FeedbackSort.oldest:
      return l.sortOldest;
    case FeedbackSort.reactions:
      return l.sortReactions;
    case FeedbackSort.comments:
      return l.sortComments;
  }
}

/// Between the names of a saved screen path:
/// `Inventory > Sell Items > Add Items`.
const screenPathSeparator = ' > ';

/// A saved screen path as shown: `Inventory → Sell Items → Add Items`.
String formatScreenPath(String saved) => saved.split(screenPathSeparator).join(' → ');

/// Path names, as shown: `Inventory → Sell Items`.
String formatScreenNames(List<String> names) => names.join(' → ');
