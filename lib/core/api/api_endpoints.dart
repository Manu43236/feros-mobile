class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const login = '/auth/login';

  // Dashboard
  static const dashboard     = '/dashboard';
  static const expiryAlerts  = '/dashboard/expiry-alerts';

  // Vehicles
  static const vehicles                   = '/vehicles';
  static String vehicleById(id)           => '/vehicles/$id';
  static String vehicleStatus(id)         => '/vehicles/$id/status';
  static String vehicleToggleActive(id)   => '/vehicles/$id/active';
  static const vehicleServices            = '/vehicle-services';
  static String vehicleServiceById(id)    => '/vehicle-services/$id';
  static String vehicleServicesByVehicle(id) => '/vehicle-services/vehicle/$id';
  static String startService(id)          => '/vehicle-services/$id/start';
  static String completeService(id)       => '/vehicle-services/$id/complete';
  static String cancelService(id)         => '/vehicle-services/$id/cancel';
  static const fuelLogs                   = '/fuel-logs';
  static String fuelLogById(id)           => '/fuel-logs/$id';
  static const meterReadings              = '/meter-readings';
  static String meterReadingById(id)      => '/meter-readings/$id';

  // Breakdowns
  static const vehicleBreakdowns          = '/vehicle-breakdowns';
  static const myBreakdown                = '/my/breakdown';
  static String orderBreakdown(oId, aId)  => '/orders/$oId/vehicle-allocations/$aId/breakdown';
  static String resolveBreakdown(oId, bId)=> '/orders/$oId/breakdowns/$bId/resolve';
  static String replaceVehicle(oId, bId)  => '/orders/$oId/breakdowns/$bId/replace';
  static String vehicleBreakdownById(vId) => '/vehicles/$vId/breakdown';
  static String resolveVehicleBreakdown(vId, bId) => '/vehicles/$vId/breakdown/$bId/resolve';

  // Orders
  static const orders                     = '/orders';
  static String orderById(id)             => '/orders/$id';
  static String assignVehicle(id)         => '/orders/$id/assign-vehicle';
  static String unassignVehicle(oId, aId) => '/orders/$oId/allocations/$aId';
  static String assignStaff(id)           => '/orders/$id/assign-staff';
  static String unassignStaff(oId, sId)   => '/orders/$oId/staff-allocations/$sId';
  static String orderStatus(id)           => '/orders/$id/status';
  static String orderPaymentStatus(id)    => '/orders/$id/payment-status';

  // LRs
  static const lrs                        = '/lrs';
  static String lrById(id)               => '/lrs/$id';
  static String lrsByOrder(orderId)      => '/lrs/order/$orderId';
  static String lrCheckposts(id)         => '/lrs/$id/checkposts';
  static String lrCharges(id)            => '/lrs/$id/charges';

  // Invoices
  static const invoices                   = '/invoices';
  static String invoiceById(id)           => '/invoices/$id';
  static String invoicesByClient(cId)     => '/invoices/client/$cId';
  static String invoiceStatus(id)         => '/invoices/$id/status';
  static String invoicePayments(id)       => '/invoices/$id/payments';

  // Credit Notes
  static const creditNotes                = '/credit-notes';
  static String creditNoteById(id)        => '/credit-notes/$id';
  static String creditNoteStatus(id)      => '/credit-notes/$id/status';

  // Client Advances
  static const clientAdvances             = '/client-advances';
  static String clientAdvanceById(id)     => '/client-advances/$id';

  // Clients
  static const clients                    = '/clients';
  static String clientById(id)            => '/clients/$id';
  static String clientStatus(id)          => '/clients/$id/status';

  // Staff
  static const staffProfiles              = '/staff/profiles';
  static String staffProfileById(id)      => '/staff/profiles/$id';
  static String staffDocuments(id)        => '/staff/$id/documents';
  static String verifyStaffDoc(dId)       => '/staff/documents/$dId/verify';

  // Attendance
  static const attendance                 = '/attendance';
  static const attendanceBulk             = '/attendance/bulk';
  static const myAttendance               = '/attendance/my';
  static const attendanceMarkPresent      = '/attendance/my/mark-present';
  static const attendanceTodayStatus      = '/attendance/my/today-status';
  static const attendancePending          = '/attendance/pending';
  static String approveAttendance(id)     => '/attendance/$id/approve';
  static String rejectAttendance(id)      => '/attendance/$id/reject';
  static String userAttendance(id)        => '/attendance/user/$id';
  static const tripProofs                 = '/trip-proofs';
  static String tripProofsByLr(lrId)      => '/trip-proofs/lr/$lrId';
  static String reviewTripProof(id)       => '/trip-proofs/$id/review';

  // Payroll
  static const payroll                    = '/payroll';
  static String payrollById(id)           => '/payroll/$id';
  static String approvePayroll(id)        => '/payroll/$id/approve';
  static const payrollAdvances            = '/payroll/advances';
  static String userPayroll(id)           => '/payroll/user/$id';
  static String userAdvances(id)          => '/payroll/advances/user/$id';

  // Inventory
  static const spareParts                 = '/inventory/spare-parts';
  static String sparePartById(id)         => '/inventory/spare-parts/$id';
  static const stock                      = '/inventory/stock';
  static const stockIn                    = '/inventory/stock-in';
  static const inventoryTransactions      = '/inventory/transactions';
  static const partRequestsPending        = '/inventory/service-parts/pending';
  static String servicePartsByService(id) => '/inventory/service-parts/service/$id';
  static String requestServicePart(id)    => '/inventory/service-parts/service/$id';
  static String approveServicePart(id)    => '/inventory/service-parts/$id/approve';
  static String removeServicePart(id)     => '/inventory/service-parts/$id';

  // Masters — Tenant
  static const routes          = '/masters/tenant/routes';
  static const designations    = '/masters/tenant/designations';
  static const payRates        = '/masters/tenant/pay-rates';
  static const vehicleStatuses = '/masters/tenant/vehicle-statuses';
  static const chargeTypes     = '/masters/tenant/charge-types';
  static const paymentTerms    = '/masters/tenant/payment-terms';
  static const tenantSettings  = '/masters/tenant/settings';

  // Masters — Global
  static const states          = '/masters/global/states';
  static const cities          = '/masters/global/cities';
  static const vehicleTypes    = '/masters/global/vehicle-types';
  static const vehicleBrands   = '/masters/global/vehicle-brands';
  static const fuelTypes       = '/masters/global/fuel-types';
  static const materialTypes   = '/masters/global/material-types';
  static const documentTypes   = '/masters/global/document-types';
  static const attendanceTypes = '/masters/global/attendance-types';
  static const leaveTypes      = '/masters/global/leave-types';
  static const taxes           = '/masters/global/taxes';
  static const serviceTaskTypes= '/masters/global/service-task-types';

  // Notifications
  static const notifications       = '/notifications';
  static const notifUnreadCount    = '/notifications/unread-count';
  static const notifMarkAllRead    = '/notifications/mark-all-read';

  // Subscription
  static const mySubscription      = '/subscriptions/my';
  static const mySubscriptionInvoices = '/subscriptions/my/invoices';

  // Reports
  static const reportDailyVehicles     = '/reports/daily-vehicles';
  static const reportLocalLongTrips    = '/reports/local-long-trips';
  static const reportIdleDrivers       = '/reports/idle-drivers';
  static const reportDocExpiry         = '/reports/document-expiry';
  static const reportTodayAttendance   = '/reports/today-attendance';
  static const reportDelayedTrips      = '/reports/delayed-trips';
  static const reportOrdersBacklog     = '/reports/orders-backlog';
  static const reportInvoiceOutstanding= '/reports/invoice-outstanding';
  static const reportCollections       = '/reports/collections';
  static const reportLrRegister        = '/reports/lr-register';
  static const reportVehicleTrips      = '/reports/vehicle-trips';
  static const reportOrderStatus       = '/reports/order-status';
  static const reportAttendance        = '/reports/attendance';
  static const reportPayrollSummary    = '/reports/payroll-summary';
  static const reportRevenueTrend      = '/reports/revenue-trend';
  static const reportInvoiceAging      = '/reports/invoice-aging';
  static const reportTopClients        = '/reports/top-clients';
  static const reportStockLevels       = '/reports/stock-levels';

  // Upload
  static const upload                  = '/upload';
}
