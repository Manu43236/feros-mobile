import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/feros_select_field.dart';
import '../../../../../core/widgets/shimmer_card.dart';
import '../controllers/store_keeper_requests_controller.dart';

class StoreKeeperRequestsView extends StatefulWidget {
  const StoreKeeperRequestsView({super.key});

  @override
  State<StoreKeeperRequestsView> createState() =>
      _StoreKeeperRequestsViewState();
}

class _StoreKeeperRequestsViewState extends State<StoreKeeperRequestsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _ctrl = Get.find<StoreKeeperRequestsController>();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (_tab.index == 1 && _ctrl.availableTires.isEmpty) {
        _ctrl.fetchAvailableTires();
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── TabBar ──────────────────────────────────────────
        Container(
          color: AppColors.navy,
          child: TabBar(
            controller: _tab,
            indicatorColor: AppColors.orange,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Parts'),
              Tab(text: 'Tires'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _PartsTab(ctrl: _ctrl),
              _TiresTab(ctrl: _ctrl),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Parts Tab ─────────────────────────────────────────────────────────────────
class _PartsTab extends StatelessWidget {
  final StoreKeeperRequestsController ctrl;
  const _PartsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value) return const ShimmerList(count: 5);
      if (ctrl.requests.isEmpty) {
        return RefreshIndicator(
          onRefresh: ctrl.fetchRequests,
          color: AppColors.navy,
          child: ListView(children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 52, color: AppColors.border),
                  const SizedBox(height: 16),
                  Text('No Pending Requests',
                      style:
                          AppTextStyles.heading3.copyWith(color: AppColors.navy)),
                  const SizedBox(height: 8),
                  Text('All part requests have been processed',
                      style:
                          AppTextStyles.body.copyWith(color: AppColors.mutedText)),
                ],
              ),
            ),
          ]),
        );
      }
      return RefreshIndicator(
        onRefresh: ctrl.fetchRequests,
        color: AppColors.navy,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.requests.length,
          itemBuilder: (context, i) {
            final req = ctrl.requests[i];
            return _RequestCard(
              request: req,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    _ApproveRejectSheet(request: req, controller: ctrl),
              ),
            );
          },
        ),
      );
    });
  }
}

// ── Tires Tab ─────────────────────────────────────────────────────────────────
class _TiresTab extends StatelessWidget {
  final StoreKeeperRequestsController ctrl;
  const _TiresTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingTireRequests.value) return const ShimmerList(count: 5);
      if (ctrl.tireRequests.isEmpty) {
        return RefreshIndicator(
          onRefresh: ctrl.fetchTireRequests,
          color: AppColors.navy,
          child: ListView(children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.circle_outlined,
                      size: 52, color: AppColors.border),
                  const SizedBox(height: 16),
                  Text('No Pending Tire Requests',
                      style:
                          AppTextStyles.heading3.copyWith(color: AppColors.navy)),
                  const SizedBox(height: 8),
                  Text('All tire requests have been processed',
                      style:
                          AppTextStyles.body.copyWith(color: AppColors.mutedText)),
                ],
              ),
            ),
          ]),
        );
      }
      return RefreshIndicator(
        onRefresh: ctrl.fetchTireRequests,
        color: AppColors.navy,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.tireRequests.length,
          itemBuilder: (context, i) {
            final req = ctrl.tireRequests[i];
            return _TireRequestCard(
              req: req,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    _TireApproveRejectSheet(request: req, controller: ctrl),
              ),
            );
          },
        ),
      );
    });
  }
}

class _TireRequestCard extends StatelessWidget {
  final Map<String, dynamic> req;
  final VoidCallback onTap;
  const _TireRequestCard({required this.req, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final vehicle  = req['vehicleRegistrationNumber'] as String? ?? '—';
    final position = req['positionCode']              as String? ?? '—';
    final by       = req['requestedByName']           as String? ?? '—';
    final notes    = req['notes']                     as String?;
    final createdAt = req['createdAt']                as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBEB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('PENDING',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD97706))),
                  ),
                  const Spacer(),
                  Text(_fmtDate(createdAt),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.directions_bus_outlined,
                        size: 14, color: AppColors.mutedText),
                    const SizedBox(width: 6),
                    Text(vehicle,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.navy)),
                    const SizedBox(width: 8),
                    Text('· $position',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.person_outline,
                        size: 13, color: AppColors.mutedText),
                    const SizedBox(width: 4),
                    Text('Requested by $by',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                  ]),
                  if (notes != null) ...[
                    const SizedBox(height: 4),
                    Text('Notes: $notes',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                  ],
                  const SizedBox(height: 10),
                  Row(children: [
                    const Spacer(),
                    Text('Tap to Approve / Reject',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios,
                        size: 10, color: AppColors.navy),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const m = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${m[d.month]}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Tire Approve / Reject Sheet ───────────────────────────────────────────────
class _TireApproveRejectSheet extends StatefulWidget {
  final Map<String, dynamic> request;
  final StoreKeeperRequestsController controller;
  const _TireApproveRejectSheet(
      {required this.request, required this.controller});

  @override
  State<_TireApproveRejectSheet> createState() =>
      _TireApproveRejectSheetState();
}

class _TireApproveRejectSheetState extends State<_TireApproveRejectSheet> {
  bool _isApprove  = true;
  bool _submitting = false;
  String? _error;

  Map<String, dynamic>? _selectedTire;
  final _kmCtrl     = TextEditingController();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _kmCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _submitting = true; _error = null; });
    final id = widget.request['id'] as int? ?? 0;
    bool ok;

    if (_isApprove) {
      if (_selectedTire == null) {
        setState(() {
          _submitting = false;
          _error = 'Please select a tire to issue';
        });
        return;
      }
      final km = double.tryParse(_kmCtrl.text.trim());
      ok = await widget.controller.approveTireRequest(
        id, _selectedTire!['id'] as int, fittedAtKm: km);
    } else {
      final reason = _reasonCtrl.text.trim();
      if (reason.isEmpty) {
        setState(() {
          _submitting = false;
          _error = 'Please provide a rejection reason';
        });
        return;
      }
      ok = await widget.controller.rejectTireRequest(id, reason);
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.of(context).pop();
      Get.snackbar(
        'Done',
        _isApprove ? 'Tire issued and fitted' : 'Request rejected',
        backgroundColor:
            _isApprove ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } else {
      setState(() => _error = 'Failed to process. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle  = widget.request['vehicleRegistrationNumber'] as String? ?? '—';
    final position = widget.request['positionCode']              as String? ?? '—';
    final by       = widget.request['requestedByName']           as String? ?? '—';

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$vehicle · $position',
                            style: AppTextStyles.heading3
                                .copyWith(color: AppColors.navy)),
                        const SizedBox(height: 2),
                        Text('Requested by $by',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close,
                        color: AppColors.mutedText, size: 22),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline,
                              size: 16, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: AppTextStyles.caption
                                    .copyWith(color: const Color(0xFFDC2626))),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Approve / Reject toggle
                    Container(
                      decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                                () { _isApprove = true; _error = null; }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isApprove
                                    ? const Color(0xFF16A34A)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 16,
                                      color: _isApprove
                                          ? Colors.white
                                          : AppColors.mutedText),
                                  const SizedBox(width: 6),
                                  Text('Approve',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                          color: _isApprove
                                              ? Colors.white
                                              : AppColors.mutedText)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                                () { _isApprove = false; _error = null; }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isApprove
                                    ? const Color(0xFFDC2626)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cancel_outlined,
                                      size: 16,
                                      color: !_isApprove
                                          ? Colors.white
                                          : AppColors.mutedText),
                                  const SizedBox(width: 6),
                                  Text('Reject',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                          color: !_isApprove
                                              ? Colors.white
                                              : AppColors.mutedText)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Approve fields
                    if (_isApprove) ...[
                      Obx(() => FerosSelectField<Map<String, dynamic>>(
                        label: 'Select Tire to Issue *',
                        title: 'Available Tires',
                        hint: 'Search by serial number…',
                        isRequired: true,
                        selectedDisplay: _selectedTire != null
                            ? '${_selectedTire!['serialNumber']}'
                              '${_selectedTire!['brand'] != null ? ' · ${_selectedTire!['brand']}' : ''}'
                            : null,
                        items: widget.controller.availableTires,
                        itemLabel: (t) =>
                            '${t['serialNumber'] ?? ''}'
                            '${t['brand'] != null ? ' · ${t['brand']}' : ''}'
                            '${t['size'] != null ? ' (${t['size']})' : ''}',
                        onSelected: (t) => setState(() => _selectedTire = t),
                        isLoading: widget.controller.isLoadingAvailTires.value,
                        emptyMessage: 'No tires available in stock',
                      )),
                      const SizedBox(height: 14),
                      Text('Fitted at Km (optional)',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _kmCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d*'))
                        ],
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.navy),
                        decoration: InputDecoration(
                          hintText: 'e.g. 45000',
                          suffixText: 'km',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.navy)),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                      ),
                    ],

                    // Reject fields
                    if (!_isApprove) ...[
                      Text('Rejection Reason *',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _reasonCtrl,
                        maxLines: 3,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.navy),
                        decoration: InputDecoration(
                          hintText: 'e.g. Wrong size requested…',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Color(0xFFDC2626))),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isApprove
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                _isApprove
                                    ? 'Approve & Issue Tire'
                                    : 'Reject Request',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Spare Part Request Card ───────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onTap;
  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final partName    = request['partName']        as String? ?? '—';
    final requestedQty= (request['requestedQuantity'] as num? ?? 0).toInt();
    final requestedBy = request['requestedByName']  as String?;
    final vehicleNo   = request['vehicleNumber']    as String?;
    final serviceName = request['serviceTaskName']  as String?;
    final createdAt   = request['createdAt']        as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBEB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('PENDING',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD97706))),
                  ),
                  const Spacer(),
                  Text(_formatDate(createdAt),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(partName,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.navy),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('$requestedQty units',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (vehicleNo != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.directions_bus_outlined,
                            size: 13, color: AppColors.mutedText),
                        const SizedBox(width: 4),
                        Text(vehicleNo,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                        if (serviceName != null) ...[
                          const SizedBox(width: 8),
                          Container(width: 3, height: 3,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.border)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(serviceName,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.mutedText),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (requestedBy != null)
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 13, color: AppColors.mutedText),
                        const SizedBox(width: 4),
                        Text('Requested by $requestedBy',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                      ],
                    ),
                  const SizedBox(height: 10),
                  // Action hint
                  Row(
                    children: [
                      const Spacer(),
                      Text('Tap to Approve / Reject',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios,
                          size: 10, color: AppColors.navy),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month]}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Approve / Reject Sheet ────────────────────────────────────────────────────
class _ApproveRejectSheet extends StatefulWidget {
  final Map<String, dynamic> request;
  final StoreKeeperRequestsController controller;
  const _ApproveRejectSheet({required this.request, required this.controller});

  @override
  State<_ApproveRejectSheet> createState() => _ApproveRejectSheetState();
}

class _ApproveRejectSheetState extends State<_ApproveRejectSheet> {
  bool _isApprove     = true;
  bool _submitting    = false;
  String? _error;

  late final TextEditingController _qtyCtrl;
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final requested = (widget.request['requestedQuantity'] as num? ?? 1).toInt();
    _qtyCtrl = TextEditingController(text: '$requested');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = widget.request['servicePartId'] as int? ?? 0;
    setState(() { _submitting = true; _error = null; });

    bool ok;
    String successMsg;

    if (_isApprove) {
      final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
      if (qty < 1) {
        setState(() { _submitting = false; _error = 'Quantity must be at least 1'; });
        return;
      }
      ok = await widget.controller.approveRequest(id, qty);
      successMsg = 'Approved — $qty units issued';
    } else {
      final reason = _reasonCtrl.text.trim();
      if (reason.isEmpty) {
        setState(() { _submitting = false; _error = 'Please provide a rejection reason'; });
        return;
      }
      ok = await widget.controller.rejectRequest(id, reason);
      successMsg = 'Request rejected';
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop();
      Get.snackbar(
        'Done', successMsg,
        backgroundColor: _isApprove
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } else {
      setState(() => _error = 'Failed to process request. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final partName     = widget.request['partName']            as String? ?? '—';
    final requestedQty = (widget.request['requestedQuantity'] as num? ?? 0).toInt();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partName,
                            style: AppTextStyles.heading3
                                .copyWith(color: AppColors.navy),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('Requested: $requestedQty units',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close,
                        color: AppColors.mutedText, size: 22),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error banner
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: AppTextStyles.caption.copyWith(
                                      color: const Color(0xFFDC2626))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Approve / Reject toggle
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() { _isApprove = true; _error = null; }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isApprove
                                      ? const Color(0xFF16A34A)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        size: 16,
                                        color: _isApprove
                                            ? Colors.white
                                            : AppColors.mutedText),
                                    const SizedBox(width: 6),
                                    Text('Approve',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                            color: _isApprove
                                                ? Colors.white
                                                : AppColors.mutedText,
                                            fontWeight: _isApprove
                                                ? FontWeight.w600
                                                : FontWeight.w400)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() { _isApprove = false; _error = null; }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isApprove
                                      ? const Color(0xFFDC2626)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cancel_outlined,
                                        size: 16,
                                        color: !_isApprove
                                            ? Colors.white
                                            : AppColors.mutedText),
                                    const SizedBox(width: 6),
                                    Text('Reject',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                            color: !_isApprove
                                                ? Colors.white
                                                : AppColors.mutedText,
                                            fontWeight: !_isApprove
                                                ? FontWeight.w600
                                                : FontWeight.w400)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Approve fields
                    if (_isApprove) ...[
                      Text('Quantity to Approve',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.body.copyWith(color: AppColors.navy),
                        decoration: InputDecoration(
                          hintText: '$requestedQty',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.navy)),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                      ),
                    ],

                    // Reject fields
                    if (!_isApprove) ...[
                      Text('Rejection Reason *',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _reasonCtrl,
                        maxLines: 3,
                        style: AppTextStyles.body.copyWith(color: AppColors.navy),
                        decoration: InputDecoration(
                          hintText:
                              'e.g. Insufficient stock, please reorder first…',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFDC2626))),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isApprove
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                _isApprove ? 'Confirm Approval' : 'Confirm Rejection',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
