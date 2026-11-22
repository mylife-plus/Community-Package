import 'package:flutter/material.dart';

import '../../../core/di/community_dependencies.dart';
import '../../../core/l10n/community_localizations.dart';
import '../../../core/navigation/community_navigator.dart';
import '../../../core/theme/refresh_style.dart';
import '../../../core/widgets/community_app_bar.dart';
import '../../../core/widgets/community_link_row.dart';
import '../../../core/widgets/emoji_text.dart';
import '../../privacy/presentation/post_gate.dart';

/// The Community App screen: intro text, links to the community screens and
/// the privacy notice. Links to screens that don't exist yet are left out.
class CommunityHomeScreen extends StatelessWidget {
  const CommunityHomeScreen({super.key, this.postGate});

  /// For tests. Defaults to a gate on the registered identity repository.
  final PostGate? postGate;

  PostGate _gate() =>
      postGate ??
      PostGate(
        identity: CommunityDependencies.identityRepository,
        privacyPolicyUrl: CommunityDependencies.config.privacyPolicyUrl,
      );

  /// The intro sits a little narrower than the rows, so its centred lines
  /// read as a paragraph.
  static const _introInset = 8.0;
  static const _introGap = 24.0;
  static const _privacyBottom = 8.0;
  static const _privacySize = 14.0;

  @override
  Widget build(BuildContext context) => CommunityRefresh(child: Builder(builder: _build));

  Widget _build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final meta = RefreshColors.meta(context, on: theme.scaffoldBackgroundColor);
    return Scaffold(
      appBar: CommunityAppBar(emoji: '❤️', title: l.communityTitle, refreshed: true),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(RefreshTokens.screenPadding),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _introInset),
                    child: Text(l.communityIntro, textAlign: TextAlign.center, style: RefreshTokens.body(context)),
                  ),
                  const SizedBox(height: _introGap),
                  CommunityLinkGroup(
                    rows: [
                      CommunityLinkRow(
                        emoji: '✍️',
                        label: l.allFeedback,
                        onTap: () => CommunityNavigator.openFeedbackList(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: _privacyBottom),
              child: Center(
                child: TextButton(
                  onPressed: () => _gate().openPrivacyNotice(context),
                  style: TextButton.styleFrom(
                    foregroundColor: meta,
                    minimumSize: const Size(64, RefreshTokens.minTarget),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RefreshTokens.controlRadius)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EmojiText('🛡️', size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l.privacyNotice,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: _privacySize,
                            fontWeight: FontWeight.w500,
                            color: meta,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
