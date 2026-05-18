import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/widgets/pulsing_dot.dart';
import '../controllers/supervisor_lrs_controller.dart';
import '../controllers/supervisor_lr_detail_controller.dart';
import 'supervisor_lr_detail_view.dart';
import 'supervisor_create_lr_sheet.dart';

class SupervisorLrsView extends GetView<SupervisorLrsController> {
  const SupervisorLrsView({super.key});

  static const _statuses = [
    'ALL',
    'CREATED',
    'WEIGHT_LOADED',
    'IN_TRANSIT',
    'DELIVERED',
    'CANCELLED',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Text(
          'lbl_lrs'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                // ── Search ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: controller.onSearch,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.bodyText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'lbl_search_lrs'.tr,
                      hintStyle: AppTextStyles.body.copyWith(
                        color: AppColors.hintText,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.mutedText,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // ── Status filters ──────────────────────────────────
                Obx(() {
                  final selected = controller.statusFilter.value;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: _statuses.map((s) {
                        final isAll = s == 'ALL';
                        final isActive = isAll
                            ? selected.isEmpty
                            : selected == s;
                        final color = _lrColor(s);
                        final count = isAll
                            ? controller.totalCount
                            : controller.countByStatus(s);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => controller.setFilter(isAll ? '' : s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? color
                                    : color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isActive
                                      ? color
                                      : color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _lrLabel(s),
                                    style: AppTextStyles.caption.copyWith(
                                      color: isActive ? Colors.white : color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isActive ? Colors.white : color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.state.value == ViewState.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.navy),
                );
              }
              if (controller.state.value == ViewState.error) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'lbl_failed_lrs'.tr,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.fetchLrs,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('btn_retry'.tr),
                      ),
                    ],
                  ),
                );
              }
              final list = controller.lrs;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 52,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'lbl_no_lrs_found'.tr,
                        style: AppTextStyles.heading4.copyWith(
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'lbl_try_filter'.tr,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.navy,
                onRefresh: controller.fetchLrs,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _LrCard(lr: list[i]),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'btn_create_lr'.tr,
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
        onPressed: () async {
          await controller.ensureOrdersLoaded();
          if (controller.orders.isEmpty) {
            Get.snackbar(
              'lbl_no_active_orders'.tr,
              'lbl_no_orders_for_lr'.tr,
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
          showModalBottomSheet(
            context: Get.context!,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SupervisorCreateLrSheet(controller: controller),
          );
        },
      ),
    );
  }
}

// ── LR Card ───────────────────────────────────────────────────────────────────
class _LrCard extends StatelessWidget {
  final Map<String, dynamic> lr;
  const _LrCard({required this.lr});

  void _openDetail() {
    final id = lr['id'];
    if (id == null) return;
    final lrId = id is int ? id : int.tryParse(id.toString()) ?? 0;
    Get.to(
      () => const SupervisorLrDetailView(),
      binding: BindingsBuilder(() {
        Get.put(SupervisorLrDetailController());
      }),
      arguments: lrId,
      transition: Transition.cupertino,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = lr['lrStatus'] as String? ?? '';
    final lrNumber = lr['lrNumber'] as String? ?? '—';
    final vehicle = lr['vehicleRegistrationNumber'] as String? ?? '—';
    final client = lr['clientName'] as String? ?? '—';
    final fromCity = lr['fromCity'] as String? ?? '—';
    final toCity = lr['toCity'] as String? ?? '—';
    final allocatedWeight = lr['allocatedWeight'];
    final loadedWeight = lr['loadedWeight'];
    final weight = loadedWeight ?? allocatedWeight;
    final weightLabel = loadedWeight != null ? 'lbl_loaded_chip'.tr : 'lbl_alloc_chip'.tr;
    final lrDate = lr['lrDate'] as String?;
    final orderNum = lr['orderNumber'] as String?;

    return GestureDetector(
      onTap: _openDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LR number + status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lrNumber,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (orderNum != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${'lbl_order_prefix'.tr} $orderNum',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _LrStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 8),

              // Client
              Text(
                client,
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Vehicle
              Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 13,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    vehicle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.bodyText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Route
              Row(
                children: [
                  const Icon(
                    Icons.radio_button_checked,
                    size: 12,
                    color: AppColors.navy,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      fromCity,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.bodyText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.location_on,
                    size: 12,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      toCity,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.bodyText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),

              // Weight + date
              Row(
                children: [
                  if (weight != null) ...[
                    const Icon(
                      Icons.scale_outlined,
                      size: 12,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$weightLabel: ${weight}T',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (lrDate != null) ...[
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      FerosDateUtils.formatDate(lrDate),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.mutedText,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── LR Status Badge ───────────────────────────────────────────────────────────
class _LrStatusBadge extends StatelessWidget {
  final String status;
  const _LrStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _lrColor(status);
    return Container(
      padding: EdgeInsets.only(
        left: status == 'IN_TRANSIT' ? 6 : 10,
        right: 10,
        top: 4,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == 'IN_TRANSIT') ...[
            PulsingDot(color: color, size: 6),
            const SizedBox(width: 4),
          ],
          Text(
            _lrLabel(status),
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Color _lrColor(String s) {
  switch (s) {
    case 'ALL':
      return AppColors.navy;
    case 'CREATED':
      return AppColors.lrCreated;
    case 'WEIGHT_LOADED':
      return AppColors.lrLoaded;
    case 'IN_TRANSIT':
      return AppColors.lrInTransit;
    case 'DELIVERED':
      return AppColors.lrDelivered;
    case 'INVOICED':
      return AppColors.lrInvoiced;
    case 'CANCELLED':
      return AppColors.error;
    default:
      return AppColors.mutedText;
  }
}

String _lrLabel(String s) {
  switch (s) {
    case 'ALL':          return 'lbl_all'.tr;
    case 'CREATED':      return 'lbl_lr_created'.tr;
    case 'WEIGHT_LOADED':return 'lbl_weight_loaded_chip'.tr;
    case 'IN_TRANSIT':   return 'status_in_transit'.tr;
    case 'DELIVERED':    return 'status_delivered'.tr;
    case 'INVOICED':     return 'status_invoiced'.tr;
    case 'CANCELLED':    return 'status_cancelled'.tr;
    default:             return s;
  }
}
