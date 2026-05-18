import 'package:get/get.dart';
import 'languages/en.dart';
import 'languages/te.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': en,
    'te_IN': te,
  };
}
