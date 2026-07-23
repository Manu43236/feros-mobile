import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/widgets/feros_bottom_nav.dart';

class DriverShellController extends GetxController {
  final currentIndex = 0.obs;

  void onTabTapped(int index) => currentIndex.value = index;

  List<NavItem> get navItems {
    final role = Get.find<AuthService>().user?.role ?? '';
    switch (role) {
      case 'DRIVER':
      case 'CLEANER':
        return [
          NavItem(label: 'nav_home'.tr,       icon: Icons.home_outlined,            activeIcon: Icons.home,              route: '/shell'),
          NavItem(label: 'nav_trips'.tr,      icon: Icons.local_shipping_outlined,  activeIcon: Icons.local_shipping,    route: '/shell'),
          NavItem(label: 'nav_attendance'.tr, icon: Icons.check_circle_outline,     activeIcon: Icons.check_circle,      route: '/shell'),
          NavItem(label: 'lbl_profile'.tr,    icon: Icons.person_outline,           activeIcon: Icons.person,            route: '/shell'),
        ];
      case 'SERVICE_MANAGER':
        return [
          NavItem(label: 'nav_home'.tr,       icon: Icons.home_outlined,            activeIcon: Icons.home,              route: '/shell'),
          NavItem(label: 'nav_services'.tr,   icon: Icons.build_outlined,           activeIcon: Icons.build,             route: '/shell'),
          NavItem(label: 'nav_tyres'.tr,      icon: Icons.tire_repair_outlined,     activeIcon: Icons.tire_repair,       route: '/shell'),
          NavItem(label: 'nav_attendance'.tr, icon: Icons.check_circle_outline,     activeIcon: Icons.check_circle,      route: '/shell'),
          NavItem(label: 'nav_payslip'.tr,    icon: Icons.receipt_outlined,         activeIcon: Icons.receipt,           route: '/shell'),
          NavItem(label: 'lbl_profile'.tr,    icon: Icons.person_outline,           activeIcon: Icons.person,            route: '/shell'),
        ];
      case 'TECHNICIAN':
        return [
          NavItem(label: 'nav_tasks'.tr,      icon: Icons.handyman_outlined,        activeIcon: Icons.handyman,          route: '/shell'),
          NavItem(label: 'nav_attendance'.tr, icon: Icons.check_circle_outline,     activeIcon: Icons.check_circle,      route: '/shell'),
          NavItem(label: 'lbl_profile'.tr,    icon: Icons.person_outline,           activeIcon: Icons.person,            route: '/shell'),
        ];
      case 'STORE_KEEPER':
        return [
          NavItem(label: 'nav_home'.tr,       icon: Icons.home_outlined,            activeIcon: Icons.home,              route: '/shell'),
          NavItem(label: 'nav_inventory'.tr,  icon: Icons.inventory_2_outlined,     activeIcon: Icons.inventory_2,       route: '/shell'),
          NavItem(label: 'nav_attendance'.tr, icon: Icons.check_circle_outline,     activeIcon: Icons.check_circle,      route: '/shell'),
          NavItem(label: 'lbl_profile'.tr,    icon: Icons.person_outline,           activeIcon: Icons.person,            route: '/shell'),
        ];
      case 'SUPERVISOR':
        return [
          NavItem(label: 'nav_home'.tr,       icon: Icons.home_outlined,            activeIcon: Icons.home,              route: '/shell'),
          NavItem(label: 'nav_orders'.tr,     icon: Icons.assignment_outlined,      activeIcon: Icons.assignment,        route: '/shell'),
          NavItem(label: 'lbl_staff'.tr,      icon: Icons.group_outlined,           activeIcon: Icons.group,             route: '/shell'),
          NavItem(label: 'lbl_profile'.tr,    icon: Icons.person_outline,           activeIcon: Icons.person,            route: '/shell'),
        ];
      case 'OFFICE_STAFF':
        return [
          NavItem(label: 'nav_home'.tr,       icon: Icons.home_outlined,            activeIcon: Icons.home,              route: '/shell'),
          NavItem(label: 'nav_orders'.tr,     icon: Icons.assignment_outlined,      activeIcon: Icons.assignment,        route: '/shell'),
          NavItem(label: 'lbl_lr_number'.tr,  icon: Icons.receipt_long_outlined,    activeIcon: Icons.receipt_long,      route: '/shell'),
          NavItem(label: 'lbl_profile'.tr,    icon: Icons.person_outline,           activeIcon: Icons.person,            route: '/shell'),
        ];
      default: // ADMIN
        return [
          NavItem(label: 'nav_home'.tr,       icon: Icons.home_outlined,            activeIcon: Icons.home,              route: '/shell'),
          NavItem(label: 'nav_orders'.tr,     icon: Icons.assignment_outlined,      activeIcon: Icons.assignment,        route: '/shell'),
          NavItem(label: 'nav_vehicles'.tr,   icon: Icons.directions_bus_outlined,  activeIcon: Icons.directions_bus,    route: '/shell'),
          NavItem(label: 'lbl_profile'.tr,    icon: Icons.person_outline,           activeIcon: Icons.person,            route: '/shell'),
        ];
    }
  }
}
