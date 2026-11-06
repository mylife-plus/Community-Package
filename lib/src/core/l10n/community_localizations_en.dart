import 'community_localizations.dart';

class CommunityLocalizationsEn extends CommunityLocalizations {
  const CommunityLocalizationsEn()
    : super(
        feedbackTitle: 'Feedback',
        back: 'Back',
        statusPlanned: 'planned',
        statusInProgress: 'in progress',
        statusDone: 'done',
        justNow: 'just now',
        minutesAgo: _minutesAgo,
        hoursAgo: _hoursAgo,
        daysAgo: _daysAgo,
        monthsAgo: _monthsAgo,
        yearsAgo: _yearsAgo,
        costUsd: _costUsd,
        commentCount: _commentCount,
        reactionCount: _reactionCount,
        emptyFeedbackTitle: 'No feedback yet',
        emptyFeedbackBody: 'Ideas, improvements and problems from the community will show up here.',
        errorOffline: 'No internet connection. Check your connection and try again.',
        errorNetwork: 'The connection was interrupted. Please try again.',
        errorServer: 'Something went wrong on our side. Please try again later.',
        errorGeneric: 'Something went wrong. Please try again.',
        retry: 'Try again',
        loadMoreFailed: 'Could not load more feedback.',
        errorStorage: 'Could not save on this device. Please try again.',
      );

  static String _minutesAgo(int n) => '${n}m ago';
  static String _hoursAgo(int n) => '${n}h ago';
  static String _daysAgo(int n) => '${n}d ago';
  static String _monthsAgo(int n) => '${n}mo ago';
  static String _yearsAgo(int n) => '${n}y ago';
  static String _costUsd(String amount) => '$amount \$';
  static String _commentCount(int n) => n == 1 ? '1 comment' : '$n comments';
  static String _reactionCount(int n) => n == 1 ? '1 heart' : '$n hearts';
}
