import 'package:get/get.dart';

/// Converts an API status string to a localized display label.
/// Use this everywhere status values from the API need to be shown in the UI.
///
/// Example:
///   Text(statusLabel(service['status']))
///   Text(statusLabel('IN_PROGRESS'))  // → 'In Progress' (en) / 'ఇన్ ప్రోగ్రెస్' (te)
String statusLabel(String? apiStatus) {
  if (apiStatus == null || apiStatus.isEmpty) return '';
  final key = _statusKeyMap[apiStatus.toUpperCase()];
  if (key != null) return key.tr;
  // Fallback: convert SNAKE_CASE to Title Case for unknown statuses
  return apiStatus
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}

const _statusKeyMap = <String, String>{
  // ── Generic ───────────────────────────────────────────────────────────────
  'ALL':              'lbl_all',
  'ACTIVE':           'status_active',
  'INACTIVE':         'lbl_inactive',

  // ── Orders / LRs ──────────────────────────────────────────────────────────
  'PENDING':          'status_pending',
  'CREATED':          'status_created',
  'IN_TRANSIT':       'status_in_transit',
  'DELIVERED':        'status_delivered',
  'INVOICED':         'status_invoiced',
  'LOADED':           'status_loaded',
  'CANCELLED':        'status_cancelled',

  // ── Services ──────────────────────────────────────────────────────────────
  'OPEN':             'status_open',
  'IN_PROGRESS':      'status_in_progress',
  'COMPLETED':        'status_completed',
  'IN_REPAIR':        'status_in_repair',
  'RESOLVED':         'status_resolved',
  'VEHICLE_REPLACED': 'status_resolved',

  // ── Requests / Approvals ──────────────────────────────────────────────────
  'APPROVED':         'status_approved',
  'REJECTED':         'status_rejected',
  'REQUESTED':        'status_requested',

  // ── Finance ───────────────────────────────────────────────────────────────
  'DRAFT':            'status_draft',
  'SENT':             'status_sent',
  'PAID':             'status_paid',
  'OVERDUE':          'status_overdue',
  'PART_PAID':        'status_partially_paid',
  'PARTIALLY_PAID':   'status_partially_paid',

  // ── Attendance ────────────────────────────────────────────────────────────
  'PRESENT':          'status_present',
  'ABSENT':           'status_absent',
  'HALF_DAY':         'status_half_day',
  'LEAVE':            'status_leave',

  // ── Breakdowns ────────────────────────────────────────────────────────────
  'REPORTED':         'status_created',

  // ── Tires / Stock ─────────────────────────────────────────────────────────
  'ISSUED':           'status_approved',
  'LOW_STOCK':        'status_low_stock',
};
