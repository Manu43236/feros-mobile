import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/utils/date_utils.dart';
import '../controllers/supervisor_vehicle_detail_controller.dart';

class SupervisorVehicleDetailView
    extends GetView<SupervisorVehicleDetailController> {
  const SupervisorVehicleDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.state.value == ViewState.loading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
                child: CircularProgressIndicator(color: AppColors.navy)),
          );
        }
        if (controller.state.value == ViewState.error) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('Failed to load vehicle',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.mutedText)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.fetchVehicle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final v = controller.vehicle.value!;
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                _VehicleBanner(vehicle: v),
                Container(
                  color: AppColors.surface,
                  child: const TabBar(
                    labelColor: AppColors.navy,
                    unselectedLabelColor: AppColors.mutedText,
                    indicatorColor: AppColors.navy,
                    indicatorWeight: 2.5,
                    labelStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(text: 'Basic Info'),
                      Tab(text: 'Compliance'),
                      Tab(text: 'GPS & Notes'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _BasicInfoTab(v: v),
                      _ComplianceTab(v: v),
                      _GpsNotesTab(v: v),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Banner ────────────────────────────────────────────────────────────────────
class _VehicleBanner extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  const _VehicleBanner({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final reg        = vehicle['registrationNumber'] as String? ?? '—';
    final type       = vehicle['vehicleTypeName']    as String?;
    final brand      = vehicle['brandName']          as String?;
    final statusName = vehicle['currentStatusName']  as String?;
    final statusType = vehicle['currentStatusType']  as String? ?? '';
    final capacity   = vehicle['capacityInTons'];
    final fuel       = vehicle['fuelTypeName']       as String?;
    final isActive   = vehicle['active']             as bool? ?? true;

    final (statusColor, statusBg) = _statusColors(statusType);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF0F2137)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + status row
              Row(
                children: [
                  GestureDetector(
                    onTap: Get.back,
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Vehicle Detail',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (statusName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        statusName,
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Reg number as hero
              Text(
                reg,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
              if (brand != null || type != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    [brand, type].where((s) => s != null).join(' · '),
                    style: AppTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
              const SizedBox(height: 14),

              // Chips row
              Row(
                children: [
                  if (capacity != null)
                    _BannerChip(
                        icon: Icons.scale_outlined,
                        label: '${capacity}T'),
                  if (fuel != null)
                    _BannerChip(
                        icon: Icons.local_gas_station_outlined,
                        label: fuel),
                  if (!isActive)
                    _BannerChip(
                        icon: Icons.block_outlined,
                        label: 'Inactive',
                        color: const Color(0xFFF87171)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (Color, Color) _statusColors(String type) {
    switch (type) {
      case 'AVAILABLE':  return (const Color(0xFF4ADE80), const Color(0xFF4ADE80).withValues(alpha: 0.15));
      case 'ASSIGNED':   return (const Color(0xFF60A5FA), const Color(0xFF60A5FA).withValues(alpha: 0.15));
      case 'ON_TRIP':    return (const Color(0xFFFB923C), const Color(0xFFFB923C).withValues(alpha: 0.15));
      case 'IN_REPAIR':  return (const Color(0xFFFCD34D), const Color(0xFFFCD34D).withValues(alpha: 0.15));
      case 'BREAKDOWN':  return (const Color(0xFFF87171), const Color(0xFFF87171).withValues(alpha: 0.15));
      default:           return (Colors.white70, Colors.white.withValues(alpha: 0.1));
    }
  }
}

class _BannerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _BannerChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white.withValues(alpha: 0.85);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Basic Info Tab ────────────────────────────────────────────────────────────
class _BasicInfoTab extends StatelessWidget {
  final Map<String, dynamic> v;
  const _BasicInfoTab({required this.v});

  @override
  Widget build(BuildContext context) {
    final ownership    = v['ownershipTypeName']  as String? ?? '';
    final isHired      = !ownership.toUpperCase().contains('OWN');
    final ownerName    = v['ownerName']          as String?;
    final ownerPhone   = v['ownerPhone']         as String?;
    final ownerAddress = v['ownerAddress']       as String?;
    final ownerPan     = v['ownerPan']           as String?;
    final agreStart    = v['agreementStartDate'] as String?;
    final agreEnd      = v['agreementEndDate']   as String?;
    final agreAmt      = v['agreementAmount'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _Section(
          title: 'General',
          children: [
            _InfoRow('Vehicle Type',    v['vehicleTypeName']),
            _InfoRow('Brand',           v['brandName']),
            _InfoRow('Fuel Type',       v['fuelTypeName']),
            _InfoRow('Ownership',       ownership.isEmpty ? null : ownership),
            _InfoRow('Capacity',        v['capacityInTons'] != null ? '${v['capacityInTons']} Tons' : null),
            _InfoRow('Manufacture Year',v['manufactureYear']?.toString()),
            _InfoRow('Color',           v['color']),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Chassis & Engine',
          children: [
            _InfoRow('Chassis Number', v['chassisNumber']),
            _InfoRow('Engine Number',  v['engineNumber']),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Operations',
          children: [
            _InfoRow('Odometer',         v['currentOdometerReading'] != null ? '${v['currentOdometerReading']} km' : null),
            _InfoRow('Fuel Tank',        v['fuelTankCapacity'] != null ? '${v['fuelTankCapacity']} L' : null),
            _InfoRow('Current Fuel',     v['currentFuelLevel'] != null ? '${v['currentFuelLevel']} L' : null),
            _InfoRow('Tyre Rotation',    v['tyreRotationIntervalKm'] != null ? '${v['tyreRotationIntervalKm']} km' : null),
          ],
        ),
        if (isHired && (ownerName != null || ownerPhone != null)) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'Owner / Agreement',
            children: [
              _InfoRow('Owner Name',       ownerName),
              _InfoRow('Owner Phone',      ownerPhone),
              _InfoRow('Owner Address',    ownerAddress),
              _InfoRow('PAN',              ownerPan),
              _InfoRow('Agreement Start',  agreStart != null ? FerosDateUtils.formatDate(agreStart) : null),
              _InfoRow('Agreement End',    agreEnd   != null ? FerosDateUtils.formatDate(agreEnd)   : null),
              _InfoRow('Agreement Amount', agreAmt   != null ? '₹${agreAmt}' : null),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Compliance Tab ────────────────────────────────────────────────────────────
class _ComplianceTab extends StatelessWidget {
  final Map<String, dynamic> v;
  const _ComplianceTab({required this.v});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _ComplianceCard(
          label: 'RC (Registration Certificate)',
          docNumber: v['rcNumber'] as String?,
          expiryDate: v['rcExpiryDate'] as String?,
        ),
        const SizedBox(height: 10),
        _ComplianceCard(
          label: 'Insurance',
          docNumber: v['insurancePolicyNumber'] as String?,
          subInfo: v['insuranceCompanyName'] as String?,
          startDate: v['insuranceStartDate'] as String?,
          expiryDate: v['insuranceExpiryDate'] as String?,
        ),
        const SizedBox(height: 10),
        _ComplianceCard(
          label: 'Permit',
          docNumber: v['permitNumber'] as String?,
          subInfo: v['permitType'] as String?,
          startDate: v['permitStartDate'] as String?,
          expiryDate: v['permitExpiryDate'] as String?,
        ),
        const SizedBox(height: 10),
        _ComplianceCard(
          label: 'Fitness Certificate',
          docNumber: v['fitnessCertificateNumber'] as String?,
          expiryDate: v['fitnessExpiryDate'] as String?,
        ),
        const SizedBox(height: 10),
        _ComplianceCard(
          label: 'PUC (Pollution Under Control)',
          docNumber: v['pucNumber'] as String?,
          expiryDate: v['pollutionExpiryDate'] as String?,
        ),
        const SizedBox(height: 10),
        _ComplianceCard(
          label: 'Road Tax',
          startDate: v['roadTaxPaidDate'] as String?,
          expiryDate: v['roadTaxExpiryDate'] as String?,
        ),
      ],
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  final String label;
  final String? docNumber;
  final String? subInfo;
  final String? startDate;
  final String? expiryDate;
  const _ComplianceCard({
    required this.label,
    this.docNumber,
    this.subInfo,
    this.startDate,
    this.expiryDate,
  });

  @override
  Widget build(BuildContext context) {
    final status = _expiryStatus(expiryDate);
    final (bg, fg, icon, statusText) = _statusStyle(status, expiryDate);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 11, color: fg),
                      const SizedBox(width: 4),
                      Text(statusText,
                          style: AppTextStyles.caption.copyWith(
                              color: fg, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (docNumber != null)
                  _InfoRow('Number', docNumber),
                if (subInfo != null)
                  _InfoRow('Details', subInfo),
                if (startDate != null)
                  _InfoRow('Start Date',
                      FerosDateUtils.formatDate(startDate!)),
                _InfoRow(
                  'Expiry Date',
                  expiryDate != null
                      ? FerosDateUtils.formatDate(expiryDate!)
                      : '—',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static _ExpiryStatus _expiryStatus(String? dateStr) {
    if (dateStr == null) return _ExpiryStatus.none;
    try {
      final d = DateTime.parse(dateStr);
      final days = d.difference(DateTime.now()).inDays;
      if (days < 0)   return _ExpiryStatus.expired;
      if (days <= 7)  return _ExpiryStatus.critical;
      if (days <= 30) return _ExpiryStatus.warning;
      return _ExpiryStatus.ok;
    } catch (_) {
      return _ExpiryStatus.none;
    }
  }

  static (Color, Color, IconData, String) _statusStyle(
      _ExpiryStatus s, String? dateStr) {
    int days = 0;
    if (dateStr != null) {
      try {
        days = DateTime.parse(dateStr).difference(DateTime.now()).inDays;
      } catch (_) {}
    }
    switch (s) {
      case _ExpiryStatus.expired:
        return (
          const Color(0xFFFEE2E2),
          const Color(0xFFDC2626),
          Icons.warning_amber_rounded,
          'Expired ${days.abs()}d ago',
        );
      case _ExpiryStatus.critical:
        return (
          const Color(0xFFFFF7ED),
          const Color(0xFFEA580C),
          Icons.warning_amber_rounded,
          '${days}d left',
        );
      case _ExpiryStatus.warning:
        return (
          const Color(0xFFFFFBEB),
          const Color(0xFFD97706),
          Icons.schedule_outlined,
          '${days}d left',
        );
      case _ExpiryStatus.ok:
        return (
          const Color(0xFFF0FDF4),
          const Color(0xFF16A34A),
          Icons.check_circle_outline,
          'Valid · ${days}d',
        );
      case _ExpiryStatus.none:
        return (
          const Color(0xFFF9FAFB),
          AppColors.mutedText,
          Icons.remove_circle_outline,
          'Not recorded',
        );
    }
  }
}

enum _ExpiryStatus { expired, critical, warning, ok, none }

// ── GPS & Notes Tab ───────────────────────────────────────────────────────────
class _GpsNotesTab extends StatelessWidget {
  final Map<String, dynamic> v;
  const _GpsNotesTab({required this.v});

  @override
  Widget build(BuildContext context) {
    final notes = v['notes'] as String?;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _Section(
          title: 'GPS Device',
          children: [
            _InfoRow('Device Number', v['gpsDeviceNumber']),
            _InfoRow('IMEI',          v['gpsDeviceImei']),
            _InfoRow('Provider',      v['gpsProvider']),
          ],
        ),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'Notes',
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  notes,
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.bodyText),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              title.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontSize: 10,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final dynamic value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ),
          Expanded(
            child: Text(
              value?.toString().isNotEmpty == true ? value.toString() : '—',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.bodyText, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
