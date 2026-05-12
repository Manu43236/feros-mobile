class LrModel {
  final int id;
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

  LrModel({
    required this.id,
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
  });

  factory LrModel.fromJson(Map<String, dynamic> j) => LrModel(
    id:              j['id'] as int? ?? 0,
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
  );
}
