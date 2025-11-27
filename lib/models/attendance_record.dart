class AttendanceRecord {
  final String id;
  final DateTime timestamp;
  final String sessionId;
  final String? personName;
  final String? activityId;
  final String? activityName;
  final String? workshopId;
  final String? workshopName;
  final String? sessionName;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? deviceInfo;  
  final String? padronId;    
  final String? dni;         

  AttendanceRecord({
    required this.id,
    required this.timestamp,
    required this.sessionId,
    this.personName,
    this.activityId,
    this.activityName,
    this.workshopId,
    this.workshopName,
    this.sessionName,
    this.latitude,
    this.longitude,
    this.locationName,
    this.deviceInfo,
    this.padronId,    
    this.dni,         
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'personName': personName,
      'activityId': activityId,
      'activityName': activityName,
      'workshopId': workshopId,
      'workshopName': workshopName,
      'sessionName': sessionName,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'deviceInfo': deviceInfo,
      'padronId': padronId,    
      'dni': dni,              
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      sessionId: map['sessionId'],
      personName: map['personName'],
      activityId: map['activityId'],
      activityName: map['activityName'],
      workshopId: map['workshopId'],
      workshopName: map['workshopName'],
      sessionName: map['sessionName'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      locationName: map['locationName'],
      deviceInfo: map['deviceInfo'],
      padronId: map['padronId'],
      dni: map['dni'],
    );
  }

  // Crear una copia con valores actualizados
  AttendanceRecord copyWith({
    String? id,
    DateTime? timestamp,
    String? sessionId,
    String? personName,
    String? activityId,
    String? activityName,
    String? workshopId,
    String? workshopName,
    String? sessionName,
    double? latitude,
    double? longitude,
    String? locationName,
    String? deviceInfo,
    String? padronId,
    String? dni,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      personName: personName ?? this.personName,
      activityId: activityId ?? this.activityId,
      activityName: activityName ?? this.activityName,
      workshopId: workshopId ?? this.workshopId,
      workshopName: workshopName ?? this.workshopName,
      sessionName: sessionName ?? this.sessionName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      padronId: padronId ?? this.padronId,
      dni: dni ?? this.dni,
    );
  }
}