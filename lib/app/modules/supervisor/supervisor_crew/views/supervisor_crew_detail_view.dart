import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';

class SupervisorCrewDetailView extends StatefulWidget {
  final Map<String, dynamic> member;
  const SupervisorCrewDetailView({super.key, required this.member});

  @override
  State<SupervisorCrewDetailView> createState() => _State();
}

class _State extends State<SupervisorCrewDetailView> {
  final _api = Get.find<ApiClient>();
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = widget.member['id'] as int?;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final res = await _api.get(ApiEndpoints.staffProfileById(uid));
      setState(() {
        _profile = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m    = widget.member;
    final name = m['name'] as String? ?? '—';
    final role = m['role'] as String? ?? '';
    final phone = m['phone'] as String? ?? '—';
    final designation = m['designationName'] as String?;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarBg = role == 'DRIVER'
        ? const Color(0xFF1E3A5F)
        : const Color(0xFF374151);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Text(
          name,
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: avatarBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [role, ?designation].join(' · '),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  _Section(
                    title: 'Basic Info',
                    rows: [
                      _row('Employment Type', _profile?['employmentTypeName']),
                      _row('Date of Birth', _profile?['dateOfBirth']),
                      _row('Joining Date', _profile?['joiningDate']),
                    ],
                  ),

                  if (role == 'DRIVER') ...[
                    const SizedBox(height: 12),
                    _Section(
                      title: 'License',
                      rows: [
                        _row('License Number', _profile?['licenseNumber']),
                        _row('Expiry Date', _profile?['licenseExpiryDate']),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  _Section(
                    title: 'Address',
                    rows: [
                      _row('Address', _profile?['address']),
                      _row('State', _profile?['stateName']),
                      _row('City', _profile?['cityName']),
                      _row('Pincode', _profile?['pincode']),
                    ],
                  ),

                  const SizedBox(height: 12),
                  _Section(
                    title: 'Emergency Contact',
                    rows: [
                      _row('Name', _profile?['emergencyContactName']),
                      _row('Phone', _profile?['emergencyContactPhone']),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  _InfoRow? _row(String label, dynamic value) {
    final v = value?.toString();
    if (v == null || v.isEmpty) return null;
    return _InfoRow(label: label, value: v);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_InfoRow?> rows;
  const _Section({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final visible = rows.whereType<_InfoRow>().toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Text(
              title,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...visible.map((r) => r),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.bodyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
