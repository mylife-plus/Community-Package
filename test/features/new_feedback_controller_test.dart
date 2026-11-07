import 'dart:convert';

import 'package:community_package/src/core/errors/app_error.dart';
import 'package:community_package/src/core/state/loading_state.dart';
import 'package:community_package/src/data/models/feedback_item.dart';
import 'package:community_package/src/data/repositories/identity_repository.dart';
import 'package:community_package/src/features/new_feedback/presentation/new_feedback_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_anon_id_source.dart';
import '../helpers/fake_backend.dart';
import '../helpers/feedback_json.dart';

const _tag = 'community_test_new_feedback';

void main() {
  late FakeBackend backend;
  late IdentityRepository identity;

  NewFeedbackController start() =>
      Get.put(NewFeedbackController(backend.repository(), identity), tag: _tag);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
    identity = IdentityRepository(FakeAnonIdSource(id: FakeAnonIdSource.createdId));
  });

  tearDown(() {
    Get.delete<NewFeedbackController>(tag: _tag, force: true);
    identity.dispose();
  });

  test('offers Improvement, Problem and Idea, and nothing is chosen at first', () {
    final controller = start();

    expect(NewFeedbackController.types, [FeedbackType.improvement, FeedbackType.problem, FeedbackType.idea]);
    expect(controller.type, isNull);
    expect(controller.canSubmit, isFalse);
  });

  test('needs a topic and text that is not only spaces', () {
    final controller = start();

    controller.textController.text = '   ';
    controller.chooseType(FeedbackType.idea);
    expect(controller.canSubmit, isFalse);

    controller.textController.text = ' Dark icon ';
    expect(controller.canSubmit, isTrue);
  });

  test('beginSubmit locks the form; send posts the trimmed text', () async {
    final controller = start()
      ..chooseType(FeedbackType.improvement)
      ..textController.text = '  Totals per shelf \n';
    backend.answer(feedbackJson(26, type: 'improvement'), status: 201);

    expect(controller.beginSubmit(), isTrue);
    expect(controller.submitState, LoadingState.loading);
    expect(controller.canSubmit, isFalse);
    expect(controller.beginSubmit(), isFalse); // a second tap does nothing
    final item = await controller.send();

    expect(item.number, 26);
    expect(controller.submitState, LoadingState.success);
    expect(controller.canSubmit, isFalse);
    expect(jsonDecode(backend.requests.single.body), {'type': 'improvement', 'text': 'Totals per shelf'});
  });

  test('cancelSubmit unlocks the form without sending', () {
    final controller = start()
      ..chooseType(FeedbackType.idea)
      ..textController.text = 'Dark icon';

    controller.beginSubmit();
    controller.cancelSubmit();

    expect(controller.submitState, LoadingState.idle);
    expect(controller.canSubmit, isTrue);
    expect(backend.requests, isEmpty);
  });

  test('a failed send rethrows, keeps the text and allows a retry', () async {
    final controller = start()
      ..chooseType(FeedbackType.idea)
      ..textController.text = 'Dark icon';
    backend.fail(status: 429, code: 'rate_limited');

    controller.beginSubmit();
    await expectLater(
      controller.send(),
      throwsA(isA<AppError>().having((e) => e.type, 'type', AppErrorType.rateLimited)),
    );

    expect(controller.submitState, LoadingState.error);
    expect(controller.textController.text, 'Dark icon');
    expect(controller.canSubmit, isTrue);
  });

  test('beginSubmit refuses while the form is not ready', () {
    final controller = start()..textController.text = 'No topic';

    expect(controller.beginSubmit(), isFalse);
    expect(controller.submitState, LoadingState.idle);
  });

  test('the topic list starts open and closes when a topic is chosen', () {
    final controller = start();
    expect(controller.menuOpen, isTrue);

    controller.chooseType(FeedbackType.idea);
    expect(controller.menuOpen, isFalse);

    controller.openMenu();
    expect(controller.menuOpen, isTrue);
    controller.closeMenu();
    expect(controller.menuOpen, isFalse);
    expect(controller.type, FeedbackType.idea);
  });

  test('follows the rules agreement from the identity repository', () async {
    final controller = start();
    await pumpEventQueue();
    expect(controller.rulesAgreed, isFalse);

    await identity.agreeToRules();
    await pumpEventQueue();

    expect(controller.rulesAgreed, isTrue);
  });

  test('reads an earlier rules agreement at start', () async {
    SharedPreferences.setMockInitialValues({IdentityRepository.rulesAgreedKey: true});
    identity = IdentityRepository(FakeAnonIdSource(id: FakeAnonIdSource.createdId));

    final controller = start();
    await pumpEventQueue();

    expect(controller.rulesAgreed, isTrue);
  });
}
