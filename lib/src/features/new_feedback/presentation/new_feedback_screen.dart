import 'package:flutter/material.dart';

import '../../../core/di/community_dependencies.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/l10n/community_localizations.dart';
import '../../../core/navigation/community_navigator.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/theme/refresh_style.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/community_app_bar.dart';
import '../../../core/widgets/community_form_actions.dart';
import '../../../core/widgets/community_popups.dart';
import '../../../core/widgets/community_text_field.dart';
import '../../../core/widgets/controller_scope.dart';
import '../../../core/widgets/emoji_text.dart';
import '../../../core/widgets/feedback_type_picker.dart';
import '../../../core/widgets/refresh_buttons.dart';
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
  Widget build(BuildContext context) => CommunityRefresh(child: Builder(builder: _build));

  Widget _build(BuildContext context) {
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

// Gaps between the form's parts, in Figma's order on the refreshed 8 pt
// grid. The rules link's 48 px tap area gives it room of its own.
const _pillTop = 16.0;
const _pillToField = 24.0;
const _pillToProblemField = 24.0;
const _fieldToRules = 8.0;
const _menuTopPadding = 8.0;
const _problemFieldGap = 12.0;

/// Cancel and Submit: 16 from the screen's sides, 8 above.
const _actionsPadding = EdgeInsets.fromLTRB(RefreshTokens.screenPadding, 8, RefreshTokens.screenPadding, 0);

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
          title: sentenceCase(l.newFeedbackTitle),
          onBack: () => _leave(context),
          refreshed: true,
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
                        RefreshTokens.screenPadding,
                        _pillTop,
                        RefreshTokens.screenPadding,
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
                          SizedBox(
                            height: controller.type == FeedbackType.problem ? _pillToProblemField : _pillToField,
                          ),
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
                        // The menu's "Choose Topic" row lands where the pill is
                        // (the menu box has 8 above its rows).
                        top: _pillTop - _menuTopPadding,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FeedbackTypeMenu(
                            types: NewFeedbackController.types,
                            selected: controller.type,
                            onSelected: controller.chooseType,
                            onClose: controller.closeMenu,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: _actionsPadding,
                child: CommunityFormActions(
                  cancelLabel: l.cancel,
                  submitLabel: l.submit,
                  onCancel: submitting ? null : () => _leave(context),
                  onSubmit: controller.canSubmit ? () => _submit(context) : null,
                ),
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
    const gap = SizedBox(height: _problemFieldGap);
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

  /// The refreshed link: 48 high with a ripple, 15 SemiBold; red (at
  /// 4.5:1) until the user agreed, then in the secondary text colour.
  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final color = agreed
        ? RefreshColors.meta(context, on: background)
        : RefreshColors.readable(CommunityColors.of(context).cancel, scheme.onSurface, background, 4.5);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: RefreshTokens.body(context, weight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(64, RefreshTokens.minTarget),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RefreshTokens.controlRadius)),
      ),
      child: Text(sentenceCase(agreed ? l.rulesLink : l.agreeToRules)),
    );
  }
}
