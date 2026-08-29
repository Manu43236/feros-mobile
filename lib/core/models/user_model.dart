class UserModel {
  final int userId;
  final int? tenantId;
  final String phone;
  final String name;
  final String role;
  final String? companyName;
  final String token;
  final bool isPinResetRequired;
  final String? profilePhotoUrl;
  final String? moduleType;
  final bool canAccessVehicles;
  final bool canAccessEquipment;
  final bool canAccessLeases;

  UserModel({
    required this.userId,
    this.tenantId,
    required this.phone,
    required this.name,
    required this.role,
    this.companyName,
    required this.token,
    this.isPinResetRequired = false,
    this.profilePhotoUrl,
    this.moduleType,
    this.canAccessVehicles = true,
    this.canAccessEquipment = false,
    this.canAccessLeases = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId:             json['userId'] as int,
    tenantId:           json['tenantId'] as int?,
    phone:              json['phone']   as String,
    name:               json['name']    as String? ?? '',
    role:               json['role']    as String,
    companyName:        json['companyName'] as String?,
    token:              json['token']   as String? ?? '',
    isPinResetRequired: json['isPinResetRequired'] as bool? ?? false,
    profilePhotoUrl:    json['profilePhotoUrl'] as String?,
    moduleType:         json['moduleType'] as String?,
    canAccessVehicles:  json['canAccessVehicles'] as bool? ?? true,
    canAccessEquipment: json['canAccessEquipment'] as bool? ?? false,
    canAccessLeases:    json['canAccessLeases'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'userId':             userId,
    'tenantId':           tenantId,
    'phone':              phone,
    'name':               name,
    'role':               role,
    'companyName':        companyName,
    'token':              token,
    'isPinResetRequired': isPinResetRequired,
    'profilePhotoUrl':    profilePhotoUrl,
    'moduleType':         moduleType,
    'canAccessVehicles':  canAccessVehicles,
    'canAccessEquipment': canAccessEquipment,
    'canAccessLeases':    canAccessLeases,
  };

  UserModel copyWith({String? profilePhotoUrl}) => UserModel(
    userId: userId, tenantId: tenantId, phone: phone, name: name,
    role: role, companyName: companyName, token: token,
    isPinResetRequired: isPinResetRequired,
    profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    moduleType: moduleType,
    canAccessVehicles: canAccessVehicles,
    canAccessEquipment: canAccessEquipment,
    canAccessLeases: canAccessLeases,
  );

  bool get isSuperAdmin      => role == 'SUPER_ADMIN';
  bool get isAdmin           => role == 'ADMIN';
  bool get isOfficeStaff     => role == 'OFFICE_STAFF';
  bool get isSupervisor      => role == 'SUPERVISOR';
  bool get isDriver          => role == 'DRIVER';
  bool get isCleaner         => role == 'CLEANER';
  bool get isServiceManager  => role == 'SERVICE_MANAGER';
  bool get isStoreKeeper     => role == 'STORE_KEEPER';
  bool get isFieldWorker     => isDriver || isCleaner || isSupervisor;

  // Rental supervisor = has equipment or leases but NOT vehicles
  bool get isRentalSupervisor =>
      isSupervisor && !canAccessVehicles && (canAccessEquipment || canAccessLeases);
}
