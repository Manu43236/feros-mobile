import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_view.dart';
import '../../../../../core/pdf_viewer/pdf_viewer_binding.dart';
import '../../../../../core/popups/feros_snackbar.dart';

class SupervisorOrderDetailController extends GetxController {
  final _api = Get.find<ApiClient>();

  final state        = ViewState.loading.obs;
  final order        = Rxn<Map<String, dynamic>>();
  final lrs          = <Map<String, dynamic>>[].obs;
  final pdfLoadingId = Rxn<int>();

  late final int orderId;

  @override
  void onInit() {
    super.onInit();
    orderId = Get.arguments as int;
    fetchAll();
  }

  Future<void> fetchAll() async {
    state.value = ViewState.loading;
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.orderById(orderId)),
        _api.get(ApiEndpoints.lrsByOrder(orderId)),
      ]);

      order.value = (results[0].data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;

      lrs.value = ((results[1].data as Map<String, dynamic>)['data'] as List)
          .cast<Map<String, dynamic>>();

      state.value = ViewState.success;
    } catch (_) {
      state.value = ViewState.error;
    }
  }

  Future<void> viewLrPdf(int lrId, String lrNumber, String route) async {
    if (pdfLoadingId.value != null) return;
    pdfLoadingId.value = lrId;
    try {
      final bytes = await _api.getBytes(ApiEndpoints.lrPdf(lrId));
      final dir   = await getTemporaryDirectory();
      final file  = File('${dir.path}/$lrNumber.pdf');
      await file.writeAsBytes(bytes);
      await Get.to(
        () => const PdfViewerView(),
        binding: PdfViewerBinding(),
        arguments: {'file': file, 'title': route, 'subtitle': lrNumber},
        transition: Transition.cupertino,
      );
    } catch (_) {
      FerosSnackbar.error('Failed to load PDF');
    }
    pdfLoadingId.value = null;
  }
}
