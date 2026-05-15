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
    return Obx(() {
      if (controller.vehicleState.value == ViewState.loading) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator(color: AppColors.navy)),
        );
      }
      if (controller.vehicleState.value == ViewState.error) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Failed to load vehicle',
                    style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.retryVehicle,
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

      final v          = controller.vehicle.value!;
      final alertCount = _complianceAlertCount(v);

      return DefaultTabController(
        length: 6,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _VehicleBanner(vehicle: v, alertCount: alertCount),
              Container(
                color: AppColors.surface,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.navy,
                  unselectedLabelColor: AppColors.mutedText,
                  indicatorColor: AppColors.navy,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                  ),
                  tabs: [
                    const Tab(
                      icon: Icon(Icons.directions_car_outlined, size: 15),
                      text: 'Basic Info',
                      iconMargin: EdgeInsets.only(bottom: 2),
                    ),
                    Tab(
                      iconMargin: const EdgeInsets.only(bottom: 2),
                      icon: alertCount > 0
                          ? Badge.count(
                              count: alertCount,
                              backgroundColor: const Color(0xFFDC2626),
                              textStyle: const TextStyle(
                                  fontSize: 9, fontFamily: 'Inter'),
                              child: const Icon(Icons.shield_outlined, size: 15),
                            )
                          : const Icon(Icons.shield_outlined, size: 15),
                      text: 'Compliance',
                    ),
                    const Tab(
                      icon: Icon(Icons.build_outlined, size: 15),
                      text: 'Service',
                      iconMargin: EdgeInsets.only(bottom: 2),
                    ),
                    const Tab(
                      icon: Icon(Icons.local_gas_station_outlined, size: 15),
                      text: 'Fuel',
                      iconMargin: EdgeInsets.only(bottom: 2),
                    ),
                    const Tab(
                      icon: Icon(Icons.speed_outlined, size: 15),
                      text: 'Meter',
                      iconMargin: EdgeInsets.only(bottom: 2),
                    ),
                    const Tab(
                      icon: Icon(Icons.gps_fixed, size: 15),
                      text: 'GPS & Notes',
                      iconMargin: EdgeInsets.only(bottom: 2),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _BasicInfoTab(v: v),
                    _ComplianceTab(v: v),
                    _ServiceTabBody(controller: controller),
                    _FuelTabBody(controller: controller),
                    _MeterTabBody(controller: controller),
                    _GpsNotesTab(v: v),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  static int _complianceAlertCount(Map<String, dynamic> v) {
    int count = 0;
    for (final d in [
      v['rcExpiryDate'], v['insuranceExpiryDate'], v['permitExpiryDate'],
      v['fitnessExpiryDate'], v['pollutionExpiryDate'], v['roadTaxExpiryDate'],
    ]) {
      if (d == null) continue;
      try {
        if (DateTime.parse(d as String).difference(DateTime.now()).inDays <= 7) {
          count++;
        }
      } catch (_) {}
    }
    return count;
  }
}

// ── Banner ─────────────────────────────────────────────────────────────────────
class _VehicleBanner extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final int alertCount;
  const _VehicleBanner({required this.vehicle, required this.alertCount});

  @override
  Widget build(BuildContext context) {
    final reg        = vehicle['registrationNumber'] as String? ?? '—';
    final type       = vehicle['vehicleTypeName']    as String?;
    final brand      = vehicle['brandName']          as String?;
    final statusName = vehicle['currentStatusName']  as String?;
    final statusType = vehicle['currentStatusType']  as String? ?? '';
    final capacity   = vehicle['capacityInTons'];
    final fuel       = vehicle['fuelTypeName']       as String?;
    final ownership  = vehicle['ownershipTypeName']  as String?;
    final odometer   = vehicle['currentOdometerReading'];
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
        child: Stack(
          children: [
            Positioned(
              right: -10, top: 0, bottom: 0,
              child: const Opacity(
                opacity: 0.05,
                child: Icon(Icons.local_shipping, size: 160, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    children: [
                      IconButton(
                        onPressed: Get.back,
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      const Spacer(),
                      if (!isActive)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.4)),
                          ),
                          child: const Text('Inactive',
                              style: TextStyle(
                                color: Color(0xFFFCA5A5),
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      if (statusName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(statusName,
                              style: TextStyle(
                                color: statusColor,
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Registration + alert
                  Row(
                    children: [
                      Flexible(
                        child: Text(reg,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w800,
                              fontSize: 26,
                              letterSpacing: 1.5,
                            )),
                      ),
                      if (alertCount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: 11, color: Color(0xFFFCA5A5)),
                              const SizedBox(width: 4),
                              Text(
                                '$alertCount alert${alertCount != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: Color(0xFFFCA5A5),
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (brand != null || type != null || fuel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        [brand, type, fuel]
                            .where((s) => s != null)
                            .join(' · '),
                        style: const TextStyle(
                          color: Color(0xFF93C5FD),
                          fontFamily: 'Inter',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Quick stats grid
                  Row(
                    children: [
                      _StatCard(label: 'Type',      value: type      ?? '—'),
                      const SizedBox(width: 8),
                      _StatCard(label: 'Capacity',  value: capacity != null ? '$capacity T' : '—'),
                      const SizedBox(width: 8),
                      _StatCard(label: 'Ownership', value: ownership ?? '—'),
                      const SizedBox(width: 8),
                      _StatCard(label: 'Odometer',  value: odometer != null ? '$odometer km' : '—'),
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

  static (Color, Color) _statusColors(String type) {
    switch (type) {
      case 'AVAILABLE': return (const Color(0xFF4ADE80), const Color(0xFF4ADE80).withValues(alpha: 0.15));
      case 'ASSIGNED':  return (const Color(0xFF60A5FA), const Color(0xFF60A5FA).withValues(alpha: 0.15));
      case 'ON_TRIP':   return (const Color(0xFFFB923C), const Color(0xFFFB923C).withValues(alpha: 0.15));
      case 'IN_REPAIR': return (const Color(0xFFFCD34D), const Color(0xFFFCD34D).withValues(alpha: 0.15));
      case 'BREAKDOWN': return (const Color(0xFFF87171), const Color(0xFFF87171).withValues(alpha: 0.15));
      default:          return (Colors.white70, Colors.white.withValues(alpha: 0.1));
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                  color: Color(0xFF93C5FD),
                  fontFamily: 'Inter',
                  fontSize: 10,
                )),
            const SizedBox(height: 3),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
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
    final ownership   = v['ownershipTypeName'] as String? ?? '';
    final isHired     = ownership.isNotEmpty &&
        !ownership.toUpperCase().contains('OWN');
    final tankCap     = v['fuelTankCapacity'];
    final currentFuel = v['currentFuelLevel'];
    final fuelPct     = (tankCap != null && currentFuel != null && (tankCap as num) > 0)
        ? ((currentFuel as num) / (tankCap as num) * 100).round().clamp(0, 100)
        : null;
    final fuelLabel   = currentFuel != null
        ? (fuelPct != null ? '$currentFuel L ($fuelPct%)' : '$currentFuel L')
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _InfoSection(title: 'Vehicle Details', rows: [
          _IR('Brand',        v['brandName']),
          _IR('Vehicle Type', v['vehicleTypeName']),
          _IR('Fuel Type',    v['fuelTypeName']),
          _IR('Ownership',    ownership.isEmpty ? null : ownership),
          _IR('Capacity',     v['capacityInTons'] != null ? '${v['capacityInTons']} Tons' : null),
          _IR('Mfg. Year',    v['manufactureYear']?.toString()),
          _IR('Color',        v['color']),
          _IR('Odometer',     v['currentOdometerReading'] != null ? '${v['currentOdometerReading']} km' : null),
          _IR('Tank Capacity',tankCap    != null ? '$tankCap L' : null),
          _IR('Current Fuel', fuelLabel),
        ]),
        const SizedBox(height: 12),
        _InfoSection(title: 'Identification', rows: [
          _IR('Chassis No.',   v['chassisNumber']),
          _IR('Engine No.',    v['engineNumber']),
          _IR('RC Number',     v['rcNumber']),
          _IR('Permit No.',    v['permitNumber']),
          _IR('Permit Type',   v['permitType']),
          _IR('PUC No.',       v['pucNumber']),
          _IR('Fitness Cert.', v['fitnessCertificateNumber']),
        ]),
        if (isHired) ...[
          const SizedBox(height: 12),
          _InfoSection(title: 'Owner / Hired Details', rows: [
            _IR('Owner Name',       v['ownerName']),
            _IR('Phone',            v['ownerPhone']),
            _IR('PAN Number',       v['ownerPan']),
            _IR('Address',          v['ownerAddress']),
            _IR('Agreement Start',  v['agreementStartDate'] != null ? FerosDateUtils.formatDate(v['agreementStartDate'] as String) : null),
            _IR('Agreement End',    v['agreementEndDate']   != null ? FerosDateUtils.formatDate(v['agreementEndDate']   as String) : null),
            _IR('Agreement Amount', v['agreementAmount'] != null ? '₹${v['agreementAmount']}' : null),
          ]),
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
    final items = [
      _CI('Registration Certificate (RC)', v['rcNumber']   as String?, null,                          v['rcExpiryDate']          as String?),
      _CI('Insurance',                     v['insurancePolicyNumber'] as String?, v['insuranceCompanyName'] as String?, v['insuranceExpiryDate']   as String?),
      _CI('Permit',                        _permitLabel(v),              null,                          v['permitExpiryDate']      as String?),
      _CI('Fitness Certificate',           v['fitnessCertificateNumber'] as String?, null,             v['fitnessExpiryDate']     as String?),
      _CI('Pollution (PUC)',               v['pucNumber']  as String?, null,                           v['pollutionExpiryDate']   as String?),
      _CI('Road Tax',                      v['roadTaxPaidDate'] != null ? 'Paid: ${FerosDateUtils.formatDate(v['roadTaxPaidDate'] as String)}' : null, null, v['roadTaxExpiryDate'] as String?),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Document Status ──────────────────────────────────────────────────
        _SectionHeader('Document Status'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: items.asMap().entries.map((e) =>
              _ComplianceRow(item: e.value, isLast: e.key == items.length - 1),
            ).toList(),
          ),
        ),
        const SizedBox(height: 20),
        // ── Insurance Details ────────────────────────────────────────────────
        _SectionHeader('Insurance Details'),
        const SizedBox(height: 8),
        _InfoSection(title: '', rows: [
          _IR('Company',    v['insuranceCompanyName']),
          _IR('Policy No.', v['insurancePolicyNumber']),
          _IR('Start Date', v['insuranceStartDate'] != null ? FerosDateUtils.formatDate(v['insuranceStartDate'] as String) : null),
          _IR('Expiry Date',v['insuranceExpiryDate'] != null ? FerosDateUtils.formatDate(v['insuranceExpiryDate'] as String) : null),
        ]),
        const SizedBox(height: 20),
        // ── Permit Details ───────────────────────────────────────────────────
        _SectionHeader('Permit Details'),
        const SizedBox(height: 8),
        _InfoSection(title: '', rows: [
          _IR('Permit No.', v['permitNumber']),
          _IR('Type',       v['permitType']),
          _IR('Start Date', v['permitStartDate'] != null ? FerosDateUtils.formatDate(v['permitStartDate'] as String) : null),
          _IR('Expiry Date',v['permitExpiryDate'] != null ? FerosDateUtils.formatDate(v['permitExpiryDate'] as String) : null),
        ]),
        const SizedBox(height: 20),
        // ── Road Tax ─────────────────────────────────────────────────────────
        _SectionHeader('Road Tax'),
        const SizedBox(height: 8),
        _InfoSection(title: '', rows: [
          _IR('Paid Date',  v['roadTaxPaidDate']  != null ? FerosDateUtils.formatDate(v['roadTaxPaidDate']  as String) : null),
          _IR('Expiry Date',v['roadTaxExpiryDate'] != null ? FerosDateUtils.formatDate(v['roadTaxExpiryDate'] as String) : null),
        ]),
      ],
    );
  }

  static String? _permitLabel(Map<String, dynamic> v) {
    final num  = v['permitNumber'] as String?;
    final type = v['permitType']   as String?;
    if (num == null) return null;
    return type != null ? '$num · $type' : num;
  }
}

class _CI {
  final String label;
  final String? docNumber;
  final String? subInfo;
  final String? expiryDate;
  const _CI(this.label, this.docNumber, this.subInfo, this.expiryDate);
}

class _ComplianceRow extends StatelessWidget {
  final _CI  item;
  final bool isLast;
  const _ComplianceRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBg, statusIcon, statusText) =
        _statusStyle(item.expiryDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.bodyText)),
                if (item.docNumber != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(item.docNumber!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                  ),
                if (item.subInfo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(item.subInfo!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedText)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    'Expiry: ${item.expiryDate != null ? FerosDateUtils.formatDate(item.expiryDate!) : '—'}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 11, color: statusColor),
                const SizedBox(width: 4),
                Text(statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static (Color, Color, IconData, String) _statusStyle(String? d) {
    if (d == null) {
      return (AppColors.mutedText, const Color(0xFFF9FAFB),
          Icons.remove_circle_outline, 'Not recorded');
    }
    try {
      final days =
          DateTime.parse(d).difference(DateTime.now()).inDays;
      if (days < 0)   return (const Color(0xFFDC2626), const Color(0xFFFEE2E2), Icons.warning_amber_rounded,  'Expired ${days.abs()}d ago');
      if (days <= 7)  return (const Color(0xFFEA580C), const Color(0xFFFFF7ED), Icons.warning_amber_rounded,  '${days}d left');
      if (days <= 30) return (const Color(0xFFD97706), const Color(0xFFFFFBEB), Icons.schedule_outlined,      '${days}d left');
      return              (const Color(0xFF16A34A), const Color(0xFFF0FDF4), Icons.check_circle_outline,  'Valid · ${days}d left');
    } catch (_) {
      return (AppColors.mutedText, const Color(0xFFF9FAFB),
          Icons.remove_circle_outline, 'Not recorded');
    }
  }
}

// ── Service Tab ───────────────────────────────────────────────────────────────
class _ServiceTabBody extends StatefulWidget {
  final SupervisorVehicleDetailController controller;
  const _ServiceTabBody({required this.controller});

  @override
  State<_ServiceTabBody> createState() => _ServiceTabBodyState();
}

class _ServiceTabBodyState extends State<_ServiceTabBody>
    with AutomaticKeepAliveClientMixin {
  String _subTab = 'general';

  @override
  void initState() {
    super.initState();
    widget.controller.ensureServicesLoaded();
    widget.controller.ensureBreakdownsLoaded();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = widget.controller;

    return Column(
      children: [
        // ── Sub-tab toggle ─────────────────────────────────────────
        Obx(() {
          final openCount = c.openBreakdownCount;
          return Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                _SubTabButton(
                  label: 'General',
                  selected: _subTab == 'general',
                  onTap: () => setState(() => _subTab = 'general'),
                ),
                const SizedBox(width: 8),
                _SubTabButton(
                  label: 'Breakdowns',
                  badge: openCount,
                  selected: _subTab == 'breakdown',
                  onTap: () => setState(() => _subTab = 'breakdown'),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 1, color: AppColors.border),

        // ── Content ────────────────────────────────────────────────
        Expanded(
          child: _subTab == 'general'
              ? _GeneralServiceContent(c: c)
              : _BreakdownContent(c: c),
        ),
      ],
    );
  }
}

class _SF {
  final String key, label;
  final int count;
  const _SF(this.key, this.label, this.count);
}

// ── Sub-tab button ────────────────────────────────────────────────────────────
class _SubTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;
  const _SubTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.bodyText,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── General service content ───────────────────────────────────────────────────
class _GeneralServiceContent extends StatelessWidget {
  final SupervisorVehicleDetailController c;
  const _GeneralServiceContent({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.servicesState.value == ViewState.loading) {
        return const _TabLoading();
      }
      if (c.servicesState.value == ViewState.error) {
        return _TabError(onRetry: c.retryServices);
      }

      final filters = [
        _SF('all',         'All',         c.serviceCount('all')),
        _SF('open',        'Open',        c.serviceCount('open')),
        _SF('in_progress', 'In Progress', c.serviceCount('in_progress')),
        _SF('due_soon',    'Due Soon',    c.serviceCount('due_soon')),
        _SF('overdue',     'Overdue',     c.serviceCount('overdue')),
        _SF('completed',   'Completed',   c.serviceCount('completed')),
      ];

      final filtered = c.filteredServices;

      return Column(
        children: [
          // Filter chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 0, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final isSelected = c.serviceFilter.value == f.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => c.serviceFilter.value = f.key,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.navy : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.navy : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(f.label,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.mutedText,
                                )),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${f.count}',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.mutedText,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyTabState(
                    icon: Icons.build_outlined,
                    message: c.services.isEmpty
                        ? 'No services yet'
                        : 'No services match filter',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _ServiceCard(record: filtered[i]),
                  ),
          ),
        ],
      );
    });
  }
}

// ── Breakdown content ─────────────────────────────────────────────────────────
class _BreakdownContent extends StatelessWidget {
  final SupervisorVehicleDetailController c;
  const _BreakdownContent({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.breakdownsState.value == ViewState.loading) {
        return const _TabLoading();
      }
      if (c.breakdownsState.value == ViewState.error) {
        return _TabError(onRetry: c.retryBreakdowns);
      }
      if (c.breakdowns.isEmpty) {
        return const _EmptyTabState(
          icon: Icons.warning_amber_outlined,
          message: 'No breakdowns recorded',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: c.breakdowns.length,
        itemBuilder: (_, i) => _BreakdownCard(breakdown: c.breakdowns[i]),
      );
    });
  }
}

// ── Breakdown Card ────────────────────────────────────────────────────────────
class _BreakdownCard extends StatelessWidget {
  final Map<String, dynamic> breakdown;
  const _BreakdownCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final status   = breakdown['status'] as String? ?? '';
    final type     = breakdown['breakdownType'] as String? ?? '';
    final duration = breakdown['breakdownDuration'] as String? ?? '';
    final reason   = breakdown['reason'] as String?;
    final date     = breakdown['breakdownDate'] as String?;
    final location = breakdown['location'] as String?;
    final orderNum = breakdown['orderNumber'] as String?;

    final isResolved = status == 'RESOLVED' || status == 'VEHICLE_REPLACED';
    final isInRepair = status == 'IN_REPAIR';

    final (statusColor, statusBg, statusLabel) = isInRepair
        ? (const Color(0xFFEA580C), const Color(0xFFFFF7ED), '🔧 In Repair')
        : isResolved
            ? (const Color(0xFF16A34A), const Color(0xFFF0FDF4), '✓ Resolved')
            : (const Color(0xFFDC2626), const Color(0xFFFEF2F2), '⚠ Open');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + type + duration
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    )),
              ),
              if (type.isNotEmpty)
                _Chip(_formatBreakdownType(type)),
              if (duration.isNotEmpty)
                _Chip(duration == 'SHORT' ? 'Minor' : 'Major'),
            ],
          ),
          if (reason != null) ...[
            const SizedBox(height: 8),
            Text(reason,
                style: AppTextStyles.body.copyWith(color: AppColors.bodyText)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              if (date != null)
                _MetaChip(Icons.calendar_today_outlined,
                    FerosDateUtils.formatDate(date)),
              if (location != null)
                _MetaChip(Icons.location_on_outlined, location),
              if (orderNum != null)
                _MetaChip(Icons.receipt_outlined, 'Order: $orderNum'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small neutral chip ────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: AppColors.bodyText)),
    );
  }
}

String _formatBreakdownType(String type) {
  return type
      .split('_')
      .map((w) => w.isEmpty
          ? ''
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _ServiceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final num         = record['serviceNumber'] as String? ?? '—';
    final status      = record['displayStatus'] as String? ??
        record['status'] as String? ?? '';
    final triggeredBy = record['triggeredBy']   as String?;
    final serviceType = record['serviceType']   as String?;
    final vendor      = record['vendorName']    as String?;
    final location    = record['location']      as String?;
    final serviceDate = record['serviceDate']   as String?;
    final odometer    = record['odometer'];
    final dueAt       = record['dueAtOdometer'];
    final totalCost   = record['totalCost'];
    final tasks       = (record['tasks'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final notes       = record['notes'] as String?;

    final (statusColor, statusBg) = _statusStyle(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: service number + status + trigger + type
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(num,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mutedText,
                                fontFamily: 'monospace',
                              )),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(_statusLabel(status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                          if (triggeredBy != null)
                            _MetaBadge(_triggerLabel(triggeredBy)),
                          if (serviceType != null)
                            _MetaBadge(_typeLabel(serviceType, vendor)),
                        ],
                      ),
                    ),
                  ],
                ),
                // Tasks
                if (tasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tasks.map((t) {
                        final name = t['taskTypeName'] as String? ??
                            t['customName']  as String? ?? '—';
                        final recurring = t['isRecurring'] as bool? ?? false;
                        final freqKm    = t['frequencyKm'];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            recurring && freqKm != null
                                ? '$name · 🔄 ${freqKm}km'
                                : name,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.bodyText),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                // Meta row
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      if (dueAt != null)
                        _MetaChip(Icons.refresh_outlined,
                            'Due at $dueAt km'),
                      if (odometer != null)
                        _MetaChip(Icons.speed_outlined, '$odometer km'),
                      if (serviceDate != null)
                        _MetaChip(Icons.calendar_today_outlined,
                            FerosDateUtils.formatDate(serviceDate)),
                      if (location != null)
                        _MetaChip(Icons.location_on_outlined, location),
                      if (totalCost != null)
                        _MetaChip(Icons.currency_rupee, '₹$totalCost',
                            color: AppColors.success),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // In-progress notes
          if (notes != null && notes.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border(
                    top: BorderSide(color: AppColors.border, width: 0.8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes_outlined,
                      size: 13, color: AppColors.mutedText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(notes,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText,
                          fontStyle: FontStyle.italic,
                        )),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static (Color, Color) _statusStyle(String s) {
    switch (s) {
      case 'OPEN':        return (const Color(0xFF2563EB), const Color(0xFFEFF6FF));
      case 'IN_PROGRESS': return (const Color(0xFFEA580C), const Color(0xFFFFF7ED));
      case 'DUE_SOON':    return (const Color(0xFFD97706), const Color(0xFFFFFBEB));
      case 'OVERDUE':     return (const Color(0xFFDC2626), const Color(0xFFFEF2F2));
      case 'COMPLETED':   return (const Color(0xFF16A34A), const Color(0xFFF0FDF4));
      default:            return (AppColors.mutedText, AppColors.background);
    }
  }

  static String _statusLabel(String s) {
    const m = {
      'OPEN': 'Open', 'IN_PROGRESS': 'In Progress', 'DUE_SOON': 'Due Soon',
      'OVERDUE': 'Overdue', 'COMPLETED': 'Completed',
    };
    return m[s] ?? s;
  }

  static String _triggerLabel(String t) {
    const m = {
      'BREAKDOWN': '⚡ Breakdown', 'ACCIDENT': '💥 Accident',
      'COMPLIANCE': '📋 Compliance', 'WARRANTY': '🔒 Warranty',
      'SCHEDULED': '📅 Scheduled',
    };
    return m[t] ?? t;
  }

  static String _typeLabel(String t, String? vendor) {
    if (t == 'INTERNAL')    return '🏭 Internal';
    if (t == 'OEM_CENTER')  return '🏢 ${vendor ?? 'OEM Center'}';
    return '🔧 ${vendor ?? '3rd Party'}';
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  const _MetaBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTextStyles.caption.copyWith(color: AppColors.mutedText));
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color?   color;
  const _MetaChip(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.mutedText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: c)),
      ],
    );
  }
}

// ── Fuel Tab ──────────────────────────────────────────────────────────────────
class _FuelTabBody extends StatefulWidget {
  final SupervisorVehicleDetailController controller;
  const _FuelTabBody({required this.controller});

  @override
  State<_FuelTabBody> createState() => _FuelTabBodyState();
}

class _FuelTabBodyState extends State<_FuelTabBody>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    widget.controller.ensureFuelLoaded();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = widget.controller;

    return Obx(() {
      if (c.fuelState.value == ViewState.loading) {
        return const _TabLoading();
      }
      if (c.fuelState.value == ViewState.error) {
        return _TabError(onRetry: c.retryFuel);
      }

      final logs = c.fuelLogs;
      final v    = c.vehicle.value!;

      // Summary calculations
      final tankCap     = v['fuelTankCapacity'];
      final currentFuel = v['currentFuelLevel'];
      final fuelPct     = (tankCap != null && currentFuel != null && (tankCap as num) > 0)
          ? ((currentFuel as num) / (tankCap as num) * 100).round().clamp(0, 100)
          : null;

      final validMileage = logs
          .where((l) => l['mileageKmPerLitre'] != null)
          .toList();
      final avgMileage = validMileage.isNotEmpty
          ? (validMileage
                  .map((l) => (l['mileageKmPerLitre'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              validMileage.length)
          : null;

      final totalSpend = logs.fold<double>(0.0, (sum, l) {
        final cost = l['totalCost'];
        return sum + (cost != null ? (cost as num).toDouble() : 0.0);
      });

      if (logs.isEmpty) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _FuelSummaryCards(
              tankCap: tankCap, currentFuel: currentFuel,
              fuelPct: fuelPct, avgMileage: avgMileage,
              totalSpend: totalSpend, logCount: 0,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _SectionHeader('Fill-up History')),
                GestureDetector(
                  onTap: () => _showFuelSheet(context, c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Add Fill-up',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const _EmptyTabState(
                icon: Icons.local_gas_station_outlined,
                message: 'No fuel logs yet'),
          ],
        );
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _FuelSummaryCards(
            tankCap: tankCap, currentFuel: currentFuel,
            fuelPct: fuelPct, avgMileage: avgMileage,
            totalSpend: totalSpend, logCount: logs.length,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SectionHeader('Fill-up History')),
              GestureDetector(
                onTap: () => _showFuelSheet(context, c),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Add Fill-up',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Table card
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: const [
                      _TH('Date',     flex: 3),
                      _TH('Litres',   flex: 2),
                      _TH('Odometer', flex: 3),
                      _TH('Cost/L',   flex: 2),
                      _TH('Total',    flex: 3),
                      _TH('Mileage',  flex: 3),
                    ],
                  ),
                ),
                ...logs.asMap().entries.map((e) {
                  final log = e.value;
                  final id  = log['id'] is int
                      ? log['id'] as int
                      : int.tryParse(log['id'].toString()) ?? 0;
                  return _FuelRow(
                    log: log,
                    isLast: e.key == logs.length - 1,
                    onEdit: () => _showFuelSheet(context, c, existing: log),
                    onDelete: () => _confirmDeleteFuel(context, c, id),
                  );
                }),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _FuelSummaryCards extends StatelessWidget {
  final dynamic tankCap, currentFuel, avgMileage;
  final int? fuelPct;
  final double totalSpend;
  final int logCount;
  const _FuelSummaryCards({
    required this.tankCap, required this.currentFuel,
    required this.fuelPct, required this.avgMileage,
    required this.totalSpend, required this.logCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Tank Capacity
        Expanded(
          child: _SummaryCard(
            label: 'Tank Capacity',
            value: tankCap != null ? '$tankCap L' : '—',
            bg: const Color(0xFFEFF6FF),
            border: const Color(0xFFBFDBFE),
            labelColor: const Color(0xFF3B82F6),
            valueColor: const Color(0xFF1D4ED8),
          ),
        ),
        const SizedBox(width: 8),
        // Current Fuel with progress bar
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Fuel',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF97316),
                      letterSpacing: 0.4,
                    )),
                const SizedBox(height: 4),
                Text(currentFuel != null ? '$currentFuel L' : '—',
                    style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC2410C),
                    )),
                if (fuelPct != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fuelPct! / 100,
                      backgroundColor: const Color(0xFFFED7AA),
                      valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFFB923C)),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text('$fuelPct% full',
                      style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 10,
                        color: Color(0xFFF97316),
                      )),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Avg Mileage
        Expanded(
          child: _SummaryCard(
            label: 'Avg Mileage',
            value: avgMileage != null
                ? '${avgMileage!.toStringAsFixed(1)} km/L'
                : '—',
            sub: 'full tank fills',
            bg: const Color(0xFFF0FDF4),
            border: const Color(0xFFBBF7D0),
            labelColor: const Color(0xFF22C55E),
            valueColor: const Color(0xFF15803D),
          ),
        ),
        const SizedBox(width: 8),
        // Total Spend
        Expanded(
          child: _SummaryCard(
            label: 'Total Spend',
            value: totalSpend > 0
                ? '₹${totalSpend.toStringAsFixed(0)}'
                : '—',
            sub: '$logCount fill-up${logCount != 1 ? 's' : ''}',
            bg: const Color(0xFFFAF5FF),
            border: const Color(0xFFE9D5FF),
            labelColor: const Color(0xFFA855F7),
            valueColor: const Color(0xFF7E22CE),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final String? sub;
  final Color bg, border, labelColor, valueColor;
  const _SummaryCard({
    required this.label, required this.value,
    this.sub,
    required this.bg, required this.border,
    required this.labelColor, required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Inter', fontSize: 9,
                fontWeight: FontWeight.w600,
                color: labelColor,
                letterSpacing: 0.4,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontFamily: 'Inter', fontSize: 15,
                fontWeight: FontWeight.w700,
                color: valueColor,
              )),
          if (sub != null)
            Text(sub!,
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 9, color: labelColor)),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.mutedText,
            fontSize: 10,
            letterSpacing: 0.4,
          )),
    );
  }
}

class _FuelRow extends StatelessWidget {
  final Map<String, dynamic> log;
  final bool isLast;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _FuelRow({
    required this.log,
    required this.isLast,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date        = log['fillDate']          as String?;
    final litres      = log['litresFilled'];
    final odometer    = log['odometerReading'];
    final cpl         = log['costPerLitre'];
    final cost        = log['totalCost'];
    final mileage     = log['mileageKmPerLitre'];
    final isFullTank  = log['fullTank']           as bool?   ?? false;
    final payment     = log['paymentMode']        as String?;
    final stationName = log['fuelStationName']    as String?;
    final stationCity = log['fuelStationCity']    as String?;
    final receiptUrl  = log['receiptUrl']         as String?;

    final station = [stationName, stationCity]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Date + full tank badge
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date != null ? FerosDateUtils.formatDate(date) : '—',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.bodyText, fontWeight: FontWeight.w500),
                    ),
                    if (isFullTank)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Full',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16A34A),
                            )),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  litres != null ? '$litres L' : '—',
                  style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  odometer != null ? '$odometer km' : '—',
                  style: AppTextStyles.caption.copyWith(color: AppColors.bodyText),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  cpl != null ? '₹$cpl' : '—',
                  style: AppTextStyles.caption.copyWith(color: AppColors.bodyText),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  cost != null ? '₹$cost' : '—',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.bodyText, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  mileage != null ? '$mileage km/L' : '—',
                  style: AppTextStyles.caption.copyWith(
                    color: mileage != null
                        ? const Color(0xFF15803D)
                        : AppColors.mutedText,
                    fontWeight:
                        mileage != null ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          // Secondary info: payment + station + receipt
          if (payment != null || station.isNotEmpty || receiptUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Wrap(
                spacing: 10,
                runSpacing: 3,
                children: [
                  if (payment != null)
                    _MetaChip(Icons.payment_outlined, _paymentLabel(payment)),
                  if (station.isNotEmpty)
                    _MetaChip(Icons.local_gas_station_outlined, station),
                  if (receiptUrl != null)
                    _MetaChip(Icons.receipt_long_outlined, 'Receipt',
                        color: AppColors.navy),
                ],
              ),
            ),
          // Edit / Delete actions
          if (onEdit != null || onDelete != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    _ActionIcon(
                      icon: Icons.edit_outlined,
                      color: AppColors.navy,
                      onTap: onEdit!,
                    ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 4),
                    _ActionIcon(
                      icon: Icons.delete_outline,
                      color: AppColors.error,
                      onTap: onDelete!,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _paymentLabel(String mode) {
    switch (mode) {
      case 'CASH':            return 'Cash';
      case 'COMPANY_ACCOUNT': return 'Company Account';
      case 'REIMBURSEMENT':   return 'Reimbursement';
      default:                return mode;
    }
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

// ── Fuel sheet helpers ────────────────────────────────────────────────────────
void _showFuelSheet(
  BuildContext context,
  SupervisorVehicleDetailController c, {
  Map<String, dynamic>? existing,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FuelLogSheet(controller: c, existing: existing),
  );
}

void _confirmDeleteFuel(
  BuildContext context,
  SupervisorVehicleDetailController c,
  int id,
) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete Fuel Log',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
      content: const Text('Are you sure you want to delete this fuel log?',
          style: TextStyle(fontFamily: 'Inter')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.mutedText, fontFamily: 'Inter')),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            final ok = await c.deleteFuelLog(id);
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to delete fuel log')),
              );
            }
          },
          child: const Text('Delete',
              style: TextStyle(color: AppColors.error, fontFamily: 'Inter',
                  fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

// ── Fuel Log Bottom Sheet ─────────────────────────────────────────────────────
class _FuelLogSheet extends StatefulWidget {
  final SupervisorVehicleDetailController controller;
  final Map<String, dynamic>? existing;
  const _FuelLogSheet({required this.controller, this.existing});

  dynamic get _currentOdometer =>
      controller.vehicle.value?['currentOdometerReading'];

  @override
  State<_FuelLogSheet> createState() => _FuelLogSheetState();
}

class _FuelLogSheetState extends State<_FuelLogSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _dateCtrl;
  late final TextEditingController _litresCtrl;
  late final TextEditingController _odometerCtrl;
  late final TextEditingController _cplCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _stationNameCtrl;
  late final TextEditingController _stationCityCtrl;
  late final TextEditingController _notesCtrl;

  String _paymentMode = 'CASH';
  bool   _isFullTank  = false;
  bool   _saving      = false;

  // Auto-calculate total when litres or cpl changes
  void _recalcTotal() {
    final l = double.tryParse(_litresCtrl.text);
    final c = double.tryParse(_cplCtrl.text);
    if (l != null && c != null) {
      _totalCtrl.text = (l * c).toStringAsFixed(2);
    }
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _dateCtrl        = TextEditingController(text: e?['fillDate']        as String? ?? _today());
    _litresCtrl      = TextEditingController(text: e?['litresFilled']    ?.toString() ?? '');
    _odometerCtrl    = TextEditingController(
        text: e?['odometerReading']?.toString() ??
            widget._currentOdometer?.toString() ?? '');
    _cplCtrl         = TextEditingController(text: e?['costPerLitre']    ?.toString() ?? '');
    _totalCtrl       = TextEditingController(text: e?['totalCost']       ?.toString() ?? '');
    _stationNameCtrl = TextEditingController(text: e?['fuelStationName'] as String? ?? '');
    _stationCityCtrl = TextEditingController(text: e?['fuelStationCity'] as String? ?? '');
    _notesCtrl       = TextEditingController(text: e?['notes']           as String? ?? '');
    _paymentMode     = e?['paymentMode'] as String? ?? 'CASH';
    _isFullTank      = e?['fullTank']    as bool?   ?? false;

    _litresCtrl.addListener(_recalcTotal);
    _cplCtrl.addListener(_recalcTotal);
  }

  @override
  void dispose() {
    for (final c in [_dateCtrl, _litresCtrl, _odometerCtrl, _cplCtrl,
        _totalCtrl, _stationNameCtrl, _stationCityCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final editId = widget.existing != null
        ? (widget.existing!['id'] is int
            ? widget.existing!['id'] as int
            : int.tryParse(widget.existing!['id'].toString()))
        : null;

    final data = {
      'vehicleId':       widget.controller.vehicleId,
      'fillDate':        _dateCtrl.text,
      'litresFilled':    double.tryParse(_litresCtrl.text),
      'odometerReading': double.tryParse(_odometerCtrl.text),
      'costPerLitre':    double.tryParse(_cplCtrl.text),
      'totalCost':       double.tryParse(_totalCtrl.text),
      'isFullTank':      _isFullTank,
      'paymentMode':     _paymentMode,
      'fuelStationName': _stationNameCtrl.text.trim().isEmpty ? null : _stationNameCtrl.text.trim(),
      'fuelStationCity': _stationCityCtrl.text.trim().isEmpty ? null : _stationCityCtrl.text.trim(),
      'notes':           _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    final ok = await widget.controller.saveFuelLog(data, editId: editId);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save fuel log')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEdit ? 'Edit Fuel Log' : 'Add Fill-up',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 20),

              // Date
              _SheetField(
                label: 'Date *',
                child: TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(_dateCtrl.text) ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: AppColors.navy),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      _dateCtrl.text =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  },
                  decoration: _inputDec('Select date'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 12),

              // Litres + Odometer
              Row(children: [
                Expanded(child: _SheetField(
                  label: 'Litres Filled *',
                  child: TextFormField(
                    controller: _litresCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDec('e.g. 150'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: _SheetField(
                  label: 'Odometer (km)',
                  child: TextFormField(
                    controller: _odometerCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDec('e.g. 48200'),
                  ),
                )),
              ]),
              const SizedBox(height: 12),

              // Cost per Litre + Total Cost
              Row(children: [
                Expanded(child: _SheetField(
                  label: 'Cost / Litre (₹)',
                  child: TextFormField(
                    controller: _cplCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDec('e.g. 105.50'),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: _SheetField(
                  label: 'Total Cost (₹)',
                  child: TextFormField(
                    controller: _totalCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDec('Auto-calculated'),
                  ),
                )),
              ]),
              const SizedBox(height: 12),

              // Payment Mode
              _SheetField(
                label: 'Payment Mode',
                child: DropdownButtonFormField<String>(
                  value: _paymentMode,
                  decoration: _inputDec(null),
                  style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 13, color: AppColors.bodyText),
                  items: const [
                    DropdownMenuItem(value: 'CASH',            child: Text('Cash')),
                    DropdownMenuItem(value: 'COMPANY_ACCOUNT', child: Text('Company Account')),
                    DropdownMenuItem(value: 'REIMBURSEMENT',   child: Text('Reimbursement')),
                  ],
                  onChanged: (v) => setState(() => _paymentMode = v ?? 'CASH'),
                ),
              ),
              const SizedBox(height: 12),

              // Station Name + City
              Row(children: [
                Expanded(child: _SheetField(
                  label: 'Station Name',
                  child: TextFormField(
                    controller: _stationNameCtrl,
                    decoration: _inputDec('Indian Oil, HP…'),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: _SheetField(
                  label: 'Station City',
                  child: TextFormField(
                    controller: _stationCityCtrl,
                    decoration: _inputDec('City'),
                  ),
                )),
              ]),
              const SizedBox(height: 12),

              // Notes
              _SheetField(
                label: 'Notes',
                child: TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: _inputDec('Optional notes…'),
                ),
              ),
              const SizedBox(height: 12),

              // Full Tank toggle
              GestureDetector(
                onTap: () => setState(() => _isFullTank = !_isFullTank),
                child: Row(
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: _isFullTank ? AppColors.navy : Colors.transparent,
                        border: Border.all(
                          color: _isFullTank ? AppColors.navy : AppColors.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _isFullTank
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Full tank fill-up',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.bodyText,
                              )),
                          Text('Enables accurate mileage calculation',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.mutedText,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Save Changes' : 'Add Fill-up',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 13, color: AppColors.mutedText),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      );
}

class _SheetField extends StatelessWidget {
  final String label;
  final Widget child;
  const _SheetField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.bodyText,
            )),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

// ── Meter Tab ─────────────────────────────────────────────────────────────────
class _MeterTabBody extends StatefulWidget {
  final SupervisorVehicleDetailController controller;
  const _MeterTabBody({required this.controller});

  @override
  State<_MeterTabBody> createState() => _MeterTabBodyState();
}

class _MeterTabBodyState extends State<_MeterTabBody>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    widget.controller.ensureMeterLoaded();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = widget.controller;

    return Obx(() {
      if (c.meterState.value == ViewState.loading) {
        return const _TabLoading();
      }
      if (c.meterState.value == ViewState.error) {
        return _TabError(onRetry: c.retryMeter);
      }

      final list     = c.meterReadings;
      final latestKm = list.isNotEmpty ? list.first['readingKm'] : null;
      final lastKmNum = latestKm != null
          ? (latestKm as num).toDouble()
          : (c.vehicle.value?['currentOdometerReading'] as num?)?.toDouble() ?? 0.0;

      return Column(
        children: [
          // Odometer summary card + Add button
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.speed_outlined,
                      size: 20, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Odometer',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.mutedText)),
                      Text(
                        latestKm != null ? '$latestKm km' : '—',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showMeterSheet(context, c, lastKmNum),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Add Reading',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Expanded(
              child: _EmptyTabState(
                  icon: Icons.speed_outlined, message: 'No meter readings'),
            )
          else
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: const [
                          _TH('Date',        flex: 3),
                          _TH('Odometer',    flex: 3),
                          _TH('Type',        flex: 2),
                          _TH('Recorded By', flex: 3),
                          _TH('Notes',       flex: 3),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _MeterRow(
                            reading: list[i], isLast: i == list.length - 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      );
    });
  }
}

class _MeterRow extends StatelessWidget {
  final Map<String, dynamic> reading;
  final bool isLast;
  const _MeterRow({required this.reading, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final km         = reading['readingKm'];
    final type       = reading['readingType']    as String?;
    final recordedAt = reading['recordedAt']     as String?;
    final recordedBy = reading['recordedByName'] as String?;
    final notes      = reading['notes']          as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3,
            child: Text(
              recordedAt != null
                  ? FerosDateUtils.formatDate(recordedAt)
                  : '—',
              style: AppTextStyles.caption.copyWith(color: AppColors.bodyText),
            )),
          Expanded(flex: 3,
            child: Text(
              km != null ? '$km km' : '—',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.navy, fontWeight: FontWeight.w600),
            )),
          Expanded(flex: 2,
            child: type != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      type.replaceAll('_', ' ').toLowerCase(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Text('—', style: AppTextStyles.caption)),
          Expanded(flex: 3,
            child: Text(
              recordedBy ?? '—',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
          Expanded(flex: 3,
            child: Text(
              notes ?? '—',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedText),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )),
        ],
      ),
    );
  }
}

// ── Meter sheet helpers ───────────────────────────────────────────────────────
void _showMeterSheet(
  BuildContext context,
  SupervisorVehicleDetailController c,
  double lastKm,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MeterReadingSheet(controller: c, lastKm: lastKm),
  );
}

class _MeterReadingSheet extends StatefulWidget {
  final SupervisorVehicleDetailController controller;
  final double lastKm;
  const _MeterReadingSheet({required this.controller, required this.lastKm});

  @override
  State<_MeterReadingSheet> createState() => _MeterReadingSheetState();
}

class _MeterReadingSheetState extends State<_MeterReadingSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kmCtrl;
  late final TextEditingController _notesCtrl;
  String _date = _today();
  bool _saving = false;

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _kmCtrl    = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'vehicleId':   widget.controller.vehicleId,
      'readingKm':   double.parse(_kmCtrl.text),
      'readingType': 'GENERAL',
      'recordedAt':  '${_date}T00:00:00',
      'notes':       _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    final ok = await widget.controller.createMeterReading(data);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save reading')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastFmt = widget.lastKm > 0
        ? '${widget.lastKm.toStringAsFixed(0)} km'
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Add Meter Reading',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.navy,
                  )),
              const SizedBox(height: 20),

              // Odometer km
              _SheetField(
                label: lastFmt != null
                    ? 'Odometer (km) * — must be > $lastFmt'
                    : 'Odometer (km) *',
                child: TextFormField(
                  controller: _kmCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: lastFmt != null ? 'Enter km > $lastFmt' : 'e.g. 48200',
                    hintStyle: const TextStyle(
                        fontFamily: 'Inter', fontSize: 13, color: AppColors.mutedText),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColors.navy, width: 1.5)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.error)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final km = double.tryParse(v);
                    if (km == null || km <= 0) return 'Enter a valid reading';
                    if (widget.lastKm > 0 && km <= widget.lastKm) {
                      return 'Must be > ${widget.lastKm.toStringAsFixed(0)} km';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Date
              _SheetField(
                label: 'Date *',
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: AppColors.navy),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _date =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(_date,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.bodyText,
                        )),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Notes
              _SheetField(
                label: 'Notes',
                child: TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Optional',
                    hintStyle: const TextStyle(
                        fontFamily: 'Inter', fontSize: 13,
                        color: AppColors.mutedText),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColors.navy, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save Reading',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        _SectionHeader('GPS Tracking'),
        const SizedBox(height: 8),
        _InfoSection(title: '', rows: [
          _IR('Device No.',  v['gpsDeviceNumber']),
          _IR('IMEI',        v['gpsDeviceImei']),
          _IR('Provider',    v['gpsProvider']),
          _IR('Odometer',    v['currentOdometerReading'] != null
              ? '${v['currentOdometerReading']} km' : null),
        ]),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader('Notes'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(notes,
                style: AppTextStyles.body.copyWith(color: AppColors.bodyText)),
          ),
        ],
      ],
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.mutedText,
        letterSpacing: 0.8,
        fontSize: 10,
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_IR> rows;
  const _InfoSection({required this.title, required this.rows});

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
          if (title.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(12)),
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
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: rows.asMap().entries.map((e) {
                return _IRWidget(row: e.value, isLast: e.key == rows.length - 1);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _IR {
  final String label;
  final dynamic value;
  const _IR(this.label, this.value);
}

class _IRWidget extends StatelessWidget {
  final _IR  row;
  final bool isLast;
  const _IRWidget({required this.row, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(row.label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText)),
          ),
          Expanded(
            flex: 5,
            child: Text(
              row.value?.toString().isNotEmpty == true
                  ? row.value.toString()
                  : '—',
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

class _TabLoading extends StatelessWidget {
  const _TabLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.navy, strokeWidth: 2),
    );
  }
}

class _TabError extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _TabError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.mutedText),
          const SizedBox(height: 10),
          Text('Failed to load',
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(
                    color: AppColors.navy, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  final IconData icon;
  final String   message;
  const _EmptyTabState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.border),
          const SizedBox(height: 12),
          Text(message,
              style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
        ],
      ),
    );
  }
}
