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
        errorTooLong: _errorTooLong,
        retry: 'Try again',
        loadMoreFailed: 'Could not load more feedback.',
        communityTitle: 'Community App',
        communityIntro:
            'This app is a 100% open source and community driven project. '
            'We try to be as transparent as possible with everything going on.',
        allFeedback: 'all Feedback',
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
        newFeedbackTitle: 'new Feedback',
        chooseTopic: 'Choose Topic',
        typeImprovement: 'Improvement',
        typeProblem: 'Problem',
        typeIdea: 'Idea',
        topicHint: 'Your improvement idea...',
        improvementPrompt: 'What do you want to improve?',
        ideaPrompt: "What's your idea?",
        agreeToRules: 'agree to Rules',
        rulesLink: 'Rules',
        cancel: 'cancel',
        submit: 'submit',
        discardTitle: 'Discard this feedback?',
        discard: 'discard',
        keepEditing: 'keep editing',
        postedAs: _postedAs,
        errorRateLimited: 'Too many posts. Try again soon.',
        selectScreen: 'select a screen',
        stepHint: 'Step to reproduce the Problem',
        problemDescriptionHint: 'What went wrong?',
        deviceOs: 'OS',
        deviceApp: 'App',
        devicePhone: 'Phone',
        appVersionShort: _appVersionShort,
        sortTooltip: 'Sort',
        filterTooltip: 'Filter',
        searchTooltip: 'Search',
        closeSearch: 'Close search',
        sortNewest: 'Newest',
        sortOldest: 'Oldest',
        sortReactions: 'Most hearts',
        sortComments: 'Most comments',
        filterType: 'Type',
        filterProgress: 'Progress',
        resetFilter: 'reset',
        searchHint: 'Search feedback',
        noMatchesTitle: 'Nothing found',
        noMatchesBody: 'Try other words or filters.',
        clearSearchAndFilter: 'clear',
        addHeart: 'Add a heart',
        removeHeart: 'Remove your heart',
        errorTooManyHearts: 'Too many hearts. Try again soon.',
        sortReplies: 'Most replies',
        filterMine: 'Mine',
        filterAdmin: 'Admin',
        searchCommentsHint: 'Search comments',
        feedbackNotFound: 'This feedback no longer exists.',
        newCommentHint: 'new Comment...',
        writeComment: 'Write a comment',
        sendComment: 'Send',
        noCommentsTitle: 'No comments yet',
        noCommentsBody: 'Be the first to comment.',
        commentDeleted: 'Comment deleted',
        edited: 'edited',
        showReplies: _showReplies,
        hideReplies: 'Hide replies',
        reply: 'Reply',
        editComment: 'Edit comment',
        editCommentTitle: 'edit Comment',
        save: 'save',
        delete: 'delete',
        keep: 'keep',
        deleteCommentTitle: 'Delete this comment?',
        deleteCommentKeepsReplies: 'Delete this comment? Its replies stay.',
        commentNotFound: 'This comment no longer exists.',
        errorTooManyComments: 'Too many comments. Try again soon.',
        offlineShowingSaved: 'Offline. Showing saved feedback.',
        loadMoreCommentsFailed: 'Could not load more comments.',
        screenCommunity: 'Community',
        screenAllFeedback: 'All Feedback',
        screenFeedbackDetail: 'Feedback Detail',
        screenNewFeedback: 'New Feedback',
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
  static String _postedAs(int n) => 'Thanks! Posted as #$n';
  static String _errorTooLong(int max) => 'Too long. Use at most $max characters.';
  static String _appVersionShort(String version) => 'App $version';
  static String _showReplies(int n) => n == 1 ? 'Show 1 reply' : 'Show $n replies';
}
