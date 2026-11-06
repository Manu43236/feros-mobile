import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../controllers/supervisor_def_requests_controller.dart';

class SupervisorDefRequestsView extends GetView<SupervisorDefRequestsController> {
  const SupervisorDefRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text('DEF Requests',
            style: TextStyle(
                color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'def_request_fab',
        onPressed: () => _showRequestSheet(context),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Request DEF',
            style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const ShimmerList(count: 4);
        return Column(
          children: [
            _FilterChips(controller: controller),
            Expanded(
              child: controller.filteredRequests.isEmpty
                  ? EmptyState(
                      icon: Icons.local_drink_outlined,
                      title: controller.requests.isEmpty
                          ? 'No DEF requests yet'
                          : 'No ${controller.filter.value.toLowerCase()} requests',
                      subtitle: 'Tap "Request DEF" to raise one for a vehicle',
                    )
                  : RefreshIndicator(
                      onRefresh: controller.reload,
                      color: AppColors.navy,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: controller.filteredRequests.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _RequestCard(req: controller.filteredRequests[i]),
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _showRequestSheet(BuildContext context) async {
    controller.resetForm();
    if (!context.mounted) return;
    await showModalBottomSheet(
      useSafeArea: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RequestSheet(controller: controller, ctx: ctx),
    );
  }
}

// ── Filter Chips ────────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final SupervisorDefRequestsController controller;
  const _FilterChips({required this.controller});

  static const _options = [
    ('PENDING',  'Pending'),
    ('ISSUED',   'Issued'),
    ('REJECTED', 'Rejected'),
    ('ALL',      'All'),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: _options.map((opt) {
          final selected = controller.filter.value == opt.$1;
          final isPending = opt.$1 == 'PENDING';
          final badge = isPending && controller.pendingCount > 0 ? ' (${controller.pendingCount})' : '';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => controller.filter.value = opt.$1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppColors.navy : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? AppColors.navy : AppColors.border),
                ),
                child: Text(
                  '${opt.$2}$badge',
                  style: AppTextStyles.caption.copyWith(
                    color: selected ? Colors.white : AppColors.bodyText,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ));
  }
}

// ── Request Card ────────────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> req;
  const _RequestCard({required this.req});

  (Color, Color, String) _statusStyle(String? status) {
    switch (status) {
      case 'ISSUED':
        return (const Color(0xFF166534), const Color(0xFFDCFCE7), 'Issued');
      case 'REJECTED':
        return (const Color(0xFF991B1B), const Color(0xFFFEE2E2), 'Rejected');
      default:
        return (const Color(0xFF9A3412), const Color(0xFFFFEDD5), 'Pending');
    }
  }

  String _fmtDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw as String);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = req['status'] as String?;
    final st = _statusStyle(status);
    final vehicle = req['vehicleRegistrationNumber'] as String? ?? '—';
    final part = req['sparePartName'] as String?;
    final qty = (req['quantityIssued'] as num?)?.toInt();
    final reason = req['rejectionReason'] as String?;
    final notes = req['notes'] as String?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_drink_outlined, color: AppColors.navy, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
                    const SizedBox(height: 2),
                    Text(_fmtDate(req['createdAt']),
                        style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: st.$2, borderRadius: BorderRadius.circular(6)),
                child: Text(st.$3,
                    style: AppTextStyles.caption.copyWith(
                        color: st.$1, fontWeight: FontWeight.w600, fontSize: 11)),
              ),
            ],
          ),
          if (status == 'ISSUED' && part != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Text('Issued: ${qty ?? ''}x $part'.trim(),
                style: AppTextStyles.caption.copyWith(color: AppColors.bodyText)),
          ],
          if (status == 'REJECTED' && reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Text('Reason: $reason',
                style: AppTextStyles.caption.copyWith(color: const Color(0xFF991B1B))),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(notes, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ],
        ],
      ),
    );
  }
}

// ── Request Sheet ───────────────────────────────────────────────────────────────
class _RequestSheet extends StatelessWidget {
  final SupervisorDefRequestsController controller;
  final BuildContext ctx;
  const _RequestSheet({required this.controller, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final notesCtrl = TextEditingController();
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Request DEF', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy)),
            const SizedBox(height: 4),
            Text('The store-keeper will select the DEF item and quantity when issuing.',
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('Vehicle *',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedText, fontWeight: FontWeight.w500)),
            ),
            Obx(() {
              final options = controller.vehicles
                  .map((v) => DropdownMenuItem<int>(
                        value: v['id'] as int,
                        child: Text(v['registrationNumber'] as String? ?? '—',
                            style: AppTextStyles.body),
                      ))
                  .toList();
              return DropdownButtonFormField<int>(
                value: controller.selectedVehicleId.value,
                hint: Text('Select vehicle',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                items: options,
                onChanged: (v) => controller.selectedVehicleId.value = v,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.navy),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                isExpanded: true,
              );
            }),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('Notes (Optional)',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedText, fontWeight: FontWeight.w500)),
            ),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Any additional notes…',
                hintStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.navy),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : () async {
                        final ok = await controller.submitRequest(notesCtrl.text);
                        if (ok && ctx.mounted) Navigator.of(ctx).pop();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Submit Request',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600)),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
