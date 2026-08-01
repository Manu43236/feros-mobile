import 'package:get/get.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/localization/locale_service.dart';
import 'tutorial_video_model.dart';

class TutorialsController extends GetxController {
  final _client = Get.find<ApiClient>();

  final videos    = <TutorialVideo>[].obs;
  final isLoading = true.obs;
  final error     = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    isLoading.value = true;
    error.value = '';
    try {
      final lang = Get.find<LocaleService>().locale.languageCode;
      final res  = await _client.get(ApiEndpoints.tutorialVideos(lang));
      final list = (res.data['data'] as List? ?? []);
      videos.value = list.map((e) => TutorialVideo.fromJson(e)).toList();
    } catch (_) {
      error.value = 'Failed to load tutorials. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}
