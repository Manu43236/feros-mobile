class LrModel {
  final int id;
  final int? allocationId;
  final String lrNumber;
  final String lrStatus;
  final String orderNumber;
  final int orderId;
  final String clientName;
  final String vehicleNumber;
  final String? vehicleTypeName;
  final String fromCity;
  final String toCity;
  final double allocatedWeight;
  final double? loadedWeight;
  final double? deliveredWeight;
  final String lrDate;
  final double? currentVehicleOdometer;
  final double? startOdometer;
  final String? startOdometerRecordedAt;
  final double? endOdometer;
  final String? endOdometerRecordedAt;
  final String? startedByName;
  final String? startedByRole;
  final String? completedByName;
  final String? completedByRole;
  final int? vehicleId;

  LrModel({
    required this.id,
    this.allocationId,
    required this.lrNumber,
    required this.lrStatus,
    required this.orderNumber,
    required this.orderId,
    required this.clientName,
    required this.vehicleNumber,
    this.vehicleTypeName,
    required this.fromCity,
    required this.toCity,
    required this.allocatedWeight,
    this.loadedWeight,
    this.deliveredWeight,
    required this.lrDate,
    this.currentVehicleOdometer,
    this.startOdometer,
    this.startOdometerRecordedAt,
    this.endOdometer,
    this.endOdometerRecordedAt,
    this.startedByName,
    this.startedByRole,
    this.completedByName,
    this.completedByRole,
    this.vehicleId,
  });

  factory LrModel.fromJson(Map<String, dynamic> j) => LrModel(
    id:              j['id'] as int? ?? 0,
    allocationId:    j['vehicleAllocationId']       as int?,
    lrNumber:        j['lrNumber']                  as String? ?? '—',
    lrStatus:        j['lrStatus']                  as String? ?? 'CREATED',
    orderNumber:     j['orderNumber']               as String? ?? '—',
    orderId:         j['orderId']                   as int? ?? 0,
    clientName:      j['clientName']                as String? ?? '—',
    vehicleNumber:   j['vehicleRegistrationNumber'] as String? ?? '—',
    vehicleTypeName: j['vehicleTypeName']           as String?,
    fromCity:        j['fromCity']                  as String? ?? '—',
    toCity:          j['toCity']                    as String? ?? '—',
    allocatedWeight: (j['allocatedWeight']          as num?)?.toDouble() ?? 0,
    loadedWeight:    (j['loadedWeight']             as num?)?.toDouble(),
    deliveredWeight: (j['deliveredWeight']          as num?)?.toDouble(),
    lrDate:          j['lrDate']                    as String? ?? '—',
    currentVehicleOdometer: (j['currentVehicleOdometer'] as num?)?.toDouble(),
    startOdometer:            (j['startOdometer']            as num?)?.toDouble(),
    startOdometerRecordedAt:   j['startOdometerRecordedAt']  as String?,
    endOdometer:              (j['endOdometer']              as num?)?.toDouble(),
    endOdometerRecordedAt:     j['endOdometerRecordedAt']    as String?,
    startedByName:             j['startedByName']            as String?,
    startedByRole:   j['startedByRole']             as String?,
    completedByName: j['completedByName']           as String?,
    completedByRole: j['completedByRole']           as String?,
    vehicleId:       j['vehicleId']                 as int?,
  );
}
