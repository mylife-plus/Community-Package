import 'package:flutter/widgets.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/l10n/community_localizations.dart';
import '../../../core/navigation/community_navigator.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/community_popups.dart';
import '../../../data/models/identity.dart';
import '../../../data/repositories/identity_repository.dart';
import 'privacy_notice_sheet.dart';
import 'rules_sheet.dart';

/// Asks for what an action needs before it runs: the privacy notice before
/// anything is posted or hearted, and the rules before the first feedback
/// or comment. Each is asked until the user agrees, then never again.
class PostGate {
  const PostGate({required this.identity, this.privacyPolicyUrl, this.snackBarClearance = 0});

  final IdentityRepository identity;

  /// Linked from the privacy notice when set.
  final String? privacyPolicyUrl;

  /// Lifts error messages above buttons at the bottom of the screen that
  /// uses this gate. See [showCommunitySnackBar].
  final double snackBarClearance;

  /// Before a heart. True when the action may go ahead.
  Future<bool> ensureIdentity(BuildContext context) async {
    if ((await _current()).agreedToPrivacy) return true;
    if (!context.mounted) return false;
    final agreed = await _askPrivacy(context);
    if (!agreed || !context.mounted) return false;
    return _agreeToPrivacy(context);
  }

  /// Before posting feedback or a comment. True when the action may go ahead.
  Future<bool> ensureCanPost(BuildContext context) async {
    if (!await ensureIdentity(context)) return false;
    if ((await _current()).rulesAgreed) return true;
    if (!context.mounted) return false;
    return _askRules(context);
  }

  /// The rules link on the forms: asks when the user has not agreed yet,
  /// otherwise shows the rules with a close button.
  Future<void> openRules(BuildContext context) async {
    final agreed = (await _current()).rulesAgreed;
    if (!context.mounted) return;
    if (!agreed) {
      await _askRules(context);
      return;
    }
    await showCommunitySheet<void>(context, builder: (_) => const RulesSheet(agreed: true));
  }

  Future<bool> _askRules(BuildContext context) async {
    final agreed = await showCommunitySheet<bool>(context, builder: (_) => const RulesSheet());
    if (agreed != true || !context.mounted) return false;
    try {
      await identity.agreeToRules();
      return true;
    } on AppError catch (e) {
      if (context.mounted) _showError(context, e);
      return false;
    }
  }

  /// The notice from the Community App screen: asks when the user has not
  /// agreed yet, otherwise shows it with their ID.
  Future<void> openPrivacyNotice(BuildContext context) async {
    final anonId = (await _current()).anonId;
    if (!context.mounted) return;
    if (anonId == null) {
      await ensureIdentity(context);
      return;
    }
    await showCommunitySheet<void>(
      context,
      builder: (_) => PrivacyNoticeSheet(anonId: anonId, onOpenPrivacyPolicy: _policyOpener(context)),
    );
  }

  Future<bool> _askPrivacy(BuildContext context) async {
    final agreed = await showCommunitySheet<bool>(
      context,
      builder: (_) => PrivacyNoticeSheet(onOpenPrivacyPolicy: _policyOpener(context)),
    );
    return agreed == true;
  }

  Future<bool> _agreeToPrivacy(BuildContext context) async {
    try {
      await identity.agreeToPrivacy();
      return true;
    } on AppError catch (e) {
      if (context.mounted) _showError(context, e);
      return false;
    }
  }

  /// A failed read counts as "not agreed yet": agreeing reads again and
  /// keeps an ID that already exists.
  Future<Identity> _current() async {
    try {
      return await identity.load();
    } on AppError {
      return const Identity();
    }
  }

  VoidCallback? _policyOpener(BuildContext context) {
    final url = privacyPolicyUrl;
    if (url == null || url.trim().isEmpty) return null;
    return () => CommunityNavigator.openExternalUrl(context, url);
  }

  void _showError(BuildContext context, AppError error) {
    showCommunitySnackBar(
      context,
      errorMessage(CommunityLocalizations.of(context), error),
      bottomClearance: snackBarClearance,
    );
  }
}
