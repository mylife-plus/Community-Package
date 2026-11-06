import 'package:flutter/material.dart';

import '../../../core/di/community_dependencies.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/l10n/community_localizations.dart';
import '../../../core/navigation/community_navigator.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/community_app_bar.dart';
import '../../../core/widgets/community_form_actions.dart';
import '../../../core/widgets/community_popups.dart';
import '../../../core/widgets/community_text_field.dart';
import '../../../core/widgets/controller_scope.dart';
import '../../../core/widgets/feedback_type_picker.dart';
import '../../../data/models/feedback_item.dart';
import '../../privacy/presentation/post_gate.dart';
import 'new_feedback_controller.dart';

/// New Feedback: choose a topic, write the text, submit.
class NewFeedbackScreen extends StatelessWidget {
  const NewFeedbackScreen({super.key, this.createController, this.postGate});

  /// For tests. Default to the registered repositories.
  final NewFeedbackController Function()? createController;
  final PostGate? postGate;

  @override
  Widget build(BuildContext context) {
    return ControllerScope<NewFeedbackController>(
      create:
          createController ??
          () => NewFeedbackController(
            CommunityDependencies.feedbackRepository,
            CommunityDependencies.identityRepository,
          ),
      builder: (controller) => _Form(
        controller: controller,
        gate:
            postGate ??
            PostGate(
              identity: CommunityDependencies.identityRepository,
              privacyPolicyUrl: CommunityDependencies.config.privacyPolicyUrl,
              snackBarClearance: CommunityFormActions.snackBarClearance(context),
            ),
      ),
    );
  }
}

// Gaps between the form's parts, from the Figma export. The rules link's
// 48 px tap area adds about 14 px above its text, so Figma's 33 px is 19.
const _pillTop = 16.0;
const _pillToField = 37.0;
const _fieldToRules = 19.0;

class _Form extends StatelessWidget {
  const _Form({required this.controller, required this.gate});

  final NewFeedbackController controller;
  final PostGate gate;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final submitting = controller.submitting;

    return PopScope(
      // Typed text or a running submit: system back asks first or waits.
      canPop: !controller.hasText && !submitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context);
      },
      child: Scaffold(
        appBar: CommunityAppBar(
          emoji: '✍️',
          title: l.newFeedbackTitle,
          onBack: () => _leave(context),
        ),
        body: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: CommunityTokens.actionsBottomGap),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        CommunityTokens.formPadding,
                        _pillTop,
                        CommunityTokens.formPadding,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Hidden under the open list, which takes its place.
                          Visibility.maintain(
                            visible: !controller.menuOpen,
                            child: Center(
                              child: FeedbackTypePill(
                                type: controller.type,
                                onTap: submitting ? null : controller.openMenu,
                              ),
                            ),
                          ),
                          const SizedBox(height: _pillToField),
                          CommunityTextField(
                            controller: controller.textController,
                            hint: _hint(l, controller.type),
                            maxLength: NewFeedbackController.maxTextLength,
                            enabled: !submitting,
                          ),
                          const SizedBox(height: _fieldToRules),
                          Center(
                            child: _RulesLink(
                              agreed: controller.rulesAgreed,
                              onTap: () => gate.openRules(context),
                            ),
                          ),
                          // Similar feedback (S9) goes here.
                        ],
                      ),
                    ),
                    if (controller.menuOpen) ...[
                      // Tapping anywhere else closes the list.
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: controller.closeMenu,
                        ),
                      ),
                      Positioned(
                        top: _pillTop,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FeedbackTypeMenu(
                            types: NewFeedbackController.types,
                            onSelected: controller.chooseType,
                            onClose: controller.closeMenu,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              CommunityFormActions(
                cancelLabel: l.cancel,
                submitLabel: l.submit,
                onCancel: submitting ? null : () => _leave(context),
                onSubmit: controller.canSubmit ? () => _submit(context) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _hint(CommunityLocalizations l, FeedbackType? type) {
    switch (type) {
      case null:
        return l.topicHint;
      case FeedbackType.improvement:
        return l.improvementPrompt;
      case FeedbackType.idea:
        return l.ideaPrompt;
      case FeedbackType.problem:
        // The problem form (S4) has its own fields.
        return l.topicHint;
    }
  }

  /// Back arrow, ✗ and system back: asks before typed text is lost.
  Future<void> _leave(BuildContext context) async {
    if (controller.submitting) return;
    if (controller.hasText) {
      final l = CommunityLocalizations.of(context);
      final discard = await showCommunityConfirm(
        context,
        title: l.discardTitle,
        confirmLabel: l.discard,
        cancelLabel: l.keepEditing,
      );
      if (!discard || !context.mounted) return;
    }
    CommunityNavigator.back(context);
  }

  Future<void> _submit(BuildContext context) async {
    if (!controller.beginSubmit()) return;
    FocusScope.of(context).unfocus();
    final l = CommunityLocalizations.of(context);
    if (!await gate.ensureCanPost(context) || !context.mounted) {
      controller.cancelSubmit();
      return;
    }
    try {
      final item = await runWithLoading(context, controller.send);
      if (!context.mounted) return;
      showCommunitySnackBar(context, l.postedAs(item.number));
      CommunityNavigator.showFeedbackListAfterPost(context);
    } on AppError catch (e) {
      if (!context.mounted) return;
      showCommunitySnackBar(
        context,
        errorMessage(l, e),
        bottomClearance: CommunityFormActions.snackBarClearance(context),
      );
    }
  }
}

/// "agree to Rules" in red until the user agreed, then a quiet "Rules"
/// link to read them again.
class _RulesLink extends StatelessWidget {
  const _RulesLink({required this.agreed, required this.onTap});

  final bool agreed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = CommunityLocalizations.of(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: agreed ? CommunityColors.muted(context) : theme.colorScheme.error,
        textStyle: theme.textTheme.titleSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(agreed ? l.rulesLink : l.agreeToRules),
    );
  }
}
