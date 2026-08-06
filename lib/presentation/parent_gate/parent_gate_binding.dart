import 'package:get/get.dart';
import 'parent_gate_controller.dart';

class ParentGateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ParentGateController>(() => ParentGateController());
  }
}
