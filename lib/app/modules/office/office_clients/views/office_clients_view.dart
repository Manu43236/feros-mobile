import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../controllers/office_clients_controller.dart';
import 'office_client_form_view.dart';

class OfficeClientsView extends StatelessWidget {
  const OfficeClientsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<OfficeClientsController>(() => OfficeClientsController());
    final controller = Get.find<OfficeClientsController>();
    final isAdmin    = Get.find<AuthService>().user?.role == 'ADMIN';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text('Clients',
            style: TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600,
              fontSize: 16, color: Colors.white,
            )),
      ),
      body: Column(
        children: [
          // ── Search + Filter ─────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: controller.onSearch,
                    style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
                      hintStyle: AppTextStyles.body
                          .copyWith(color: AppColors.hintText),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.mutedText, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Obx(() {
                    final sel = controller.selectedFilter.value;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: ['ALL', 'ACTIVE', 'INACTIVE'].map((f) {
                          final active = f == sel;
                          final label  = f == 'ALL'
                              ? 'All'
                              : f == 'ACTIVE'
                                  ? 'Active'
                                  : 'Inactive';
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => controller.setFilter(f),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.navy
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: active
                                        ? AppColors.navy
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(label,
                                    style: AppTextStyles.caption.copyWith(
                                      color: active
                                          ? Colors.white
                                          : AppColors.mutedText,
                                      fontWeight: active
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    )),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // ── List ───────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final state = controller.state.value;
              if (state == ViewState.loading) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.navy));
              }
              if (state == ViewState.error) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Failed to load clients',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.mutedText)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.fetchClients,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      child: const Text('Retry'),
                    ),
                  ]),
                );
              }
              final list = controller.filtered;
              if (list.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.business_outlined,
                        size: 52, color: AppColors.mutedText),
                    const SizedBox(height: 16),
                    Text('No clients found',
                        style: AppTextStyles.heading4
                            .copyWith(color: AppColors.navy)),
                    const SizedBox(height: 6),
                    Text('Try a different search or filter',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.mutedText)),
                  ]),
                );
              }
              return RefreshIndicator(
                color: AppColors.navy,
                onRefresh: controller.fetchClients,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _ClientCard(
                    client: list[i],
                    isAdmin: isAdmin,
                    onChanged: controller.fetchClients,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Client',
                  style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              onPressed: () async {
                await Get.to(() => const OfficeClientFormView());
                controller.fetchClients();
              },
            )
          : null,
    );
  }
}

// ── Client Card ────────────────────────────────────────────────────────────────
class _ClientCard extends StatelessWidget {
  final Map<String, dynamic> client;
  final bool isAdmin;
  final VoidCallback onChanged;
  const _ClientCard(
      {required this.client,
      required this.isAdmin,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final name      = client['clientName']    as String? ?? '—';
    final typeName  = client['clientTypeName']as String? ?? '';
    final phone     = client['phone']         as String? ?? '';
    final city      = client['cityName']      as String? ?? '';
    final state     = client['stateName']     as String? ?? '';
    final isActive  = client['isActive']      as bool? ?? true;
    final id        = (client['id'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () async {
        await Get.to(() => OfficeClientFormView(clientId: id));
        onChanged();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTextStyles.heading3.copyWith(
                      color: AppColors.navy, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(name,
                          style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    _ActiveChip(isActive: isActive),
                  ]),
                  if (typeName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(typeName,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                  ],
                  const SizedBox(height: 4),
                  Row(children: [
                    if (phone.isNotEmpty) ...[
                      const Icon(Icons.phone_outlined,
                          size: 12, color: AppColors.mutedText),
                      const SizedBox(width: 4),
                      Text(phone,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText)),
                      const SizedBox(width: 12),
                    ],
                    if (city.isNotEmpty) ...[
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        state.isNotEmpty ? '$city, $state' : city,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final bool isActive;
  const _ActiveChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.mutedText)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: AppTextStyles.caption.copyWith(
          color: isActive ? AppColors.success : AppColors.mutedText,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
