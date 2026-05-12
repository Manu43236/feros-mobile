import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/popups/feros_snackbar.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_card.dart';

class FuelLogView extends StatefulWidget {
  const FuelLogView({super.key});

  @override
  State<FuelLogView> createState() => _FuelLogViewState();
}

class _FuelLogViewState extends State<FuelLogView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final api = Get.find<ApiClient>();
      final res = await api.get(ApiEndpoints.fuelLogs);
      final raw = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
      setState(() {
        _logs = raw.cast<Map<String, dynamic>>()
          ..sort((a, b) =>
              (b['id'] as int? ?? 0).compareTo(a['id'] as int? ?? 0));
      });
    } catch (_) {
      FerosSnackbar.error('Failed to load fuel logs');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Fuel Log',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppColors.navy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const ShimmerList(count: 4)
          : RefreshIndicator(
              onRefresh: _fetch,
              color: AppColors.navy,
              child: _logs.isEmpty
                  ? const EmptyState(
                      icon: Icons.local_gas_station_outlined,
                      title: 'No Fuel Logs',
                      subtitle: 'Tap + to record a fuel fill',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _FuelLogCard(log: _logs[i]),
                    ),
            ),
    );
  }

  Future<void> _showAddDialog() async {
    final litresCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final odmCtrl = TextEditingController();
    final stationCtrl = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Add Fuel Log',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.navy)),
                const SizedBox(height: 16),
                _Field(
                  label: 'Litres Filled',
                  controller: litresCtrl,
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                  suffix: 'L',
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Total Cost (₹)',
                  controller: costCtrl,
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                  prefix: '₹',
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Odometer Reading (km)',
                  controller: odmCtrl,
                  keyboard: TextInputType.number,
                  suffix: 'km',
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Fuel Station (optional)',
                  controller: stationCtrl,
                  keyboard: TextInputType.text,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final litres = double.tryParse(litresCtrl.text.trim());
                            final cost = double.tryParse(costCtrl.text.trim());
                            final odm = double.tryParse(odmCtrl.text.trim());
                            if (litres == null || cost == null) {
                              FerosSnackbar.error('Enter litres and cost');
                              return;
                            }
                            setSheet(() => isSubmitting = true);
                            try {
                              final api = Get.find<ApiClient>();
                              await api.post(ApiEndpoints.fuelLogs, data: {
                                'litresFilled': litres,
                                'totalCost': cost,
                                if (odm != null) 'odometerReading': odm,
                                if (stationCtrl.text.trim().isNotEmpty)
                                  'fuelStationName': stationCtrl.text.trim(),
                                'fillDate': DateTime.now()
                                    .toIso8601String()
                                    .split('T')[0],
                              });
                              FerosSnackbar.success('Fuel log added');
                              Navigator.of(ctx).pop();
                              _fetch();
                            } catch (_) {
                              FerosSnackbar.error('Failed to add fuel log');
                            }
                            setSheet(() => isSubmitting = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Save',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Fuel Log Card ─────────────────────────────────────────────────────────────
class _FuelLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _FuelLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final litres = (log['litresFilled'] as num?)?.toDouble();
    final cost = (log['totalCost'] as num?)?.toDouble();
    final odm = (log['odometerReading'] as num?)?.toDouble();
    final station = log['fuelStationName'] as String?;
    final date = log['fillDate'] as String? ?? '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_gas_station_outlined,
                color: AppColors.navy, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${litres?.toStringAsFixed(1) ?? '—'} L  •  ₹${cost?.toStringAsFixed(0) ?? '—'}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
                ),
                if (station != null && station.isNotEmpty)
                  Text(station,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText)),
                Text(date,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
              ],
            ),
          ),
          if (odm != null)
            Text(
              '${odm.toStringAsFixed(0)} km',
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
        ],
      ),
    );
  }
}

// ── Field Helper ──────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboard;
  final String? suffix;
  final String? prefix;

  const _Field({
    required this.label,
    required this.controller,
    required this.keyboard,
    this.suffix,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            AppTextStyles.caption.copyWith(color: AppColors.mutedText),
        suffixText: suffix,
        prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.navy),
        ),
      ),
    );
  }
}
