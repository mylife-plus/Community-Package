import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../config/screen_node.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/identity/device_details.dart';
import '../../../core/state/loading_state.dart';
import '../../../data/models/feedback_item.dart';
import '../../../data/models/identity.dart';
import '../../../data/repositories/feedback_repository.dart';
import '../../../data/repositories/identity_repository.dart';
import '../domain/screen_tree.dart';

/// One step field of the Problem form. [id] stays the same while steps
/// before it are removed, so its field keeps its state.
@immutable
class ProblemStep {
  const ProblemStep(this.id, this.text);

  final int id;
  final String text;

  bool get isFilled => text.trim().isNotEmpty;
}

/// State of the New Feedback form: topic, text or the Problem fields, and
/// submitting.
class NewFeedbackController extends GetxController {
  NewFeedbackController(
    this._feedback,
    this._identity, {
    List<ScreenNode> screens = const [],
    DeviceDetailsSource? deviceDetails,
  }) : screens = pickerScreens(screens),
       _deviceDetailsSource = deviceDetails;

  /// Longest text and Problem description, in characters as the user sees
  /// them. The backend checks the same limits.
  static const maxTextLength = 2000;
  static const maxSteps = 10;
  static const maxStepLength = 500;

  /// Problems get an optional "What went wrong?" field. It is not in Figma;
  /// false removes it from the form.
  static const askProblemDescription = true;

  static const types = [FeedbackType.improvement, FeedbackType.problem, FeedbackType.idea];

  final FeedbackRepository _feedback;
  final IdentityRepository _identity;
  final DeviceDetailsSource? _deviceDetailsSource;
  StreamSubscription<Identity>? _identitySubscription;
  Future<DeviceDetails>? _deviceDetailsRead;
  bool _closed = false;

  /// Improvement and Idea text.
  final textController = TextEditingController();

  /// The Problem's optional description.
  final descriptionController = TextEditingController();

  /// Null until the user picks a topic.
  FeedbackType? type;

  /// The topic list is open. It opens by itself until a topic is chosen.
  bool menuOpen = true;

  /// Shows "agree to Rules" before, and a "Rules" link after.
  bool rulesAgreed = false;

  LoadingState submitState = LoadingState.idle;

  /// Every screen the picker offers. Empty: the form asks no screen.
  final List<ScreenChoice> screens;

  /// The screen the Problem happens on.
  ScreenChoice? screen;

  /// The step fields: the filled ones, then one empty field for the next
  /// step while there are fewer than [maxSteps].
  List<ProblemStep> get steps => List.unmodifiable(_steps);
  final _steps = <ProblemStep>[];
  int _nextStepId = 0;

  /// Null while they are read.
  DeviceDetails? deviceDetails;

  bool get submitting => submitState == LoadingState.loading;

  bool get asksScreen => screens.isNotEmpty;

  bool get hasText => textController.text.trim().isNotEmpty;

  List<String> get filledSteps => [
    for (final step in _steps)
      if (step.isFilled) step.text.trim(),
  ];

  /// Anything typed or chosen, in any topic: leaving then asks first.
  bool get hasInput =>
      hasText ||
      screen != null ||
      _steps.any((step) => step.isFilled) ||
      descriptionController.text.trim().isNotEmpty;

  /// Ready to send, and not sent yet: after a success the screen leaves.
  bool get canSubmit {
    final chosen = type;
    if (chosen == null || submitting || submitState == LoadingState.success) return false;
    return switch (chosen) {
      FeedbackType.problem => (!asksScreen || screen != null) && filledSteps.isNotEmpty,
      FeedbackType.improvement || FeedbackType.idea => hasText,
    };
  }

  @override
  void onInit() {
    super.onInit();
    _addStep();
    textController.addListener(_refresh);
    descriptionController.addListener(_refresh);
    _identitySubscription = _identity.identityStream.listen(_onIdentity);
    unawaited(_loadIdentity());
    unawaited(_loadDeviceDetails());
  }

  @override
  void onClose() {
    _closed = true;
    _identitySubscription?.cancel();
    textController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void chooseType(FeedbackType value) {
    if (submitting) return;
    type = value;
    menuOpen = false;
    _refresh(force: true);
  }

  void openMenu() {
    if (submitting || menuOpen) return;
    menuOpen = true;
    _refresh(force: true);
  }

  void closeMenu() {
    if (!menuOpen) return;
    menuOpen = false;
    _refresh(force: true);
  }

  void chooseScreen(ScreenChoice value) {
    if (submitting) return;
    screen = value;
    _refresh(force: true);
  }

  /// The step [id] now reads [text]. Filling the last field adds an empty
  /// one below it.
  void editStep(int id, String text) {
    final index = _steps.indexWhere((step) => step.id == id);
    if (index < 0) return;
    _steps[index] = ProblemStep(id, text);
    if (index == _steps.length - 1 && _steps[index].isFilled && _steps.length < maxSteps) {
      _addStep();
    }
    _refresh();
  }

  /// The user left the step [id]. An emptied step is removed, unless it is
  /// the empty field at the end.
  void leaveStep(int id) {
    final index = _steps.indexWhere((step) => step.id == id);
    if (index < 0 || index == _steps.length - 1 || _steps[index].isFilled) return;
    _steps.removeAt(index);
    // Removing a step from a full list leaves no empty field at the end.
    if (_steps.last.isFilled) _addStep();
    _refresh(force: true);
  }

  /// First step of a submit, before the privacy notice and the rules are
  /// asked: locks the form. False when the form is not ready or already
  /// being sent.
  bool beginSubmit() {
    if (!canSubmit) return false;
    menuOpen = false;
    submitState = LoadingState.loading;
    _refresh(force: true);
    return true;
  }

  /// The user did not agree, so nothing is sent: unlocks the form.
  void cancelSubmit() {
    if (_closed || !submitting) return;
    submitState = LoadingState.idle;
    _refresh(force: true);
  }

  /// Sends the feedback after [beginSubmit]. Failures are rethrown as
  /// [AppError] for the screen to show; the input stays so the user can try
  /// again.
  Future<FeedbackItem> send() async {
    final chosen = type;
    if (chosen == null || !submitting) {
      throw StateError('send() needs beginSubmit() first');
    }
    try {
      final item = chosen == FeedbackType.problem
          ? await _sendProblem()
          : await _feedback.createFeedback(type: chosen, text: textController.text.trim());
      if (!_closed) {
        submitState = LoadingState.success;
        _refresh(force: true);
      }
      return item;
    } on AppError {
      if (!_closed) {
        submitState = LoadingState.error;
        _refresh(force: true);
      }
      rethrow;
    }
  }

  Future<FeedbackItem> _sendProblem() async {
    final description = descriptionController.text.trim();
    return _feedback.createProblem(
      steps: filledSteps,
      screenPath: screen?.savedPath,
      description: askProblemDescription && description.isNotEmpty ? description : null,
      device: await _loadDeviceDetails(),
    );
  }

  void _addStep() => _steps.add(ProblemStep(_nextStepId++, ''));

  // What the screen last showed. Typing rebuilds only when it changes, not
  // on every key; every other change rebuilds with [force].
  (bool, bool, int)? _shown;

  void _refresh({bool force = false}) {
    if (_closed) return;
    final shown = (hasInput, canSubmit, _steps.length);
    if (!force && shown == _shown) return;
    _shown = shown;
    update();
  }

  Future<void> _loadIdentity() async {
    try {
      _onIdentity(await _identity.load());
    } on AppError {
      // Shown as not agreed; agreeing reads again.
    }
  }

  void _onIdentity(Identity identity) {
    if (_closed || identity.rulesAgreed == rulesAgreed) return;
    rulesAgreed = identity.rulesAgreed;
    _refresh(force: true);
  }

  /// Read once; sending a Problem waits for it if it is still running.
  Future<DeviceDetails> _loadDeviceDetails() => _deviceDetailsRead ??= () async {
    final details = await _deviceDetailsSource?.read() ?? DeviceDetails.unknown;
    if (!_closed) {
      deviceDetails = details;
      _refresh(force: true);
    }
    return details;
  }();
}
