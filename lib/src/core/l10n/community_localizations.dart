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
    required this.errorStorage,
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
  final String errorStorage;
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
