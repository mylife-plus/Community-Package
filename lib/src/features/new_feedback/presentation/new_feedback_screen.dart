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
import '../../../core/widgets/emoji_text.dart';
import '../../../core/widgets/feedback_type_picker.dart';
import '../../../data/models/feedback_item.dart';
import '../../privacy/presentation/post_gate.dart';
import '../domain/screen_tree.dart';
import 'new_feedback_controller.dart';
import 'problem_fields.dart';
import 'screen_picker_sheet.dart';

/// New Feedback: choose a topic, write the text (or, for a Problem, pick
/// the screen and list the steps), submit.
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
            screens: CommunityDependencies.config.screens,
            deviceDetails: CommunityDependencies.deviceDetails,
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
      // Any input or a running submit: system back asks first or waits.
      canPop: !controller.hasInput && !submitting,
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
                          if (controller.type == FeedbackType.problem)
                            ..._problemFields(context, l)
                          else
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

  /// The optional description, screen, steps and the device details.
  List<Widget> _problemFields(BuildContext context, CommunityLocalizations l) {
    final submitting = controller.submitting;
    const gap = SizedBox(height: CommunityTokens.problemFieldGap);
    final steps = controller.steps;
    return [
      if (NewFeedbackController.askProblemDescription) ...[
        CommunityTextField(
          controller: controller.descriptionController,
          hint: l.problemDescriptionHint,
          maxLength: NewFeedbackController.maxTextLength,
          enabled: !submitting,
          leading: const EmojiText('⚠️', size: 20),
        ),
        gap,
      ],
      if (controller.asksScreen) ...[
        ScreenPickerField(
          screen: controller.screen,
          onTap: submitting ? null : () => _pickScreen(context),
        ),
        gap,
      ],
      for (var i = 0; i < steps.length; i++) ...[
        if (i > 0) gap,
        ProblemStepField(
          key: ValueKey(steps[i].id),
          number: i + 1,
          initialText: steps[i].text,
          enabled: !submitting,
          onChanged: (text) => controller.editStep(steps[i].id, text),
          onLeave: () => controller.leaveStep(steps[i].id),
        ),
      ],
      gap,
      DeviceDetailsRow(details: controller.deviceDetails),
    ];
  }

  Future<void> _pickScreen(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final choice = await showCommunitySheet<ScreenChoice>(
      context,
      builder: (_) => ScreenPickerSheet(screens: controller.screens, selected: controller.screen),
    );
    if (choice != null) controller.chooseScreen(choice);
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
        // Not shown: a Problem has its own fields.
        return l.topicHint;
    }
  }

  /// Back arrow, ✗ and system back: asks before any input is lost.
  Future<void> _leave(BuildContext context) async {
    if (controller.submitting) return;
    if (controller.hasInput) {
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
