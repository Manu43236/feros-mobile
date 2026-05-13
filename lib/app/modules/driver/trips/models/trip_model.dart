class TripModel {
  final int id;
  final String orderNumber;
  final String status;
  final String clientName;
  final String fromLocation;
  final String toLocation;
  final String? vehicleNumber;
  final String? lrNumber;
  final double? weight;
  final String? materialType;
  final String? scheduledDate;
  final String? completedDate;
  final String? driverName;

  TripModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.clientName,
    required this.fromLocation,
    required this.toLocation,
    this.vehicleNumber,
    this.lrNumber,
    this.weight,
    this.materialType,
    this.scheduledDate,
    this.completedDate,
    this.driverName,
  });

  factory TripModel.fromJson(Map<String, dynamic> j) => TripModel(
    id:            j['id'] as int? ?? 0,
    orderNumber:   j['orderNumber']    as String? ?? '—',
    status:        j['orderStatus']    as String? ?? j['status'] as String? ?? '—',
    clientName:    j['clientName']     as String? ?? '—',
    fromLocation:  j['sourceCityName'] as String? ?? j['fromLocation'] as String? ?? '—',
    toLocation:    j['destinationCityName'] as String? ?? j['toLocation'] as String? ?? '—',
    vehicleNumber: _firstVehicleNumber(j),
    lrNumber:      j['lrNumber']       as String?,
    weight:        (j['totalWeight']   as num?)?.toDouble() ?? (j['weight'] as num?)?.toDouble(),
    materialType:  j['materialTypeName'] as String? ?? j['materialType'] as String?,
    scheduledDate: j['orderDate']      as String? ?? j['scheduledDate'] as String?,
    completedDate: j['completedDate']  as String?,
    driverName:    j['driverName']     as String?,
  );
}

String? _firstVehicleNumber(Map<String, dynamic> j) {
  final allocs = j['vehicleAllocations'] as List?;
  if (allocs != null && allocs.isNotEmpty) {
    return (allocs.first as Map<String, dynamic>)['vehicleRegistrationNumber'] as String?;
  }
  return j['vehicleNumber'] as String?;
}

extension _MapGet on Map {
  dynamic get(String key) => this[key];
}
