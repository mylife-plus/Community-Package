import 'dart:async';
import 'dart:convert';

import 'package:community_package/community_package.dart';
import 'package:community_package/src/core/identity/device_details.dart';
import 'package:community_package/src/data/models/feedback_item.dart';
import 'package:community_package/src/data/repositories/identity_repository.dart';
import 'package:community_package/src/features/new_feedback/presentation/new_feedback_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_anon_id_source.dart';
import '../helpers/fake_backend.dart';
import '../helpers/fake_device_details.dart';
import '../helpers/feedback_json.dart';

const _tag = 'community_test_new_problem';

const _screens = [
  ScreenNode('Inventory', children: [ScreenNode('Sell Items', children: [ScreenNode('Add Items')])]),
];

void main() {
  late FakeBackend backend;
  late IdentityRepository identity;
  late FakeDeviceDetailsSource device;

  NewFeedbackController start({List<ScreenNode> screens = _screens}) => Get.put(
    NewFeedbackController(backend.repository(), identity, screens: screens, deviceDetails: device),
    tag: _tag,
  );

  /// A Problem form with [screen] chosen.
  NewFeedbackController problem({String? screen = 'Inventory > Sell Items > Add Items'}) {
    final controller = start()..chooseType(FeedbackType.problem);
    if (screen != null) {
      controller.chooseScreen(controller.screens.firstWhere((s) => s.savedPath == screen));
    }
    return controller;
  }

  /// Types [text] into the step field at [index].
  void type(NewFeedbackController controller, int index, String text) =>
      controller.editStep(controller.steps[index].id, text);

  List<String> texts(NewFeedbackController controller) => [for (final s in controller.steps) s.text];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
    identity = IdentityRepository(FakeAnonIdSource(id: FakeAnonIdSource.createdId));
    device = FakeDeviceDetailsSource();
  });

  tearDown(() {
    Get.delete<NewFeedbackController>(tag: _tag, force: true);
    identity.dispose();
  });

  test("offers the host's screens and the package's own", () {
    final controller = start();

    expect(controller.asksScreen, isTrue);
    expect(controller.screens.first.savedPath, 'Inventory');
    expect(controller.screens.last.savedPath, 'Community > New Feedback');
  });

  test('needs a screen and a filled step', () {
    final controller = problem(screen: null);
    expect(controller.canSubmit, isFalse);

    type(controller, 0, '   ');
    expect(controller.canSubmit, isFalse);

    type(controller, 0, 'Tap plus');
    expect(controller.canSubmit, isFalse); // no screen yet

    controller.chooseScreen(controller.screens[1]);
    expect(controller.canSubmit, isTrue);
  });

  test('a parent screen can be chosen', () {
    final controller = problem(screen: 'Inventory');
    type(controller, 0, 'Open the app');

    expect(controller.screen!.savedPath, 'Inventory');
    expect(controller.canSubmit, isTrue);
  });

  test('without screens from the host it asks no screen', () {
    final controller = start(screens: const [])..chooseType(FeedbackType.problem);

    expect(controller.asksScreen, isFalse);
    type(controller, 0, 'Tap plus');
    expect(controller.canSubmit, isTrue);
  });

  test('starts with one empty step; filling the last adds the next', () {
    final controller = problem();
    expect(texts(controller), ['']);

    type(controller, 0, 'T');
    expect(texts(controller), ['T', '']);

    type(controller, 0, 'Tap plus'); // still typing in step 1: no third field
    type(controller, 1, 'Add an item');
    expect(texts(controller), ['Tap plus', 'Add an item', '']);
  });

  test('stops at 10 steps', () {
    final controller = problem();
    for (var i = 0; i < 12 && i < controller.steps.length; i++) {
      type(controller, i, 'Step ${i + 1}');
    }

    expect(controller.steps, hasLength(NewFeedbackController.maxSteps));
    expect(controller.steps.every((s) => s.isFilled), isTrue);
    expect(controller.filledSteps.last, 'Step 10');
  });

  test('a step emptied and left is removed; the empty last field stays', () {
    final controller = problem();
    type(controller, 0, 'Tap plus');
    type(controller, 1, 'Add an item');
    final lastId = controller.steps.last.id;

    type(controller, 0, '');
    expect(texts(controller), ['', 'Add an item', '']); // still focused: kept
    controller.leaveStep(controller.steps[0].id);
    expect(texts(controller), ['Add an item', '']);

    controller.leaveStep(lastId);
    expect(texts(controller), ['Add an item', '']);
  });

  test('a filled step left alone stays', () {
    final controller = problem();
    type(controller, 0, 'Tap plus');

    controller.leaveStep(controller.steps[0].id);

    expect(texts(controller), ['Tap plus', '']);
  });

  test('removing a step from a full list brings back an empty last field', () {
    final controller = problem();
    for (var i = 0; i < 10; i++) {
      type(controller, i, 'Step ${i + 1}');
    }
    final third = controller.steps[2].id;

    controller.editStep(third, '');
    controller.leaveStep(third);

    expect(controller.steps, hasLength(10));
    expect(controller.steps.last.isFilled, isFalse);
    expect(controller.filledSteps, hasLength(9));
  });

  test('send posts the filled steps, path, description and device details', () async {
    final controller = problem();
    type(controller, 0, '  Tap plus ');
    type(controller, 1, 'Add an item');
    controller.descriptionController.text = '  No item gets added. ';
    backend.answer({...feedbackJson(26, type: 'problem'), 'steps': ['Tap plus', 'Add an item']}, status: 201);

    expect(controller.beginSubmit(), isTrue);
    final item = await controller.send();

    expect(item.type, FeedbackType.problem);
    expect(jsonDecode(backend.requests.single.body), {
      'type': 'problem',
      'steps': ['Tap plus', 'Add an item'],
      'screenPath': 'Inventory > Sell Items > Add Items',
      'description': 'No item gets added.',
      'osVersion': 'iOS 18.1',
      'appVersion': '3.2.0',
      'deviceModel': 'iPhone 15 Pro',
    });
  });

  test('a blank description is sent as null', () async {
    final controller = problem();
    type(controller, 0, 'Tap plus');
    controller.descriptionController.text = '   ';
    backend.answer(feedbackJson(26, type: 'problem'), status: 201);

    controller.beginSubmit();
    await controller.send();

    expect(jsonDecode(backend.requests.single.body)['description'], isNull);
  });

  test('reads the device details once when the form opens', () async {
    final controller = start();
    expect(controller.deviceDetails, isNull);

    await pumpEventQueue();

    expect(controller.deviceDetails, FakeDeviceDetailsSource.sample);
    expect(device.reads, 1);
  });

  test('a Problem sent while the details are still read waits for them', () async {
    final gate = Completer<void>();
    device = FakeDeviceDetailsSource(gate: gate.future);
    final controller = problem();
    type(controller, 0, 'Tap plus');
    backend.answer(feedbackJson(26, type: 'problem'), status: 201);

    controller.beginSubmit();
    final sending = controller.send();
    await pumpEventQueue();
    expect(backend.requests, isEmpty);

    gate.complete();
    await sending;
    expect(jsonDecode(backend.requests.single.body)['osVersion'], 'iOS 18.1');
    expect(device.reads, 1);
  });

  test('details that cannot be read are sent as null', () async {
    device = FakeDeviceDetailsSource(details: DeviceDetails.unknown);
    final controller = problem();
    type(controller, 0, 'Tap plus');
    backend.answer(feedbackJson(26, type: 'problem'), status: 201);

    controller.beginSubmit();
    await controller.send();

    final body = jsonDecode(backend.requests.single.body) as Map<String, dynamic>;
    expect([body['osVersion'], body['appVersion'], body['deviceModel']], [null, null, null]);
  });

  test('any input counts before leaving: screen, step or description', () {
    var controller = problem(screen: null);
    expect(controller.hasInput, isFalse);
    controller.chooseScreen(controller.screens.first);
    expect(controller.hasInput, isTrue);
    Get.delete<NewFeedbackController>(tag: _tag, force: true);

    controller = problem(screen: null);
    type(controller, 0, 'Tap plus');
    expect(controller.hasInput, isTrue);
    Get.delete<NewFeedbackController>(tag: _tag, force: true);

    controller = problem(screen: null);
    controller.descriptionController.text = 'Broken';
    expect(controller.hasInput, isTrue);
  });

  test('switching topic keeps the input, and Improvement sends only its text', () async {
    final controller = problem();
    type(controller, 0, 'Tap plus');
    controller
      ..chooseType(FeedbackType.improvement)
      ..textController.text = 'Totals';
    expect(controller.canSubmit, isTrue);
    backend.answer(feedbackJson(26, type: 'improvement'), status: 201);

    controller.beginSubmit();
    await controller.send();

    expect(jsonDecode(backend.requests.single.body), {'type': 'improvement', 'text': 'Totals'});
    expect(controller.filledSteps, ['Tap plus']);
  });
}
