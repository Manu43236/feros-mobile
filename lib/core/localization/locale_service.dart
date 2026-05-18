import 'dart:ui';
import 'package:get/get.dart';
import '../services/storage_service.dart';

class LocaleService extends GetxService {
  static const _defaultLocale = Locale('en', 'US');

  final _locale = _defaultLocale.obs;
  Locale get locale => _locale.value;

  bool get isTelugu => _locale.value.languageCode == 'te';
  bool get isEnglish => _locale.value.languageCode == 'en';

  @override
  void onInit() async {
    super.onInit();
    final saved = await Get.find<StorageService>().getLocale();
    if (saved != null) {
      _locale.value = saved;
      Get.updateLocale(saved);
    }
  }

  Future<void> setEnglish() => _applyLocale(const Locale('en', 'US'));
  Future<void> setTelugu()  => _applyLocale(const Locale('te', 'IN'));

  Future<void> _applyLocale(Locale locale) async {
    _locale.value = locale;
    Get.updateLocale(locale);
    await Get.find<StorageService>().saveLocale(locale);
  }
}
