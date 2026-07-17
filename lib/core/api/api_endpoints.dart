class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const login      = '/auth/login';
  static const logout     = '/auth/logout';
  static const changePin  = '/auth/change-pin';
  static String askPinReset(String phone) => '/auth/ask-pin-reset?phone=${Uri.encodeComponent(phone)}';

  // Dashboard
  static const dashboard    = '/dashboard';
  static const expiryAlerts = '/dashboard/expiry-alerts';

  // Vehicles
  static const vehicles                   = '/vehicles';
  static String vehicleById(id)           => '/vehicles/$id';
  static String vehicleStatus(id)         => '/vehicles/$id/status';
  static String vehicleToggleActive(id)   => '/vehicles/$id/active';
  static String vehicleAssignDriver(id)   => '/vehicles/$id/staff/driver';
  static String vehicleAssignCleaner(id)  => '/vehicles/$id/staff/cleaner';
  static const vehicleServices            = '/vehicle-services';
  static String vehicleServiceById(id)    => '/vehicle-services/$id';
  static String vehicleServicesByVehicle(id) => '/vehicle-services/vehicle/$id';
  static String startService(id)          => '/vehicle-services/$id/start';
  static String completeService(id)       => '/vehicle-services/$id/complete';
  static String cancelService(id)         => '/vehicle-services/$id/cancel';
  static String completeTask(serviceId, taskId) => '/vehicle-services/$serviceId/tasks/$taskId/complete';
  static String addServiceTask(serviceId)       => '/vehicle-services/$serviceId/tasks';

  // Service Manager
  static const serviceManagerDashboard                     = '/service-manager/dashboard';
  static const serviceManagerTechnicians                   = '/service-manager/technicians';
  static String assignTechnicianToTask(serviceId, taskId) => '/vehicle-services/$serviceId/tasks/$taskId/assign';

  // Technician
  static const technicianTasks                     = '/technician/tasks';
  static String technicianStartTask(taskId)        => '/technician/tasks/$taskId/start';
  static String technicianCloseTask(taskId)        => '/technician/tasks/$taskId/close';
  static String technicianTaskPartRequest(taskId)  => '/technician/tasks/$taskId/spare-part-request';
  static String technicianTaskPartRequests(taskId) => '/technician/tasks/$taskId/spare-part-requests';

  // Service Invoices
  static const serviceInvoices                  = '/service-invoices';
  static String serviceInvoiceById(id)          => '/service-invoices/$id';
  static String serviceInvoiceByService(id)     => '/service-invoices/service/$id';
  static String serviceInvoiceMarkPaid(id)      => '/service-invoices/$id/mark-paid';
  static String serviceInvoicePdf(id)           => '/service-invoices/$id/pdf';
  static const fuelLogs                   = '/fuel-logs';
  static String fuelLogById(id)           => '/fuel-logs/$id';
  static const meterReadings              = '/meter-readings';
  static String meterReadingById(id)      => '/meter-readings/$id';

  // Breakdowns
  static const vehicleBreakdowns          = '/vehicle-breakdowns';
  static const myBreakdown                = '/my/breakdown';
  static String orderBreakdown(oId, aId)  => '/orders/$oId/vehicle-allocations/$aId/breakdown';
  static String resolveBreakdown(oId, bId) => '/orders/$oId/breakdowns/$bId/resolve';
  static String cancelBreakdown(oId, bId)  => '/orders/$oId/breakdowns/$bId';
  static String replaceVehicle(oId, bId)   => '/orders/$oId/breakdowns/$bId/replace';
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
  static String orderPdf(id)             => '/orders/$id/pdf';
  static String orderForceDeliver(id)     => '/orders/$id/force-deliver';
  static String orderPaymentStatus(id)    => '/orders/$id/payment-status';

  // LRs
  static const lrs                        = '/lrs';
  static const myLrs                      = '/lrs/my';
  static String lrById(id)               => '/lrs/$id';
  static String lrPdf(id)                => '/lrs/$id/pdf';
  static String lrsByOrder(orderId)      => '/lrs/order/$orderId';
  static String lrCheckposts(id)            => '/lrs/$id/checkposts';
  static String lrCheckpostById(id, cpId)   => '/lrs/$id/checkposts/$cpId';
  static String lrCharges(id)               => '/lrs/$id/charges';
  static String lrChargeById(id, chargeId)  => '/lrs/$id/charges/$chargeId';

  // Trip Expenses
  static String lrTripExpense(lrId)          => '/lr/$lrId/trip-expense';
  static String lrTripExpenseSubmit(lrId)    => '/lr/$lrId/trip-expense/submit';
  static String tripExpenseApprove(id)       => '/trip-expenses/$id/approve';
  static String tripExpenseSettle(id)        => '/trip-expenses/$id/settle';

  // Invoices
  static const invoices                   = '/invoices';
  static String invoiceById(id)           => '/invoices/$id';
  static String invoicesByClient(cId)     => '/invoices/client/$cId';
  static String invoicesByOrder(orderId)  => '/invoices/order/$orderId';
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

  // Users / Staff
  static const users                      = '/users';
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
  static const attendanceMarkOut          = '/attendance/my/mark-out';
  static const attendanceUndoOut          = '/attendance/my/undo-out';
  static const attendancePending          = '/attendance/pending';
  static String attendanceById(id)        => '/attendance/$id';
  static String approveAttendance(id)     => '/attendance/$id/approve';
  static String rejectAttendance(id)      => '/attendance/$id/reject';
  static String userAttendance(id)        => '/attendance/user/$id';
  static const attendanceRejected         = '/attendance/rejected';
  static const tripProofs                 = '/trip-proofs';
  static String tripProofsByLr(lrId)      => '/trip-proofs/lr/$lrId';
  static String reviewTripProof(id)       => '/trip-proofs/$id/review';

  // Payroll
  static const payroll                    = '/payroll';
  static String payrollById(id)           => '/payroll/$id';
  static String approvePayroll(id)        => '/payroll/$id/approve';
  static String payslipPdf(id)            => '/payroll/$id/payslip-pdf';
  static const payrollAdvances            = '/payroll/advances';
  static String userPayroll(id)           => '/payroll/user/$id';
  static String userAdvances(id)          => '/payroll/advances/user/$id';

  // Inventory
  static const spareParts                 = '/inventory/spare-parts';
  static String sparePartById(id)         => '/inventory/spare-parts/$id';
  static const stock                      = '/inventory/stock';
  static const stockIn                    = '/inventory/stock-in';
  static const stockOut                   = '/inventory/stock-out';
  static const inventoryTransactions      = '/inventory/transactions';
  static const partRequestsAll            = '/inventory/service-parts';
  static const partRequestsPending        = '/inventory/service-parts/pending';
  static String servicePartsByService(id) => '/inventory/service-parts/service/$id';
  static String requestServicePart(id)    => '/inventory/service-parts/service/$id';
  static String approveServicePart(id)    => '/inventory/service-parts/$id/approve';
  static String removeServicePart(id)     => '/inventory/service-parts/$id';

  // Masters — Tenant
  static const routes          = '/masters/tenant/routes';
  static const designations    = '/masters/tenant/designations';
  static const vehicleStatuses = '/masters/tenant/vehicle-statuses';
  static const chargeTypes     = '/masters/tenant/charge-types';
  static const clientTypes     = '/masters/tenant/client-types';
  static const paymentTerms    = '/masters/tenant/payment-terms';
  static const tenantSettings  = '/tenants/settings';

  // Vehicle Documents & Images (ADMIN/OFFICE_STAFF)
  static String vehicleDocuments(id)      => '/staff/vehicles/$id/documents';
  static String vehicleDocumentVerify(id) => '/staff/vehicles/documents/$id/verify';
  static String vehicleDocumentById(id)   => '/staff/vehicles/documents/$id';
  static String vehicleImages(id)         => '/staff/vehicles/$id/images';
  static String vehicleImageById(id)      => '/staff/vehicles/images/$id';

  // Masters — Global
  static const states          = '/masters/global/states';
  static const cities          = '/masters/global/cities';
  static const ownershipTypes  = '/masters/global/ownership-types';
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
  static const mySubscription         = '/subscriptions/my';
  static const mySubscriptionInvoices = '/subscriptions/my/invoices';
  static String mySubscriptionInvoicePdf(id) => '/subscriptions/my/invoices/$id/pdf';

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
  static const reportRevenueTrend         = '/reports/revenue-trend';
  // Orders
  static const reportOrderFulfillment    = '/reports/order-fulfillment';
  static const reportOrderLeadTime       = '/reports/order-lead-time';
  static const reportUnassignedVehicles  = '/reports/unassigned-vehicles';
  static const reportDriverAssignments   = '/reports/driver-assignments';
  // LRs & Trips
  static const reportTripsInProgress     = '/reports/trips-in-progress';
  static const reportLrStatusFunnel      = '/reports/lr-status-funnel';
  static const reportUnbilledLrs         = '/reports/unbilled-lrs';
  static const reportInvoiceTurnaround   = '/reports/invoice-turnaround';
  static const reportTripDuration        = '/reports/trip-duration';
  static const reportWeightVariance      = '/reports/weight-variance';
  static const reportOverloading         = '/reports/overloading';
  // Driver & Staff
  static const reportDriverPerformance   = '/reports/driver-performance';
  static const reportAttendanceGaps      = '/reports/attendance-gaps';
  static const reportAttendanceTrend     = '/reports/attendance-trend';
  static const reportAttendanceCalendar  = '/reports/attendance-calendar';
  // Finance
  static const reportInvoiceAging        = '/reports/invoice-aging';
  static const reportRouteProfitability  = '/reports/route-profitability';
  static const reportGstSummary          = '/reports/gst-summary';
  static const reportCreditNotesReport   = '/reports/credit-notes-summary';
  static const reportClientPendingBilling= '/reports/client-pending-billing';
  static const reportTopClients          = '/reports/top-clients';
  static const reportStockLevels         = '/reports/stock-levels';

  // Tyres
  static const tyres                   = '/tyres';
  static const tyresAvailable          = '/tyres/available';
  static String tyreHistory(id)        => '/tyres/$id/history';
  static const tyrePositionsCurrent    = '/tyre-positions/current';
  static const tyreFittings            = '/tyre-fittings';
  static String tyreFittingRemove(id)  => '/tyre-fittings/$id/remove';
  static const tyreRotations           = '/tyre-rotations';
  static const tyreRequests            = '/tyre-requests';
  static const tyreRequestsMy         = '/tyre-requests/my';
  static const tyreRequestsPending    = '/tyre-requests/pending';
  static String approveTyreRequest(id) => '/tyre-requests/$id/approve';
  static String rejectTyreRequest(id)  => '/tyre-requests/$id/reject';

  // Upload
  static const upload                  = '/upload';
}
