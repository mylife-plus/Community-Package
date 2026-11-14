import 'package:flutter/material.dart';

import '../../../core/di/community_dependencies.dart';
import '../../../core/l10n/community_localizations.dart';
import '../../../core/navigation/community_navigator.dart';
import '../../../core/theme/community_tokens.dart';
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

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Scaffold(
      appBar: CommunityAppBar(emoji: '❤️', title: l.communityTitle),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                // The intro's top is 38.5 below the title's centre.
                padding: const EdgeInsets.fromLTRB(
                  CommunityTokens.screenPadding,
                  16.5,
                  CommunityTokens.screenPadding,
                  16,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 29),
                    child: Text(
                      l.communityIntro,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 21),
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
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: InkWell(
                  onTap: () => _gate().openPrivacyNotice(context),
                  borderRadius: BorderRadius.circular(CommunityTokens.buttonRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmojiText('🛡️', size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l.privacyNotice,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color: CommunityColors.muted(context),
                            ),
                          ),
                        ),
                      ],
                    ),
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
