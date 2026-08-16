import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/view_state.dart';
import '../../../../../core/popups/feros_snackbar.dart';
import '../controllers/office_staff_controller.dart';
import 'office_staff_detail_view.dart';

class OfficeStaffView extends StatelessWidget {
  const OfficeStaffView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<OfficeStaffController>(() => OfficeStaffController());
    final controller = Get.find<OfficeStaffController>();
    final isAdmin = Get.find<AuthService>().user?.role == 'ADMIN';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text(
          'Staff',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search + Filter ──────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: controller.onSearch,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.bodyText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Obx(() {
                    final sel = controller.selectedRole.value;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: OfficeStaffController.roles.map((r) {
                          final active = r == sel;
                          final label = r == 'ALL'
                              ? 'All'
                              : r == 'SERVICE_MANAGER'
                              ? 'Service Manager'
                              : r == 'STORE_KEEPER'
                              ? 'Store Keeper'
                              : r == 'OFFICE_STAFF'
                              ? 'Office Staff'
                              : r[0] + r.substring(1).toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => controller.setRole(r),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
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
                                child: Text(
                                  label,
                                  style: AppTextStyles.caption.copyWith(
                                    color: active
                                        ? Colors.white
                                        : AppColors.mutedText,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
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

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final s = controller.state.value;
              if (s == ViewState.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.navy),
                );
              }
              if (s == ViewState.error) {
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
                        'Failed to load staff',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.fetchStaff,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              final list = controller.filtered;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 52,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No staff found',
                        style: AppTextStyles.heading4.copyWith(
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try a different search or filter',
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
                onRefresh: controller.fetchStaff,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _StaffCard(
                    user: list[i],
                    isAdmin: isAdmin,
                    onResetPin: () =>
                        _handleResetPin(context, controller, list[i]),
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
              icon: const Icon(Icons.person_add_outlined),
              label: const Text(
                'Add Staff',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _showCreateStaffSheet(context, controller),
            )
          : null,
    );
  }

  Future<void> _handleResetPin(
    BuildContext context,
    OfficeStaffController controller,
    Map<String, dynamic> user,
  ) async {
    final id = (user['id'] as num?)?.toInt() ?? 0;
    final name = user['name'] as String? ?? 'Staff';
    try {
      final pin = await controller.resetPin(id);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('PIN Reset — $name'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('New PIN:'),
                const SizedBox(height: 8),
                Text(
                  pin ?? '—',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share this PIN with the staff member.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      FerosSnackbar.error('Could not reset PIN. Try again.');
    }
  }

  void _showCreateStaffSheet(
    BuildContext context,
    OfficeStaffController controller,
  ) {
    showModalBottomSheet(
        useSafeArea: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateStaffSheet(controller: controller),
    );
  }
}

// ── Staff Card ─────────────────────────────────────────────────────────────────
class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isAdmin;
  final VoidCallback onResetPin;
  const _StaffCard({
    required this.user,
    required this.isAdmin,
    required this.onResetPin,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['name'] as String? ?? '—';
    final role = user['role'] as String? ?? '';
    final phone = user['phone'] as String? ?? '';
    final isActive = user['isActive'] as bool? ?? true;
    final joiningDate = user['joiningDate'] as String?;
    final empType = user['employmentType'] as String?;

    return GestureDetector(
      onTap: () => Get.to(() => OfficeStaffDetailView(user: user)),
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
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ────────────────────────────────────────────────
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _roleColor(role).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTextStyles.heading3.copyWith(
                    color: _roleColor(role),
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ──────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoleBadge(role: role),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (phone.isNotEmpty) ...[
                        const Icon(
                          Icons.phone_outlined,
                          size: 12,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (empType != null) ...[
                        const Icon(
                          Icons.work_outline,
                          size: 12,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          empType,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (joiningDate != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Joined $joiningDate',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                        const Spacer(),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mutedText.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Inactive',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mutedText,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),
            if (isAdmin)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'pin') onResetPin();
                },
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: AppColors.mutedText,
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'pin',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Reset PIN'),
                      ],
                    ),
                  ),
                ],
              )
            else
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.mutedText,
              ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'DRIVER':
        return AppColors.navy;
      case 'CLEANER':
        return AppColors.orange;
      case 'SUPERVISOR':
        return const Color(0xFF7C3AED);
      case 'SERVICE_MANAGER':
        return AppColors.success;
      case 'STORE_KEEPER':
        return const Color(0xFF0891B2);
      case 'OFFICE_STAFF':
        return const Color(0xFF0284C7);
      default:
        return AppColors.navy;
    }
  }
}

// ── Role Badge ─────────────────────────────────────────────────────────────────
class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      'SERVICE_MANAGER' => 'Service Manager',
      'STORE_KEEPER' => 'Store Keeper',
      'OFFICE_STAFF' => 'Office Staff',
      _ => role[0] + role.substring(1).toLowerCase(),
    };
    final color = switch (role) {
      'DRIVER' => AppColors.navy,
      'CLEANER' => AppColors.orange,
      'SUPERVISOR' => const Color(0xFF7C3AED),
      'SERVICE_MANAGER' => AppColors.success,
      'STORE_KEEPER' => const Color(0xFF0891B2),
      'OFFICE_STAFF' => const Color(0xFF0284C7),
      _ => AppColors.navy,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ── Create Staff Bottom Sheet ──────────────────────────────────────────────────
class _CreateStaffSheet extends StatefulWidget {
  final OfficeStaffController controller;
  const _CreateStaffSheet({required this.controller});

  @override
  State<_CreateStaffSheet> createState() => _CreateStaffSheetState();
}

class _CreateStaffSheetState extends State<_CreateStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _phoneCtr = TextEditingController();
  String _role = 'DRIVER';
  bool _loading = false;

  static const _roles = [
    'DRIVER',
    'CLEANER',
    'SUPERVISOR',
    'SERVICE_MANAGER',
    'STORE_KEEPER',
    'OFFICE_STAFF',
  ];

  @override
  void dispose() {
    _nameCtr.dispose();
    _phoneCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.controller.createUser({
        'name': _nameCtr.text.trim(),
        'phone': _phoneCtr.text.trim(),
        'role': _role,
      });
      if (mounted) {
        Navigator.pop(context);
        FerosSnackbar.success('Staff member created successfully');
      }
    } catch (e) {
      FerosSnackbar.error('Failed to create staff. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Add Staff',
                  style: AppTextStyles.heading4.copyWith(color: AppColors.navy),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            _label('Full Name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtr,
              decoration: _inputDec('e.g. Ravi Kumar'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Phone
            _label('Phone Number'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneCtr,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: _inputDec('10-digit number'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length != 10) return 'Must be 10 digits';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Role
            _label('Role'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: _inputDec(''),
              items: _roles.map((r) {
                final label = switch (r) {
                  'SERVICE_MANAGER' => 'Service Manager',
                  'STORE_KEEPER' => 'Store Keeper',
                  'OFFICE_STAFF' => 'Office Staff',
                  _ => r[0] + r.substring(1).toLowerCase(),
                };
                return DropdownMenuItem(value: r, child: Text(label));
              }).toList(),
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create Staff',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AppTextStyles.caption.copyWith(
      color: AppColors.bodyText,
      fontWeight: FontWeight.w600,
    ),
  );

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
    filled: true,
    fillColor: AppColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
    ),
    counterText: '',
  );
}
