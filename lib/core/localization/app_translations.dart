import 'package:get/get.dart';
import 'bn_strings.dart';
import 'en_strings.dart';

/// GetX translations. Use with .tr on any key string:
///   Text('home_title'.tr)
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enStrings,
        'bn_BD': bnStrings,
      };
}
