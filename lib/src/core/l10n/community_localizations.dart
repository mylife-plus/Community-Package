import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'community_localizations_en.dart';

/// Labels of the community screens, in the host app's language.
///
/// Each language is one subclass. Apps without [delegate] get English.
class CommunityLocalizations {
  const CommunityLocalizations({
    required this.feedbackTitle,
    required this.back,
    required this.statusPlanned,
    required this.statusInProgress,
    required this.statusDone,
    required this.justNow,
    required this.minutesAgo,
    required this.hoursAgo,
    required this.daysAgo,
    required this.monthsAgo,
    required this.yearsAgo,
    required this.costUsd,
    required this.commentCount,
    required this.reactionCount,
    required this.emptyFeedbackTitle,
    required this.emptyFeedbackBody,
    required this.errorOffline,
    required this.errorNetwork,
    required this.errorServer,
    required this.errorGeneric,
    required this.retry,
    required this.loadMoreFailed,
    required this.communityTitle,
    required this.communityIntro,
    required this.allFeedback,
    required this.privacyNotice,
    required this.privacyIntro,
    required this.privacyWhyTitle,
    required this.privacyWhyBody,
    required this.privacyWhatTitle,
    required this.privacyUnlink,
    required this.privacyDelete,
    required this.privacyRetentionTitle,
    required this.privacyRetentionBody,
    required this.privacyRightsTitle,
    required this.privacyRightsBody,
    required this.privacyPolicyBefore,
    required this.privacyPolicyLink,
    required this.privacyPolicyAfter,
    required this.yourId,
    required this.agree,
    required this.decline,
    required this.close,
    required this.rulesTitle,
    required this.ruleNoPrivateInfo,
    required this.ruleNoUnrelated,
    required this.ruleNoHate,
    required this.rulesWarning,
    required this.rulesThanks,
    required this.errorStorage,
    required this.linkFailed,
    required this.newFeedbackTitle,
    required this.chooseTopic,
    required this.typeImprovement,
    required this.typeProblem,
    required this.typeIdea,
    required this.topicHint,
    required this.improvementPrompt,
    required this.ideaPrompt,
    required this.agreeToRules,
    required this.rulesLink,
    required this.cancel,
    required this.submit,
    required this.discardTitle,
    required this.discard,
    required this.keepEditing,
    required this.postedAs,
    required this.errorRateLimited,
    required this.selectScreen,
    required this.stepHint,
    required this.problemDescriptionHint,
    required this.deviceOs,
    required this.deviceApp,
    required this.devicePhone,
    required this.appVersionShort,
    required this.sortTooltip,
    required this.filterTooltip,
    required this.searchTooltip,
    required this.closeSearch,
    required this.sortNewest,
    required this.sortOldest,
    required this.sortReactions,
    required this.sortComments,
    required this.filterType,
    required this.filterProgress,
    required this.resetFilter,
    required this.searchHint,
    required this.noMatchesTitle,
    required this.noMatchesBody,
    required this.clearSearchAndFilter,
    required this.addHeart,
    required this.removeHeart,
    required this.errorTooManyHearts,
    required this.sortReplies,
    required this.filterMine,
    required this.filterAdmin,
    required this.searchCommentsHint,
    required this.feedbackNotFound,
    required this.newCommentHint,
    required this.writeComment,
    required this.sendComment,
    required this.noCommentsTitle,
    required this.noCommentsBody,
    required this.commentDeleted,
    required this.edited,
    required this.showReplies,
    required this.hideReplies,
    required this.reply,
    required this.editComment,
    required this.editCommentTitle,
    required this.save,
    required this.delete,
    required this.keep,
    required this.deleteCommentTitle,
    required this.deleteCommentKeepsReplies,
    required this.commentNotFound,
    required this.errorTooManyComments,
  });

  /// Add to the host app's `localizationsDelegates`.
  static const LocalizationsDelegate<CommunityLocalizations> delegate =
      _CommunityLocalizationsDelegate();

  /// The labels for [context], falling back to English.
  static CommunityLocalizations of(BuildContext context) =>
      Localizations.of<CommunityLocalizations>(context, CommunityLocalizations) ??
      const CommunityLocalizationsEn();

  final String feedbackTitle;
  final String back;
  final String statusPlanned;
  final String statusInProgress;
  final String statusDone;
  final String justNow;
  final String Function(int minutes) minutesAgo;
  final String Function(int hours) hoursAgo;
  final String Function(int days) daysAgo;
  final String Function(int months) monthsAgo;
  final String Function(int years) yearsAgo;

  /// A USD amount, already formatted, for example `50` or `12.50`.
  final String Function(String amount) costUsd;

  /// For screen readers.
  final String Function(int count) commentCount;

  /// For screen readers.
  final String Function(int count) reactionCount;
  final String emptyFeedbackTitle;
  final String emptyFeedbackBody;
  final String errorOffline;
  final String errorNetwork;
  final String errorServer;
  final String errorGeneric;
  final String retry;
  final String loadMoreFailed;

  // Community App screen.
  final String communityTitle;
  final String communityIntro;
  final String allFeedback;

  // Privacy notice. Each heading is bold, followed by its body text.
  final String privacyNotice;
  final String privacyIntro;
  final String privacyWhyTitle;
  final String privacyWhyBody;
  final String privacyWhatTitle;
  final String privacyUnlink;
  final String privacyDelete;
  final String privacyRetentionTitle;
  final String privacyRetentionBody;
  final String privacyRightsTitle;
  final String privacyRightsBody;

  /// "Read our full [privacyPolicyLink] for details.", split around the link.
  final String privacyPolicyBefore;
  final String privacyPolicyLink;
  final String privacyPolicyAfter;

  /// The user's anonymous ID, shown once they agreed.
  final String Function(String id) yourId;
  final String agree;
  final String decline;
  final String close;

  // Community rules.
  final String rulesTitle;
  final String ruleNoPrivateInfo;
  final String ruleNoUnrelated;
  final String ruleNoHate;
  final String rulesWarning;
  final String rulesThanks;

  final String errorStorage;
  final String linkFailed;

  // New Feedback.
  final String newFeedbackTitle;
  final String chooseTopic;
  final String typeImprovement;
  final String typeProblem;
  final String typeIdea;

  /// In the text field while no topic is chosen yet.
  final String topicHint;

  /// In the text field, per chosen topic.
  final String improvementPrompt;
  final String ideaPrompt;

  /// Opens the rules before the user agreed; [rulesLink] after.
  final String agreeToRules;
  final String rulesLink;
  final String cancel;
  final String submit;

  /// Asked when the user leaves the form with text in it.
  final String discardTitle;
  final String discard;
  final String keepEditing;

  /// After submitting, with the new post's number.
  final String Function(int number) postedAs;
  final String errorRateLimited;

  // Problem form.
  /// The screen picker's field before a screen is chosen, and its title.
  final String selectScreen;

  /// In an empty step field, after the step's number.
  final String stepHint;

  /// In the optional "what went wrong" field.
  final String problemDescriptionHint;

  /// Labels of the read-only device boxes.
  final String deviceOs;
  final String deviceApp;
  final String devicePhone;

  /// The app version on a Problem card, for example `App 3.2.0`.
  final String Function(String version) appVersionShort;

  // List toolbar.
  /// Tooltips of the toolbar buttons.
  final String sortTooltip;
  final String filterTooltip;
  final String searchTooltip;
  final String closeSearch;

  /// The sort options.
  final String sortNewest;
  final String sortOldest;
  final String sortReactions;
  final String sortComments;

  /// Group titles in the filter, and the row that clears it.
  final String filterType;
  final String filterProgress;
  final String resetFilter;

  /// In the search field.
  final String searchHint;

  /// When a search or filter finds nothing, with a button that clears both.
  final String noMatchesTitle;
  final String noMatchesBody;
  final String clearSearchAndFilter;

  /// For screen readers, on the heart button.
  final String addHeart;
  final String removeHeart;

  /// When hearts hit the rate limit.
  final String errorTooManyHearts;

  // Feedback detail and comments.
  /// The comment sort option and filters.
  final String sortReplies;
  final String filterMine;
  final String filterAdmin;

  /// In the comment search field.
  final String searchCommentsHint;

  /// The detail screen of feedback that was deleted.
  final String feedbackNotFound;

  /// In the new comment and reply fields.
  final String newCommentHint;

  /// Tooltip of the + that opens the new comment field.
  final String writeComment;

  /// The send button inside a comment field.
  final String sendComment;

  /// A feedback without comments.
  final String noCommentsTitle;
  final String noCommentsBody;

  /// In place of a deleted comment that still has replies.
  final String commentDeleted;

  /// After the age of an edited comment: `3d ago · edited`.
  final String edited;

  /// For screen readers, on the replies chip.
  final String Function(int count) showReplies;
  final String hideReplies;

  /// For screen readers, on the chip of a comment without replies.
  final String reply;

  /// The ✏️ on the user's own comments, and the sheet it opens.
  final String editComment;
  final String editCommentTitle;
  final String save;
  final String delete;
  final String keep;

  /// Asked before deleting a comment, without and with replies.
  final String deleteCommentTitle;
  final String deleteCommentKeepsReplies;
  final String commentNotFound;

  /// When comments hit the rate limit.
  final String errorTooManyComments;
}

class _CommunityLocalizationsDelegate extends LocalizationsDelegate<CommunityLocalizations> {
  const _CommunityLocalizationsDelegate();

  // Every locale is accepted: languages without their own labels get
  // English, so no host locale triggers Flutter's "not supported" warning.
  @override
  bool isSupported(Locale locale) => true;

  // de, es, fr and pt are added with the labels for every M1 screen.
  @override
  Future<CommunityLocalizations> load(Locale locale) =>
      SynchronousFuture(const CommunityLocalizationsEn());

  @override
  bool shouldReload(_CommunityLocalizationsDelegate old) => false;
}
