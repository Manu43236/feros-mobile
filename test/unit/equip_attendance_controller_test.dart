import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:feros/core/api/api_client.dart';
import 'package:feros/core/api/api_endpoints.dart';
import 'package:feros/core/utils/view_state.dart';
import 'package:feros/app/modules/supervisor/supervisor_equipment_shell/attendance/controllers/equip_attendance_controller.dart';
import '../helpers/fake_api_client.dart';

void main() {
  late FakeApiClient api;
  late EquipAttendanceController ctrl;

  // All users returned by /users endpoint — mix of roles and active states.
  final allUsers = [
    {'id': 1, 'name': 'Op One',      'role': 'OPERATOR', 'isActive': true},
    {'id': 2, 'name': 'Op Two',      'role': 'operator', 'isActive': true}, // lowercase role
    {'id': 3, 'name': 'Driver One',  'role': 'DRIVER',   'isActive': true},
    {'id': 4, 'name': 'Cleaner One', 'role': 'CLEANER',  'isActive': true},
    {'id': 5, 'name': 'Admin User',  'role': 'ADMIN',    'isActive': true},
    {'id': 6, 'name': 'Op Inactive', 'role': 'OPERATOR', 'isActive': false},
  ];

  void stubDefaults({List? users, List? attendance}) {
    api.stubGet(ApiEndpoints.users, {'data': users ?? allUsers});
    api.stubGet(ApiEndpoints.attendance, {'data': attendance ?? []});
    api.stubGet(ApiEndpoints.attendanceTypes, {'data': [
      {'id': 1, 'name': 'Present'},
      {'id': 2, 'name': 'Absent'},
      {'id': 3, 'name': 'Half Day Present'},
    ]});
    api.stubGet(ApiEndpoints.leaveTypes, {'data': [
      {'id': 10, 'name': 'Sick Leave'},
    ]});
  }

  setUp(() {
    Get.testMode = true;
    Get.reset();
    api = FakeApiClient();
    Get.put<ApiClient>(api);
    ctrl = EquipAttendanceController();
  });

  tearDown(Get.reset);

  // ── CRITICAL: OPERATOR role filter ────────────────────────────────────────

  group('crew filter (CRITICAL)', () {
    test('includes only active OPERATOR role users', () async {
      stubDefaults();
      await ctrl.fetchAll();

      // id=1 (OPERATOR active), id=2 (operator active — case-insensitive)
      // Excluded: id=3 DRIVER, id=4 CLEANER, id=5 ADMIN, id=6 OPERATOR inactive
      expect(ctrl.crew.length, 2);
      expect(ctrl.crew.map((u) => u['id']).toList(), containsAll([1, 2]));
    });

    test('excludes DRIVER role', () async {
      stubDefaults(users: [
        {'id': 3, 'name': 'Driver', 'role': 'DRIVER', 'isActive': true},
      ]);
      await ctrl.fetchAll();
      expect(ctrl.crew, isEmpty);
    });

    test('excludes CLEANER role', () async {
      stubDefaults(users: [
        {'id': 4, 'name': 'Cleaner', 'role': 'CLEANER', 'isActive': true},
      ]);
      await ctrl.fetchAll();
      expect(ctrl.crew, isEmpty);
    });

    test('excludes inactive OPERATOR', () async {
      stubDefaults(users: [
        {'id': 6, 'name': 'Inactive Op', 'role': 'OPERATOR', 'isActive': false},
      ]);
      await ctrl.fetchAll();
      expect(ctrl.crew, isEmpty);
    });

    test('treats missing isActive as active (defaults to true)', () async {
      stubDefaults(users: [
        {'id': 7, 'name': 'Op No Flag', 'role': 'OPERATOR'}, // isActive absent
      ]);
      await ctrl.fetchAll();
      expect(ctrl.crew.length, 1);
    });
  });

  // ── State transitions ──────────────────────────────────────────────────────

  group('fetchAll state', () {
    test('sets success state when all calls succeed', () async {
      stubDefaults();
      await ctrl.fetchAll();
      expect(ctrl.state.value, ViewState.success);
    });

    test('sets error state when an API call fails', () async {
      // only stub users; attendance will throw
      api.stubGet(ApiEndpoints.users, {'data': []});
      // attendanceTypes and leaveTypes also needed
      api.stubGet(ApiEndpoints.attendanceTypes, {'data': []});
      api.stubGet(ApiEndpoints.leaveTypes, {'data': []});
      // attendance NOT stubbed → throws

      await ctrl.fetchAll();

      expect(ctrl.state.value, ViewState.error);
    });
  });

  // ── Computed properties ────────────────────────────────────────────────────

  group('computed counts', () {
    final attendance = [
      {'id': 100, 'userId': 1, 'attendanceTypeName': 'Present'},
      {'id': 101, 'userId': 2, 'attendanceTypeName': 'Absent'},
    ];

    setUp(() {
      stubDefaults(attendance: attendance);
    });

    test('present counts full-present records only', () async {
      await ctrl.fetchAll();
      expect(ctrl.present, 1); // userId=1 is Present
    });

    test('absent counts records with "absent" in type name', () async {
      await ctrl.fetchAll();
      expect(ctrl.absent, 1); // userId=2
    });

    test('unmarked = crew - marked crew', () async {
      await ctrl.fetchAll();
      // crew = [1, 2], both marked → unmarked = 0
      expect(ctrl.unmarked, 0);
    });

    test('half-day present is not counted as present', () async {
      stubDefaults(attendance: [
        {'id': 200, 'userId': 1, 'attendanceTypeName': 'Half Day Present'},
      ]);
      await ctrl.fetchAll();
      expect(ctrl.present, 0);
    });

    test('unmarkedCrew lists only crew with no record', () async {
      stubDefaults(
        users: [
          {'id': 1, 'role': 'OPERATOR', 'isActive': true, 'name': 'Op One'},
          {'id': 2, 'role': 'OPERATOR', 'isActive': true, 'name': 'Op Two'},
        ],
        attendance: [
          {'id': 100, 'userId': 1, 'attendanceTypeName': 'Present'},
        ],
      );
      await ctrl.fetchAll();
      // crew=[1,2], marked=[1] → unmarked=[2]
      expect(ctrl.unmarked, 1);
      expect(ctrl.unmarkedCrew.map((u) => u['id']).toList(), [2]);
    });
  });

  // ── Mark single ────────────────────────────────────────────────────────────

  group('markForUser', () {
    test('posts correct body and returns true', () async {
      stubDefaults();
      await ctrl.fetchAll();

      Map<String, dynamic>? capturedBody;
      api.stubPostFn(ApiEndpoints.attendance, (body) {
        capturedBody = body as Map<String, dynamic>;
        return {'data': {}};
      });
      // After mark, attendance is re-fetched — update stub to avoid reuse error
      api.stubGet(ApiEndpoints.attendance, {'data': []});

      final ok = await ctrl.markForUser(userId: 1, attendanceTypeId: 1);

      expect(ok, isTrue);
      expect(capturedBody?['userId'], 1);
      expect(capturedBody?['attendanceTypeId'], 1);
      expect(capturedBody?.containsKey('attendanceDate'), isTrue);
    });

    test('includes leaveTypeId and remarks when provided', () async {
      stubDefaults();
      await ctrl.fetchAll();

      Map<String, dynamic>? capturedBody;
      api.stubPostFn(ApiEndpoints.attendance, (body) {
        capturedBody = body as Map<String, dynamic>;
        return {'data': {}};
      });
      api.stubGet(ApiEndpoints.attendance, {'data': []});

      await ctrl.markForUser(
        userId: 1,
        attendanceTypeId: 2,
        leaveTypeId: 10,
        remarks: 'Fever',
      );

      expect(capturedBody?['leaveTypeId'], 10);
      expect(capturedBody?['remarks'], 'Fever');
    });

    test('returns false when API fails', () async {
      stubDefaults();
      await ctrl.fetchAll();
      // no POST stub → throws

      final ok = await ctrl.markForUser(userId: 1, attendanceTypeId: 1);

      expect(ok, isFalse);
      expect(ctrl.markLoading.value, isFalse); // cleared in finally
    });
  });

  // ── Bulk mark ──────────────────────────────────────────────────────────────

  group('markBulkPresent', () {
    test('returns true immediately when no unmarked crew', () async {
      stubDefaults(
        users: [{'id': 1, 'role': 'OPERATOR', 'isActive': true}],
        attendance: [
          {'id': 100, 'userId': 1, 'attendanceTypeName': 'Present'},
        ],
      );
      await ctrl.fetchAll();
      // All crew already marked
      expect(ctrl.unmarkedCrew, isEmpty);

      final ok = await ctrl.markBulkPresent(1);
      expect(ok, isTrue);
    });

    test('posts only unmarked crew members to bulk endpoint', () async {
      stubDefaults(
        users: [
          {'id': 1, 'role': 'OPERATOR', 'isActive': true},
          {'id': 2, 'role': 'OPERATOR', 'isActive': true},
          {'id': 3, 'role': 'OPERATOR', 'isActive': true},
        ],
        attendance: [
          {'id': 100, 'userId': 1, 'attendanceTypeName': 'Present'},
        ],
      );
      await ctrl.fetchAll();

      Map<String, dynamic>? capturedBody;
      api.stubPostFn(ApiEndpoints.attendanceBulk, (body) {
        capturedBody = body as Map<String, dynamic>;
        return {'data': {}};
      });
      api.stubGet(ApiEndpoints.attendance, {'data': []});

      final ok = await ctrl.markBulkPresent(1);

      expect(ok, isTrue);
      final entries = capturedBody?['entries'] as List?;
      // Only users 2 and 3 are unmarked
      expect(entries?.length, 2);
      expect(entries?.map((e) => e['userId']).toSet(), {2, 3});
    });

    test('returns false and clears bulkLoading on API error', () async {
      stubDefaults(
        users: [{'id': 1, 'role': 'OPERATOR', 'isActive': true}],
      );
      await ctrl.fetchAll();
      // no bulk stub → throws

      final ok = await ctrl.markBulkPresent(1);

      expect(ok, isFalse);
      expect(ctrl.bulkLoading.value, isFalse);
    });
  });
}
