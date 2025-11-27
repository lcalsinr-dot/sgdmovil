class Registration {
  final String id;
  final String dni;
  final String fullName;
  final String activityId;
  final String workshopId;
  final String sessionId;
  final String siteId;
  final bool hasAttended;
  final DateTime registrationDate;
  final DateTime? attendanceDate;
  final String? padronId; // Nuevo campo para identificador de padrón

  Registration({
    required this.id,
    required this.dni,
    required this.fullName,
    required this.activityId,
    required this.workshopId,
    required this.sessionId,
    required this.siteId,
    this.hasAttended = false,
    required this.registrationDate,
    this.attendanceDate,
    this.padronId, // Parámetro opcional para identificador de padrón
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dni': dni,
      'fullName': fullName,
      'activityId': activityId,
      'workshopId': workshopId,
      'sessionId': sessionId,
      'siteId': siteId,
      'hasAttended': hasAttended ? 1 : 0,
      'registrationDate': registrationDate.toIso8601String(),
      'attendanceDate': attendanceDate?.toIso8601String(),
      'padronId': padronId, // Incluir identificador de padrón en el mapa
    };
  }

  factory Registration.fromMap(Map<String, dynamic> map) {
    return Registration(
      id: map['id'],
      dni: map['dni'],
      fullName: map['fullName'],
      activityId: map['activityId'],
      workshopId: map['workshopId'],
      sessionId: map['sessionId'],
      siteId: map['siteId'],
      hasAttended: map['hasAttended'] == 1,
      registrationDate: DateTime.parse(map['registrationDate']),
      attendanceDate: map['attendanceDate'] != null 
          ? DateTime.parse(map['attendanceDate']) 
          : null,
      padronId: map['padronId'], // Extraer identificador de padrón del mapa
    );
  }

  // Crea una copia del objeto con propiedades actualizadas
  Registration copyWith({
    String? id,
    String? dni,
    String? fullName,
    String? activityId,
    String? workshopId,
    String? sessionId,
    String? siteId,
    bool? hasAttended,
    DateTime? registrationDate,
    DateTime? attendanceDate,
    String? padronId, // Incluir identificador de padrón en copyWith
  }) {
    return Registration(
      id: id ?? this.id,
      dni: dni ?? this.dni,
      fullName: fullName ?? this.fullName,
      activityId: activityId ?? this.activityId,
      workshopId: workshopId ?? this.workshopId,
      sessionId: sessionId ?? this.sessionId,
      siteId: siteId ?? this.siteId,
      hasAttended: hasAttended ?? this.hasAttended,
      registrationDate: registrationDate ?? this.registrationDate,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      padronId: padronId ?? this.padronId, // Mantener identificador de padrón en la copia
    );
  }
}