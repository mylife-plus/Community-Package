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
    required this.errorRateLimited,
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
  final String errorRateLimited;
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
