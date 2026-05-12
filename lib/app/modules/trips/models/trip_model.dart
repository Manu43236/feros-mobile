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
    orderNumber:   j['orderNumber']  as String? ?? '—',
    status:        j['status']       as String? ?? '—',
    clientName:    j['clientName']   as String? ??
                   (j['client'] as Map?)?.get('name') ?? '—',
    fromLocation:  j['fromLocation'] as String? ??
                   (j['route'] as Map?)?.get('source') ?? '—',
    toLocation:    j['toLocation']   as String? ??
                   (j['route'] as Map?)?.get('destination') ?? '—',
    vehicleNumber: j['vehicleNumber'] as String? ??
                   (j['vehicle'] as Map?)?.get('registrationNumber'),
    lrNumber:      j['lrNumber']     as String?,
    weight:        (j['weight'] as num?)?.toDouble(),
    materialType:  j['materialType'] as String?,
    scheduledDate: j['scheduledDate'] as String? ?? j['orderDate'] as String?,
    completedDate: j['completedDate'] as String?,
    driverName:    j['driverName']   as String?,
  );
}

extension _MapGet on Map {
  dynamic get(String key) => this[key];
}
