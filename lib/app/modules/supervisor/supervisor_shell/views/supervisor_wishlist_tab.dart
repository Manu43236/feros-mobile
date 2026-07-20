import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../supervisor_vehicles/bindings/supervisor_vehicles_binding.dart';
import '../../supervisor_vehicles/views/supervisor_vehicles_view.dart';
import '../../supervisor_crew/bindings/supervisor_crew_binding.dart';
import '../../supervisor_crew/views/supervisor_crew_view.dart';

class SupervisorWishlistTab extends StatefulWidget {
  const SupervisorWishlistTab({super.key});

  @override
  State<SupervisorWishlistTab> createState() => _SupervisorWishlistTabState();
}

class _SupervisorWishlistTabState extends State<SupervisorWishlistTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    SupervisorVehiclesBinding().dependencies();
    SupervisorCrewBinding().dependencies();
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
        // ── Vehicles | Drivers & Cleaners tab bar ───────────────
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              TabBar(
                controller: _tab,
                labelColor: AppColors.navy,
                unselectedLabelColor: AppColors.mutedText,
                indicatorColor: AppColors.navy,
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Vehicles'),
                  Tab(text: 'Drivers & Cleaners'),
                ],
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
            ],
          ),
        ),

        // ── Tab content ─────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              SupervisorVehiclesView(embedded: true),
              SupervisorCrewView(embedded: true),
            ],
          ),
        ),
      ],
    );
  }
}
