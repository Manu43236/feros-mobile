import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/feros_bottom_nav.dart';

class ShellController extends GetxController {
  final currentIndex = 0.obs;

  void onTabTapped(int index) => currentIndex.value = index;

  List<NavItem> get navItems {
    final role = Get.find<AuthService>().user?.role ?? '';
    switch (role) {
      case 'DRIVER':
      case 'CLEANER':
        return const [
          NavItem(label: 'Home',       icon: Icons.home_outlined,            activeIcon: Icons.home,              route: '/shell'),
          NavItem(label: 'Trips',      icon: Icons.local_shipping_outlined,  activeIcon: Icons.local_shipping,    route: '/shell'),
          NavItem(label: 'Attendance', icon: Icons.check_circle_outline,     activeIcon: Icons.check_circle,      route: '/shell'),
          NavItem(label: 'Profile',    icon: Icons.person_outline,           activeIcon: Icons.person,            route: '/shell'),
        ];
      case 'SERVICE_MEN':
        return const [
          NavItem(label: 'Home',       icon: Icons.home_outlined,            activeIcon: Icons.home,              route: '/shell'),
          NavItem(label: 'Services',   icon: Icons.build_outlined,           activeIcon: Icons.build,             route: '/shell'),
          NavItem(label: 'Breakdown',  icon: Icons.car_crash_outlined,       activeIcon: Icons.car_crash,         route: '/shell'),
          NavItem(label: 'Profile',    icon: Icons.person_outline,           activeIcon: Icons.person,            route: '/shell'),
        ];
      case 'STORE_KEEPER':
        return const [
          NavItem(label: 'Home',       icon: Icons.home_outlined,            activeIcon: Icons.home,              route: '/shell'),
          NavItem(label: 'Inventory',  icon: Icons.inventory_2_outlined,     activeIcon: Icons.inventory_2,       route: '/shell'),
          NavItem(label: 'Requests',   icon: Icons.list_alt_outlined,        activeIcon: Icons.list_alt,          route: '/shell'),
          NavItem(label: 'Profile',    icon: Icons.person_outline,           activeIcon: Icons.person,            route: '/shell'),
        ];
      case 'SUPERVISOR':
        return const [
          NavItem(label: 'Home',       icon: Icons.home_outlined,            activeIcon: Icons.home,              route: '/shell'),
          NavItem(label: 'Orders',     icon: Icons.assignment_outlined,      activeIcon: Icons.assignment,        route: '/shell'),
          NavItem(label: 'Staff',      icon: Icons.group_outlined,           activeIcon: Icons.group,             route: '/shell'),
          NavItem(label: 'Profile',    icon: Icons.person_outline,           activeIcon: Icons.person,            route: '/shell'),
        ];
      case 'OFFICE_STAFF':
        return const [
          NavItem(label: 'Home',       icon: Icons.home_outlined,            activeIcon: Icons.home,              route: '/shell'),
          NavItem(label: 'Orders',     icon: Icons.assignment_outlined,      activeIcon: Icons.assignment,        route: '/shell'),
          NavItem(label: 'LRs',        icon: Icons.receipt_long_outlined,    activeIcon: Icons.receipt_long,      route: '/shell'),
          NavItem(label: 'Profile',    icon: Icons.person_outline,           activeIcon: Icons.person,            route: '/shell'),
        ];
      default: // ADMIN
        return const [
          NavItem(label: 'Home',       icon: Icons.home_outlined,            activeIcon: Icons.home,              route: '/shell'),
          NavItem(label: 'Orders',     icon: Icons.assignment_outlined,      activeIcon: Icons.assignment,        route: '/shell'),
          NavItem(label: 'Vehicles',   icon: Icons.directions_bus_outlined,  activeIcon: Icons.directions_bus,    route: '/shell'),
          NavItem(label: 'Profile',    icon: Icons.person_outline,           activeIcon: Icons.person,            route: '/shell'),
        ];
    }
  }
}
