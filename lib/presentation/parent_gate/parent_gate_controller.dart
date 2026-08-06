import 'dart:math';

import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';

/// A simple parental gate with no personal data: solve a small addition
/// problem, picked at random. A wrong answer regenerates a new problem
/// rather than showing an error state — this is a lock, not a failure.
class ParentGateController extends GetxController {
  final Random _random = Random();

  final RxInt operandA = 0.obs;
  final RxInt operandB = 0.obs;
  final RxList<int> choices = <int>[].obs;
  final RxBool showError = false.obs;

  @override
  void onInit() {
    super.onInit();
    _generateChallenge();
  }

  void _generateChallenge() {
    final a = 3 + _random.nextInt(6); // 3..8
    final b = 2 + _random.nextInt(6); // 2..7
    operandA.value = a;
    operandB.value = b;

    final correct = a + b;
    final wrongOptions = <int>{};
    while (wrongOptions.length < 3) {
      final delta = 1 + _random.nextInt(5);
      final subtract = _random.nextBool() && correct - delta >= 0;
      final candidate = subtract ? correct - delta : correct + delta;
      if (candidate != correct && candidate >= 0) wrongOptions.add(candidate);
    }
    choices.value = [correct, ...wrongOptions]..shuffle(_random);
  }

  void submit(int answer) {
    if (answer == operandA.value + operandB.value) {
      Get.offNamed(AppRoutes.parentZone);
    } else {
      showError.value = true;
      _generateChallenge();
    }
  }
}
