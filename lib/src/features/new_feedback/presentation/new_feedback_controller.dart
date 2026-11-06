import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/state/loading_state.dart';
import '../../../data/models/feedback_item.dart';
import '../../../data/models/identity.dart';
import '../../../data/repositories/feedback_repository.dart';
import '../../../data/repositories/identity_repository.dart';

/// State of the New Feedback form: topic, text and submitting.
class NewFeedbackController extends GetxController {
  NewFeedbackController(this._feedback, this._identity);

  /// Longest text, in characters as the user sees them. The backend checks
  /// the same limit.
  static const maxTextLength = 2000;

  /// Topics this form offers. Problem arrives with the problem form.
  static const types = [FeedbackType.improvement, FeedbackType.idea];

  final FeedbackRepository _feedback;
  final IdentityRepository _identity;
  StreamSubscription<Identity>? _identitySubscription;
  bool _closed = false;

  final textController = TextEditingController();

  /// Null until the user picks a topic.
  FeedbackType? type;

  /// The topic list is open. It opens by itself until a topic is chosen.
  bool menuOpen = true;

  /// Shows "agree to Rules" before, and a "Rules" link after.
  bool rulesAgreed = false;

  LoadingState submitState = LoadingState.idle;

  bool get submitting => submitState == LoadingState.loading;

  bool get hasText => textController.text.trim().isNotEmpty;

  /// Ready to send, and not sent yet: after a success the screen leaves.
  bool get canSubmit =>
      type != null && hasText && !submitting && submitState != LoadingState.success;

  @override
  void onInit() {
    super.onInit();
    textController.addListener(_onTextChanged);
    _identitySubscription = _identity.identityStream.listen(_onIdentity);
    unawaited(_loadIdentity());
  }

  @override
  void onClose() {
    _closed = true;
    _identitySubscription?.cancel();
    textController.dispose();
    super.onClose();
  }

  void chooseType(FeedbackType value) {
    if (submitting) return;
    type = value;
    menuOpen = false;
    update();
  }

  void openMenu() {
    if (submitting || menuOpen) return;
    menuOpen = true;
    update();
  }

  void closeMenu() {
    if (!menuOpen) return;
    menuOpen = false;
    update();
  }

  /// First step of a submit, before the privacy notice and the rules are
  /// asked: locks the form. False when the form is not ready or already
  /// being sent.
  bool beginSubmit() {
    if (!canSubmit) return false;
    menuOpen = false;
    submitState = LoadingState.loading;
    update();
    return true;
  }

  /// The user did not agree, so nothing is sent: unlocks the form.
  void cancelSubmit() {
    if (_closed || !submitting) return;
    submitState = LoadingState.idle;
    update();
  }

  /// Sends the feedback after [beginSubmit]. Failures are rethrown as
  /// [AppError] for the screen to show; the text stays so the user can try
  /// again.
  Future<FeedbackItem> send() async {
    final chosen = type;
    if (chosen == null || !submitting) {
      throw StateError('send() needs beginSubmit() first');
    }
    try {
      final item = await _feedback.createFeedback(type: chosen, text: textController.text.trim());
      if (!_closed) {
        submitState = LoadingState.success;
        update();
      }
      return item;
    } on AppError {
      if (!_closed) {
        submitState = LoadingState.error;
        update();
      }
      rethrow;
    }
  }

  // Rebuilds only when the submit button changes, not on every key.
  bool _hadText = false;

  void _onTextChanged() {
    if (_closed || hasText == _hadText) return;
    _hadText = hasText;
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
    update();
  }
}
