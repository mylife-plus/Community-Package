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
        privacyNotice: 'Privacy Notice',
        privacyIntro:
            'When you submit your first feedback, we generate one unique identifier (UUID) '
            'that is securely stored on your device.',
        privacyWhyTitle: 'Why we do this:',
        privacyWhyBody:
            'To link your feedback and comments to you, so you can identify and manage your '
            'own submissions. (Legal basis: legitimate interest – Art. 6(1)(f) GDPR)',
        privacyWhatTitle: 'What you can do:',
        privacyUnlink:
            'Unlink – Remove your UUID from all your feedback and comments. The content is '
            'kept but can no longer be traced back to you.',
        privacyDelete:
            "Delete – Remove your feedback entirely. Exception: feedback marked with '💪' by "
            'our team cannot be deleted.',
        privacyRetentionTitle: 'Retention:',
        privacyRetentionBody:
            'Your UUID persists on your device across app reinstalls. Feedback content is '
            "retained until you delete or unlink it. Feedback marked with '💪' is retained "
            'permanently.',
        privacyRightsTitle: 'Your rights:',
        privacyRightsBody:
            'You can access, rectify, restrict, or object to processing at any time. You may '
            'also lodge a complaint with your local data protection authority (e.g., the '
            'Bundesdatenschutzbeauftragte).',
        privacyPolicyBefore: 'Read our full ',
        privacyPolicyLink: 'Privacy Policy',
        privacyPolicyAfter: ' for details.',
        yourId: _yourId,
        agree: 'agree',
        decline: 'decline',
        close: 'close',
        rulesTitle: 'Do Not',
        ruleNoPrivateInfo: 'Share private information',
        ruleNoUnrelated: 'Submit unrelated content',
        ruleNoHate: 'Use harassment or hate speech',
        rulesWarning: 'Violations may result in deletion of feedback or account restrictions.',
        rulesThanks: 'Thank you',
        errorStorage: 'Could not save on this device. Please try again.',
        linkFailed: 'Could not open the link.',
      );

  static String _minutesAgo(int n) => '${n}m ago';
  static String _hoursAgo(int n) => '${n}h ago';
  static String _daysAgo(int n) => '${n}d ago';
  static String _monthsAgo(int n) => '${n}mo ago';
  static String _yearsAgo(int n) => '${n}y ago';
  static String _costUsd(String amount) => '$amount \$';
  static String _commentCount(int n) => n == 1 ? '1 comment' : '$n comments';
  static String _reactionCount(int n) => n == 1 ? '1 heart' : '$n hearts';
  static String _yourId(String id) => 'Your ID: $id';
}
