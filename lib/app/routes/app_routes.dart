part of 'app_pages.dart';

abstract class Routes {
  Routes._();

  static const SPLASH = _Paths.SPLASH;
  static const LOGIN = _Paths.LOGIN;
  static const HOME = _Paths.HOME;
  static const DASHBOARD = _Paths.DASHBOARD;
  static const SHELL            = _Paths.SHELL;
  static const SUPERVISOR_SHELL = _Paths.SUPERVISOR_SHELL;
  static const OFFICE_SHELL     = _Paths.OFFICE_SHELL;

  // Vehicles
  static const VEHICLES = _Paths.VEHICLES;
  static const VEHICLE_DETAIL = _Paths.VEHICLE_DETAIL;
  static const VEHICLE_SERVICES = _Paths.VEHICLE_SERVICES;
  static const VEHICLE_BREAKDOWNS = _Paths.VEHICLE_BREAKDOWNS;

  // Orders & LRs
  static const ORDERS = _Paths.ORDERS;
  static const ORDER_DETAIL = _Paths.ORDER_DETAIL;
  static const LRS = _Paths.LRS;
  static const LR_DETAIL = _Paths.LR_DETAIL;
  static const LR_CREATE = _Paths.LR_CREATE;

  // Invoices & Clients
  static const INVOICES = _Paths.INVOICES;
  static const INVOICE_DETAIL = _Paths.INVOICE_DETAIL;
  static const CLIENTS = _Paths.CLIENTS;
  static const CLIENT_DETAIL = _Paths.CLIENT_DETAIL;

  // Staff & Attendance
  static const STAFF = _Paths.STAFF;
  static const STAFF_DETAIL = _Paths.STAFF_DETAIL;
  static const ATTENDANCE = _Paths.ATTENDANCE;
  static const ATTENDANCE_MARK = _Paths.ATTENDANCE_MARK;

  // Driver self-service
  static const MY_TRIPS = _Paths.MY_TRIPS;
  static const MY_TRIP_DETAIL = _Paths.MY_TRIP_DETAIL;
  static const MY_EXPENSES = _Paths.MY_EXPENSES;
  static const MY_ATTENDANCE = _Paths.MY_ATTENDANCE;

  // Inventory & Parts
  static const INVENTORY = _Paths.INVENTORY;
  static const INVENTORY_DETAIL = _Paths.INVENTORY_DETAIL;
  static const PARTS_REQUESTS = _Paths.PARTS_REQUESTS;
  static const PARTS_REQUEST_DETAIL = _Paths.PARTS_REQUEST_DETAIL;

  // Payroll & Reports
  static const PAYROLL = _Paths.PAYROLL;
  static const PAYROLL_DETAIL = _Paths.PAYROLL_DETAIL;
  static const REPORTS = _Paths.REPORTS;

  // Misc
  static const NOTIFICATIONS = _Paths.NOTIFICATIONS;
  static const PROFILE = _Paths.PROFILE;
  static const SUBSCRIPTION = _Paths.SUBSCRIPTION;
  static const FORCE_PIN_CHANGE = _Paths.FORCE_PIN_CHANGE;
}

abstract class _Paths {
  _Paths._();

  static const SPLASH = '/splash';
  static const LOGIN = '/login';
  static const HOME = '/home';
  static const DASHBOARD = '/dashboard';
  static const SHELL            = '/shell';
  static const SUPERVISOR_SHELL = '/supervisor';
  static const OFFICE_SHELL     = '/office';

  static const VEHICLES = '/vehicles';
  static const VEHICLE_DETAIL = '/vehicles/detail';
  static const VEHICLE_SERVICES = '/vehicles/services';
  static const VEHICLE_BREAKDOWNS = '/vehicles/breakdowns';

  static const ORDERS = '/orders';
  static const ORDER_DETAIL = '/orders/detail';
  static const LRS = '/lrs';
  static const LR_DETAIL = '/lrs/detail';
  static const LR_CREATE = '/lrs/create';

  static const INVOICES = '/invoices';
  static const INVOICE_DETAIL = '/invoices/detail';
  static const CLIENTS = '/clients';
  static const CLIENT_DETAIL = '/clients/detail';

  static const STAFF = '/staff';
  static const STAFF_DETAIL = '/staff/detail';
  static const ATTENDANCE = '/attendance';
  static const ATTENDANCE_MARK = '/attendance/mark';

  static const MY_TRIPS = '/my/trips';
  static const MY_TRIP_DETAIL = '/my/trips/detail';
  static const MY_EXPENSES = '/my/expenses';
  static const MY_ATTENDANCE = '/my/attendance';

  static const INVENTORY = '/inventory';
  static const INVENTORY_DETAIL = '/inventory/detail';
  static const PARTS_REQUESTS = '/parts/requests';
  static const PARTS_REQUEST_DETAIL = '/parts/requests/detail';

  static const PAYROLL = '/payroll';
  static const PAYROLL_DETAIL = '/payroll/detail';
  static const REPORTS = '/reports';

  static const NOTIFICATIONS = '/notifications';
  static const PROFILE = '/profile';
  static const SUBSCRIPTION = '/subscription';
  static const FORCE_PIN_CHANGE = '/force-pin-change';
}
