import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/date_utils.dart';
import '../controllers/vehicle_leases_controller.dart';

class VehicleLeaseDetailView extends GetView<VehicleLeasesController> {
  const VehicleLeaseDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final leaseId = Get.arguments as int;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchDetail(leaseId);
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          elevation: 0,
          leading: GestureDetector(
            onTap: Get.back,
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          ),
          title: Obx(() {
            final l = controller.lease.value;
            return Text(
              l != null ? l['leaseNumber'] as String? ?? 'Lease' : 'Lease',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            );
          }),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(text: 'Vehicles'),
              Tab(text: 'Sessions'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoadingDetail.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.navy));
          }
          final lease = controller.lease.value;
          if (lease == null) {
            return const Center(child: Text('Failed to load lease'));
          }
          return TabBarView(
            children: [
              _VehiclesTab(leaseId: leaseId),
              _SessionsTab(),
            ],
          );
        }),
      ),
    );
  }
}

// ── Vehicles Tab ──────────────────────────────────────────────────────────────
class _VehiclesTab extends GetView<VehicleLeasesController> {
  final int leaseId;
  const _VehiclesTab({required this.leaseId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final vs = controller.vehicles;
      if (vs.isEmpty) {
        return Center(
          child: Text('No vehicles assigned', style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: vs.length,
        itemBuilder: (_, i) => _VehicleAssignmentCard(
          assignment: vs[i],
          leaseId: leaseId,
        ),
      );
    });
  }
}

class _VehicleAssignmentCard extends GetView<VehicleLeasesController> {
  final Map<String, dynamic> assignment;
  final int leaseId;
  const _VehicleAssignmentCard({required this.assignment, required this.leaseId});

  @override
  Widget build(BuildContext context) {
    final assignmentId   = (assignment['id'] as num).toInt();
    final isActive       = assignment['isActive'] as bool? ?? false;
    final regNo          = assignment['registrationNumber'] as String? ?? '—';
    final driverName     = assignment['driverName'] as String?;
    final vehicleType    = assignment['vehicleType'] as String?;
    final rate           = (assignment['ratePerVehicle'] as num?)?.toDouble() ?? 0;
    final rateTypeRaw    = controller.lease.value?['rateType'] as String? ?? '';
    final divisionName   = assignment['divisionName'] as String?;

    return Obx(() {
      final activeSession = controller.activeSessionFor(assignmentId);
      final hasActive     = activeSession != null;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasActive ? const Color(0xFF166534) : AppColors.border,
            width: hasActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Vehicle header ───────────────────────────────────
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    regNo,
                    style: AppTextStyles.bodySemiBold.copyWith(color: AppColors.bodyText),
                  ),
                ),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Closed',
                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                    ),
                  ),
                if (hasActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active session',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF166534),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (vehicleType != null)
              Text(vehicleType, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
            if (driverName != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 13, color: AppColors.mutedText),
                  const SizedBox(width: 4),
                  Text(driverName, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '₹${_fmt(rate)} / ${_rateLabel(rateTypeRaw)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
            if (divisionName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_city_outlined, size: 13, color: AppColors.mutedText),
                  const SizedBox(width: 4),
                  Text(divisionName, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
                ],
              ),
            ],
            if (isActive) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showAssignDivisionSheet(context, assignmentId),
                child: Text(
                  divisionName != null ? 'Change Division' : 'Assign Division',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
            if (hasActive) ...[
              const SizedBox(height: 4),
              Text(
                'Started: ${FerosDateUtils.formatDateTime(activeSession['startTime'] as String?)}',
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
              ),
            ],
            // ── Session buttons ──────────────────────────────────
            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!hasActive)
                    Expanded(
                      child: _SessionButton(
                        label: 'Start Session',
                        color: AppColors.navy,
                        onTap: () => _showStartDialog(context, assignmentId),
                      ),
                    ),
                  if (hasActive)
                    Expanded(
                      child: _SessionButton(
                        label: 'End Session',
                        color: const Color(0xFFDC2626),
                        onTap: () => _showEndDialog(
                          context,
                          assignmentId,
                          activeSession['odometerStart'],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  void _showStartDialog(BuildContext context, int assignmentId) {
    final odmCtrl   = TextEditingController();
    final notesCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionBottomSheet(
        title: 'Start Session',
        regNo: assignment['registrationNumber'] as String? ?? '',
        odmCtrl: odmCtrl,
        notesCtrl: notesCtrl,
        actionLabel: 'Start',
        actionColor: AppColors.navy,
        onSubmit: () async {
          final odm = int.tryParse(odmCtrl.text.trim());
          await controller.startSession(
            leaseId, assignmentId,
            odometerStart: odm,
            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          );
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEndDialog(BuildContext context, int assignmentId, dynamic odmStart) {
    final odmCtrl   = TextEditingController(
      text: odmStart != null ? odmStart.toString() : '',
    );
    final notesCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionBottomSheet(
        title: 'End Session',
        regNo: assignment['registrationNumber'] as String? ?? '',
        odmCtrl: odmCtrl,
        notesCtrl: notesCtrl,
        actionLabel: 'End Session',
        actionColor: const Color(0xFFDC2626),
        onSubmit: () async {
          final odm = int.tryParse(odmCtrl.text.trim());
          await controller.endSession(
            leaseId, assignmentId,
            odometerEnd: odm,
            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          );
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showAssignDivisionSheet(BuildContext context, int assignmentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignDivisionSheet(
        leaseId: leaseId,
        assignmentId: assignmentId,
        currentDivisionId: assignment['divisionId'] as int?,
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  String _rateLabel(String rt) => switch (rt) {
        'PER_TRIP'  => 'trip',
        'PER_TON'   => 'ton',
        'PER_KM'    => 'km',
        'PER_MONTH' => 'month',
        'PER_DAY'   => 'day',
        _           => rt.toLowerCase(),
      };
}

// ── Sessions Tab ──────────────────────────────────────────────────────────────
class _SessionsTab extends GetView<VehicleLeasesController> {
  const _SessionsTab();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ss = controller.sessions;
      if (ss.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history, size: 44, color: AppColors.mutedText),
              const SizedBox(height: 10),
              Text('No sessions yet', style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: ss.length,
        itemBuilder: (_, i) => _SessionCard(session: ss[i]),
      );
    });
  }
}

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final isActive = session['isActive'] as bool? ?? false;
    final regNo    = session['registrationNumber'] as String? ?? '—';
    final driver   = session['driverName'] as String?;
    final division = session['divisionName'] as String?;
    final km       = (session['kmDriven'] as num?)?.toDouble();
    final hrs      = (session['hoursWorked'] as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? const Color(0xFF166534) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(regNo, style: AppTextStyles.bodySemiBold.copyWith(color: AppColors.bodyText)),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Active', style: AppTextStyles.caption.copyWith(color: const Color(0xFF166534), fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _Row(Icons.play_circle_outline, 'Start', FerosDateUtils.formatDateTime(session['startTime'] as String?)),
          if (session['endTime'] != null)
            _Row(Icons.stop_circle_outlined, 'End', FerosDateUtils.formatDateTime(session['endTime'] as String?)),
          if (driver != null)
            _Row(Icons.person_outline, 'Driver', driver),
          if (division != null)
            _Row(Icons.location_city_outlined, 'Division', division),
          if (km != null)
            _Row(Icons.route_outlined, 'Distance', '${km.toStringAsFixed(0)} km'),
          if (hrs != null)
            _Row(Icons.access_time_outlined, 'Hours', '${hrs.toStringAsFixed(1)} hrs'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.mutedText),
          const SizedBox(width: 5),
          Text('$label: ', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          Expanded(
            child: Text(value, style: AppTextStyles.caption.copyWith(color: AppColors.bodyText)),
          ),
        ],
      ),
    );
  }
}

// ── Session Button ────────────────────────────────────────────────────────────
class _SessionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SessionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Session Bottom Sheet ──────────────────────────────────────────────────────
class _SessionBottomSheet extends GetView<VehicleLeasesController> {
  final String title;
  final String regNo;
  final TextEditingController odmCtrl;
  final TextEditingController notesCtrl;
  final String actionLabel;
  final Color actionColor;
  final Future<void> Function() onSubmit;

  const _SessionBottomSheet({
    required this.title,
    required this.regNo,
    required this.odmCtrl,
    required this.notesCtrl,
    required this.actionLabel,
    required this.actionColor,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.heading3.copyWith(color: AppColors.bodyText)),
          Text(regNo, style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 16),
          _Field(controller: odmCtrl, label: 'Odometer (km)', hint: 'Optional', keyboard: TextInputType.number),
          const SizedBox(height: 12),
          _Field(controller: notesCtrl, label: 'Notes', hint: 'Optional'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Obx(() => ElevatedButton(
              onPressed: controller.isActioning.value ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: controller.isActioning.value
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(actionLabel, style: AppTextStyles.bodySemiBold.copyWith(color: Colors.white)),
            )),
          ),
        ],
      ),
    );
  }
}

// ── Assign Division Sheet ─────────────────────────────────────────────────────
class _AssignDivisionSheet extends StatefulWidget {
  final int leaseId;
  final int assignmentId;
  final int? currentDivisionId;

  const _AssignDivisionSheet({
    required this.leaseId,
    required this.assignmentId,
    required this.currentDivisionId,
  });

  @override
  State<_AssignDivisionSheet> createState() => _AssignDivisionSheetState();
}

class _AssignDivisionSheetState extends State<_AssignDivisionSheet> {
  final _ctrl = Get.find<VehicleLeasesController>();
  late int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentDivisionId;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Assign Division', style: AppTextStyles.heading3.copyWith(color: AppColors.bodyText)),
          const SizedBox(height: 4),
          Text('Select a division / site for this vehicle', style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 16),
          Obx(() {
            final divs = _ctrl.divisions;
            if (divs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No divisions set up for this client.', style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
              );
            }
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedId,
                  isExpanded: true,
                  hint: Text('Select division', style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('— None —', style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
                    ),
                    ...divs.map((d) => DropdownMenuItem<int?>(
                      value: (d['id'] as num).toInt(),
                      child: Text(d['name'] as String? ?? '', style: AppTextStyles.body.copyWith(color: AppColors.bodyText)),
                    )),
                  ],
                  onChanged: (v) => setState(() => _selectedId = v),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Obx(() => ElevatedButton(
              onPressed: _ctrl.isActioning.value
                  ? null
                  : () async {
                      await _ctrl.assignDivision(widget.leaseId, widget.assignmentId, _selectedId);
                      await _ctrl.fetchDetail(widget.leaseId);
                      if (context.mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _ctrl.isActioning.value
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Confirm', style: AppTextStyles.bodySemiBold.copyWith(color: Colors.white)),
            )),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboard;
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.bodyText, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: AppTextStyles.body.copyWith(color: AppColors.bodyText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
