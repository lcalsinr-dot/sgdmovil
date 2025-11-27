import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/attendance_record.dart';
import '../models/user.dart';
import '../models/activity.dart';
import '../models/workshop.dart';
import '../models/session.dart';
import '../models/registration.dart';
import '../utils/encryption_util.dart';

class EncryptedDatabaseHelper {
  static final EncryptedDatabaseHelper _instance =
      EncryptedDatabaseHelper._internal();
  static Database? _database;
  final EncryptionUtil _encryptionUtil = EncryptionUtil();

  // Nombre de la base de datos y versión
  static const String _databaseName = 'srciam.db';
  static const int _databaseVersion =
      2; // Incrementado para incluir nuevos campos

  // Tablas
  static const String tableAttendance = 'attendance';
  static const String tableUsers = 'users';
  static const String tableActivities = 'activities';
  static const String tableWorkshops = 'workshops';
  static const String tableSessions = 'sessions';
  static const String tableRegistrations = 'registrations';

  // Columnas comunes
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnDescription = 'description';
  static const String columnSiteId = 'site_id';
  static const String columnTimestamp = 'timestamp';
  static const String columnEncrypted = 'encrypted_data';
  static const String columnSyncStatus =
      'sync_status'; // Columna para estado de sincronización

  // Columnas específicas de usuarios
  static const String columnEmail = 'email';
  static const String columnFirstName = 'first_name';
  static const String columnLastName = 'last_name';
  static const String columnDni = 'dni';
  static const String columnToken = 'token';

  // Columnas específicas de workshops
  static const String columnActivityId = 'activity_id';

  // Columnas específicas de sessions
  static const String columnWorkshopId = 'workshop_id';
  static const String columnDate = 'date';

  // Columnas específicas de attendance
  static const String columnSessionId = 'session_id';
  static const String columnDniNumber = 'dni_number';
  static const String columnPersonName = 'person_name';
  static const String columnLatitude = 'latitude';
  static const String columnLongitude = 'longitude';
  static const String columnLocationName = 'location_name';
  static const String columnDeviceInfo =
      'device_info'; // Nueva columna para información del dispositivo
  static const String columnPadronId =
      'padron_id'; // Nueva columna para identificador del padrón
  static const String columnPadronDni =
      'padron_dni'; // Nueva columna para DNI del padrón

  // Columnas específicas de registrations
  static const String columnFullName = 'full_name';
  static const String columnHasAttended = 'has_attended';
  static const String columnRegistrationDate = 'registration_date';
  static const String columnAttendanceDate = 'attendance_date';

  // Columnas adicionales para nombres descriptivos
  static const String columnActivityName = 'activity_name';
  static const String columnWorkshopName = 'workshop_name';
  static const String columnSessionName = 'session_name';

  factory EncryptedDatabaseHelper() {
    return _instance;
  }

  EncryptedDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializar la base de datos
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Añadir manejador de actualización
    );
  }

  // Crear las tablas de la base de datos
  Future _onCreate(Database db, int version) async {
    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE $tableUsers (
        $columnId TEXT PRIMARY KEY,
        $columnEmail TEXT NOT NULL,
        $columnFirstName TEXT NOT NULL,
        $columnLastName TEXT NOT NULL,
        $columnSiteId TEXT NOT NULL,
        $columnDni TEXT NOT NULL,
        $columnToken TEXT
      )
    ''');

    // Tabla de actividades (con siteId)
    await db.execute('''
      CREATE TABLE $tableActivities (
        $columnId TEXT PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnDescription TEXT,
        $columnSiteId TEXT NOT NULL
      )
    ''');

    // Tabla de talleres (con siteId)
    await db.execute('''
      CREATE TABLE $tableWorkshops (
        $columnId TEXT PRIMARY KEY,
        $columnActivityId TEXT NOT NULL,
        $columnName TEXT NOT NULL,
        $columnSiteId TEXT NOT NULL,
        FOREIGN KEY ($columnActivityId) REFERENCES $tableActivities ($columnId)
      )
    ''');

    // Tabla de sesiones (con siteId)
    await db.execute('''
      CREATE TABLE $tableSessions (
        $columnId TEXT PRIMARY KEY,
        $columnWorkshopId TEXT NOT NULL,
        $columnName TEXT NOT NULL,
        $columnDate TEXT NOT NULL,
        $columnSiteId TEXT NOT NULL,
        FOREIGN KEY ($columnWorkshopId) REFERENCES $tableWorkshops ($columnId)
      )
    ''');

    // Tabla de registros de asistencia (encriptados)
    await db.execute('''
      CREATE TABLE $tableAttendance (
        $columnId TEXT PRIMARY KEY,
        $columnSessionId TEXT NOT NULL,
        $columnTimestamp TEXT NOT NULL,
        $columnEncrypted TEXT NOT NULL,
        $columnSyncStatus INTEGER DEFAULT 0,
        FOREIGN KEY ($columnSessionId) REFERENCES $tableSessions ($columnId)
      )
    ''');

    // Tabla de padrón de inscritos
    await db.execute('''
      CREATE TABLE $tableRegistrations (
        $columnId TEXT PRIMARY KEY,
        $columnDni TEXT NOT NULL,
        $columnFullName TEXT NOT NULL,
        $columnActivityId TEXT NOT NULL,
        $columnWorkshopId TEXT NOT NULL,
        $columnSessionId TEXT NOT NULL,
        $columnSiteId TEXT NOT NULL,
        $columnHasAttended INTEGER DEFAULT 0,
        $columnRegistrationDate TEXT NOT NULL,
        $columnAttendanceDate TEXT,
        $columnPadronId TEXT,
        $columnSyncStatus INTEGER DEFAULT 0,
        FOREIGN KEY ($columnSessionId) REFERENCES $tableSessions ($columnId),
        FOREIGN KEY ($columnWorkshopId) REFERENCES $tableWorkshops ($columnId),
        FOREIGN KEY ($columnActivityId) REFERENCES $tableActivities ($columnId)
      )
    ''');
  }

  // Método para actualizar la base de datos si se necesita una migración
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Actualizando base de datos de versión $oldVersion a $newVersion');

    if (oldVersion < 2) {
      // Si estás actualizando a la versión 2 o superior desde una versión anterior

      // Verificar si la columna ya existe en la tabla registrations
      var tableInfo = await db.rawQuery(
        "PRAGMA table_info($tableRegistrations)",
      );
      bool padronIdExists = tableInfo.any(
        (column) => column['name'] == columnPadronId,
      );

      if (!padronIdExists) {
        // Añadir columna de padron_id a tabla registrations si no existe
        await db.execute(
          'ALTER TABLE $tableRegistrations ADD COLUMN $columnPadronId TEXT;',
        );
      }

      // No necesitamos modificar la tabla de attendance porque
      // los nuevos campos se almacenan en el campo encriptado
    }
  }

  // ----- MÉTODOS PARA USUARIO -----

  Future<void> saveUser(User user) async {
    final db = await database;

    // Verificar si el usuario ya existe
    final existingUser = await db.query(
      tableUsers,
      where: '$columnId = ?',
      whereArgs: [user.id],
    );

    if (existingUser.isEmpty) {
      // Insertar nuevo usuario
      await db.insert(tableUsers, {
        columnId: user.id,
        columnEmail: user.email,
        columnFirstName: user.firstName,
        columnLastName: user.lastName,
        columnSiteId: user.siteId,
        columnDni: user.dni,
        columnToken: user.token,
      });
    } else {
      // Actualizar usuario existente
      await db.update(
        tableUsers,
        {
          columnEmail: user.email,
          columnFirstName: user.firstName,
          columnLastName: user.lastName,
          columnSiteId: user.siteId,
          columnDni: user.dni,
          columnToken: user.token,
        },
        where: '$columnId = ?',
        whereArgs: [user.id],
      );
    }
  }

  Future<User?> getUser(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUsers,
      where: '$columnId = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User(
        id: maps[0][columnId],
        email: maps[0][columnEmail],
        password: '',
        firstName: maps[0][columnFirstName],
        lastName: maps[0][columnLastName],
        siteId: maps[0][columnSiteId],
        dni: maps[0][columnDni],
        token: maps[0][columnToken],
      );
    }
    return null;
  }

  Future<User?> getCurrentUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableUsers);

    if (maps.isNotEmpty) {
      return User(
        id: maps[0][columnId],
        email: maps[0][columnEmail],
        password: '',
        firstName: maps[0][columnFirstName],
        lastName: maps[0][columnLastName],
        siteId: maps[0][columnSiteId],
        dni: maps[0][columnDni],
        token: maps[0][columnToken],
      );
    }
    return null;
  }

  // ----- MÉTODOS PARA ACTIVIDADES -----

  Future<void> saveActivities(List<Activity> activities) async {
    final db = await database;

    // Utilizar una transacción para mejorar el rendimiento
    await db.transaction((txn) async {
      // Limpiar tabla de actividades
      await txn.delete(tableActivities);

      // Insertar las nuevas actividades
      for (var activity in activities) {
        await txn.insert(tableActivities, {
          columnId: activity.id,
          columnName: activity.name,
          columnDescription: activity.description ?? '',
          columnSiteId: activity.siteId,
        });
      }
    });
  }

  Future<List<Activity>> getActivitiesBySite(String siteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableActivities,
      where: '$columnSiteId = ?',
      whereArgs: [siteId],
    );

    return List.generate(maps.length, (i) {
      return Activity(
        id: maps[i][columnId],
        name: maps[i][columnName],
        description: maps[i][columnDescription],
        siteId: maps[i][columnSiteId],
      );
    });
  }

  // ----- MÉTODOS PARA TALLERES -----

  Future<void> saveWorkshops(List<Workshop> workshops) async {
    final db = await database;

    await db.transaction((txn) async {
      // Limpiar tabla de talleres
      await txn.delete(tableWorkshops);

      // Insertar los nuevos talleres
      for (var workshop in workshops) {
        await txn.insert(tableWorkshops, {
          columnId: workshop.id,
          columnActivityId: workshop.activityId,
          columnName: workshop.name,
          columnSiteId: workshop.siteId,
        });
      }
    });
  }

  Future<List<Workshop>> getWorkshopsBySite(String siteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableWorkshops,
      where: '$columnSiteId = ?',
      whereArgs: [siteId],
    );

    return List.generate(maps.length, (i) {
      return Workshop(
        id: maps[i][columnId],
        activityId: maps[i][columnActivityId],
        name: maps[i][columnName],
        siteId: maps[i][columnSiteId],
      );
    });
  }

  Future<List<Workshop>> getWorkshopsByActivity(
    String activityId,
    String siteId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableWorkshops,
      where: '$columnActivityId = ? AND $columnSiteId = ?',
      whereArgs: [activityId, siteId],
    );

    return List.generate(maps.length, (i) {
      return Workshop(
        id: maps[i][columnId],
        activityId: maps[i][columnActivityId],
        name: maps[i][columnName],
        siteId: maps[i][columnSiteId],
      );
    });
  }

  // ----- MÉTODOS PARA SESIONES -----

  Future<void> saveSessions(List<Session> sessions) async {
    final db = await database;

    await db.transaction((txn) async {
      // Limpiar tabla de sesiones
      await txn.delete(tableSessions);

      // Insertar las nuevas sesiones
      for (var session in sessions) {
        await txn.insert(tableSessions, {
          columnId: session.id,
          columnWorkshopId: session.workshopId,
          columnName: session.name,
          columnDate: session.date.toIso8601String(),
          columnSiteId: session.siteId,
        });
      }
    });
  }

  Future<List<Session>> getSessionsBySite(String siteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableSessions,
      where: '$columnSiteId = ?',
      whereArgs: [siteId],
    );

    return List.generate(maps.length, (i) {
      return Session(
        id: maps[i][columnId],
        workshopId: maps[i][columnWorkshopId],
        name: maps[i][columnName],
        date: DateTime.parse(maps[i][columnDate]),
        siteId: maps[i][columnSiteId],
      );
    });
  }

  Future<List<Session>> getSessionsByWorkshop(
    String workshopId,
    String siteId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableSessions,
      where: '$columnWorkshopId = ? AND $columnSiteId = ?',
      whereArgs: [workshopId, siteId],
    );

    return List.generate(maps.length, (i) {
      return Session(
        id: maps[i][columnId],
        workshopId: maps[i][columnWorkshopId],
        name: maps[i][columnName],
        date: DateTime.parse(maps[i][columnDate]),
        siteId: maps[i][columnSiteId],
      );
    });
  }

  // ----- MÉTODOS PARA PADRÓN DE INSCRITOS -----

  Future<void> saveSessionRegistrations(
    List<Registration> registrations,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      // Si hay registros para procesar
      if (registrations.isNotEmpty) {
        String sessionId = registrations.first.sessionId;
        String workshopId = registrations.first.workshopId;
        String activityId = registrations.first.activityId;
        String siteId = registrations.first.siteId;

        // Eliminamos solo los registros que no están marcados como asistencia (para preservar las asistencias tomadas)
        await txn.delete(
          tableRegistrations,
          where:
              '$columnSessionId = ? AND $columnWorkshopId = ? AND $columnActivityId = ? AND $columnSiteId = ? AND $columnHasAttended = 0',
          whereArgs: [sessionId, workshopId, activityId, siteId],
        );

        // Insertar los nuevos registros, pero respetando los existentes
        for (var reg in registrations) {
          // Verificar si ya existe este registro
          final existing = await txn.query(
            tableRegistrations,
            where: '$columnDni = ? AND $columnSessionId = ?',
            whereArgs: [reg.dni, reg.sessionId],
          );

          if (existing.isEmpty) {
            // Si no existe, lo insertamos
            await txn.insert(
              tableRegistrations,
              {
                columnId: reg.id,
                columnDni: reg.dni,
                columnFullName: reg.fullName,
                columnActivityId: reg.activityId,
                columnWorkshopId: reg.workshopId,
                columnSessionId: reg.sessionId,
                columnSiteId: reg.siteId,
                columnHasAttended: reg.hasAttended ? 1 : 0,
                columnRegistrationDate: reg.registrationDate.toIso8601String(),
                columnAttendanceDate: reg.attendanceDate?.toIso8601String(),
                columnPadronId: reg.padronId, // Incluir identificador de padrón
                columnSyncStatus: 0,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore, // Ignorar conflictos
            );
          }
        }
      }
    });
  }

  Future<List<Registration>> getSessionRegistrations(
    String sessionId,
    String workshopId,
    String activityId,
    String siteId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableRegistrations,
      where:
          '$columnSessionId = ? AND $columnWorkshopId = ? AND $columnActivityId = ? AND $columnSiteId = ?',
      whereArgs: [sessionId, workshopId, activityId, siteId],
    );

    return List.generate(maps.length, (i) {
      return Registration(
        id: maps[i][columnId],
        dni: maps[i][columnDni],
        fullName: maps[i][columnFullName],
        activityId: maps[i][columnActivityId],
        workshopId: maps[i][columnWorkshopId],
        sessionId: maps[i][columnSessionId],
        siteId: maps[i][columnSiteId],
        hasAttended: maps[i][columnHasAttended] == 1,
        registrationDate: DateTime.parse(maps[i][columnRegistrationDate]),
        attendanceDate:
            maps[i][columnAttendanceDate] != null
                ? DateTime.parse(maps[i][columnAttendanceDate])
                : null,
        padronId: maps[i][columnPadronId], // Extraer identificador de padrón
      );
    });
  }

  Future<Registration?> getRegistrationByDni(
    String sessionId,
    String dni,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableRegistrations,
      where: '$columnSessionId = ? AND $columnDni = ?',
      whereArgs: [sessionId, dni],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Registration(
        id: maps[0][columnId],
        dni: maps[0][columnDni],
        fullName: maps[0][columnFullName],
        activityId: maps[0][columnActivityId],
        workshopId: maps[0][columnWorkshopId],
        sessionId: maps[0][columnSessionId],
        siteId: maps[0][columnSiteId],
        hasAttended: maps[0][columnHasAttended] == 1,
        registrationDate: DateTime.parse(maps[0][columnRegistrationDate]),
        attendanceDate:
            maps[0][columnAttendanceDate] != null
                ? DateTime.parse(maps[0][columnAttendanceDate])
                : null,
        padronId: maps[0][columnPadronId], // Extraer identificador de padrón
      );
    }
    return null;
  }

  Future<int> updateAttendanceStatus(
    String registrationId,
    bool hasAttended,
  ) async {
    final db = await database;
    return await db.update(
      tableRegistrations,
      {
        columnHasAttended: hasAttended ? 1 : 0,
        columnAttendanceDate:
            hasAttended ? DateTime.now().toIso8601String() : null,
        columnSyncStatus: 0, // Pendiente de sincronizar
      },
      where: '$columnId = ?',
      whereArgs: [registrationId],
    );
  }

  // ----- MÉTODOS PARA REGISTROS DE ASISTENCIA -----

  Future<int> insertAttendanceRecord(AttendanceRecord record) async {
    final db = await database;

    // Datos a encriptar (todo excepto id, session_id y timestamp para facilitar búsquedas)
    final dataToEncrypt = {
      columnDniNumber: record.id,
      columnPersonName: record.personName ?? '',
      columnLatitude: record.latitude,
      columnLongitude: record.longitude,
      columnLocationName: record.locationName,
      columnActivityId: record.activityId,
      columnActivityName: record.activityName,
      columnWorkshopId: record.workshopId,
      columnWorkshopName: record.workshopName,
      columnSessionName: record.sessionName,
      columnDeviceInfo:
          record.deviceInfo, // Incluir información del dispositivo
      columnPadronId: record.padronId, // Incluir identificador de padrón
      columnPadronDni:
          record.dni ??
          record.id, // Incluir DNI (usar el ID si no hay DNI específico)
    };

    final encryptedData = await _encryptionUtil.encryptData(dataToEncrypt);

    final row = {
      columnId:
          record.id + '_' + DateTime.now().millisecondsSinceEpoch.toString(),
      columnSessionId: record.sessionId,
      columnTimestamp: record.timestamp.toIso8601String(),
      columnEncrypted: encryptedData,
      columnSyncStatus: 0, // 0 = pendiente de sincronizar
    };

    return await db.insert(tableAttendance, row);
  }

  Future<List<AttendanceRecord>> getAllAttendanceRecords() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableAttendance,
      orderBy: '$columnTimestamp DESC',
    );

    List<AttendanceRecord> records = [];
    for (var map in maps) {
      final encryptedData = map[columnEncrypted] as String;
      final decryptedData = await _encryptionUtil.decryptData(encryptedData);

      records.add(
        AttendanceRecord(
          id: decryptedData[columnDniNumber],
          timestamp: DateTime.parse(map[columnTimestamp]),
          sessionId: map[columnSessionId],
          personName: decryptedData[columnPersonName],
          activityId: decryptedData[columnActivityId],
          activityName: decryptedData[columnActivityName],
          workshopId: decryptedData[columnWorkshopId],
          workshopName: decryptedData[columnWorkshopName],
          sessionName: decryptedData[columnSessionName],
          latitude: decryptedData[columnLatitude],
          longitude: decryptedData[columnLongitude],
          locationName: decryptedData[columnLocationName],
          deviceInfo: decryptedData[columnDeviceInfo],
          padronId: decryptedData[columnPadronId],
          dni: decryptedData[columnPadronDni],
        ),
      );
    }

    return records;
  }

  Future<List<AttendanceRecord>> getAttendancesBySession(
    String sessionId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableAttendance,
      where: '$columnSessionId = ?',
      whereArgs: [sessionId],
      orderBy: '$columnTimestamp DESC',
    );

    List<AttendanceRecord> records = [];
    for (var map in maps) {
      final encryptedData = map[columnEncrypted] as String;
      final decryptedData = await _encryptionUtil.decryptData(encryptedData);

      records.add(
        AttendanceRecord(
          id: decryptedData[columnDniNumber],
          timestamp: DateTime.parse(map[columnTimestamp]),
          sessionId: map[columnSessionId],
          personName: decryptedData[columnPersonName],
          activityId: decryptedData[columnActivityId],
          activityName: decryptedData[columnActivityName],
          workshopId: decryptedData[columnWorkshopId],
          workshopName: decryptedData[columnWorkshopName],
          sessionName: decryptedData[columnSessionName],
          latitude: decryptedData[columnLatitude],
          longitude: decryptedData[columnLongitude],
          locationName: decryptedData[columnLocationName],
          deviceInfo: decryptedData[columnDeviceInfo],
          padronId: decryptedData[columnPadronId],
          dni: decryptedData[columnPadronDni],
        ),
      );
    }

    return records;
  }

  // Método para obtener registros pendientes de sincronización
  Future<List<AttendanceRecord>> getPendingSyncAttendances() async {
    final db = await database;

    // Asegurarnos de buscar solo registros que realmente existen
    final List<Map<String, dynamic>> maps = await db.query(
      tableAttendance,
      where: '$columnSyncStatus = ?',
      whereArgs: [0], // 0 significa pendiente de sincronizar
    );

    List<AttendanceRecord> records = [];

    for (var map in maps) {
      try {
        final encryptedData = map[columnEncrypted] as String;
        final decryptedData = await _encryptionUtil.decryptData(encryptedData);

        records.add(
          AttendanceRecord(
            id: decryptedData[columnDniNumber],
            timestamp: DateTime.parse(map[columnTimestamp]),
            sessionId: map[columnSessionId],
            personName: decryptedData[columnPersonName],
            activityId: decryptedData[columnActivityId],
            activityName: decryptedData[columnActivityName],
            workshopId: decryptedData[columnWorkshopId],
            workshopName: decryptedData[columnWorkshopName],
            sessionName: decryptedData[columnSessionName],
            latitude: decryptedData[columnLatitude],
            longitude: decryptedData[columnLongitude],
            locationName: decryptedData[columnLocationName],
            deviceInfo: decryptedData[columnDeviceInfo],
            padronId: decryptedData[columnPadronId],
            dni: decryptedData[columnPadronDni],
          ),
        );
      } catch (e) {
        print('Error al procesar registro pendiente: $e');
        // Si hay un error al procesar el registro, lo marcamos como sincronizado
        // para evitar que se quede en un estado inválido
        try {
          await db.update(
            tableAttendance,
            {columnSyncStatus: 1}, // 1 significa sincronizado
            where: '$columnId = ?',
            whereArgs: [map[columnId]],
          );
        } catch (updateError) {
          print(
            'Error al actualizar estado de registro inconsistente: $updateError',
          );
        }
      }
    }

    return records;
  }

  // Método para marcar una asistencia como sincronizada
  Future<int> markAttendanceAsSynced(String id) async {
    final db = await database;

    // Primero necesitamos encontrar todos los registros que coincidan con el ID
    final List<Map<String, dynamic>> maps = await db.query(
      tableAttendance,
      orderBy: '$columnTimestamp DESC',
    );

    List<String> recordIdsToUpdate = [];

    for (var map in maps) {
      final encryptedData = map[columnEncrypted] as String;
      final decryptedData = await _encryptionUtil.decryptData(encryptedData);

      if (decryptedData[columnDniNumber] == id) {
        recordIdsToUpdate.add(map[columnId]);
      }
    }

    if (recordIdsToUpdate.isEmpty) {
      return 0;
    }

    // Actualizar el estado de sincronización de todos los registros encontrados
    int updatedCount = 0;
    for (var recordId in recordIdsToUpdate) {
      final count = await db.update(
        tableAttendance,
        {columnSyncStatus: 1}, // 1 significa sincronizado
        where: '$columnId = ?',
        whereArgs: [recordId],
      );
      updatedCount += count;
    }

    return updatedCount;
  }

  Future<int> getAttendanceCount(String sessionId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableAttendance WHERE $columnSessionId = ?',
      [sessionId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Filtrar registros por fecha
  Future<List<AttendanceRecord>> getAttendanceRecordsByDate(
    DateTime date,
  ) async {
    final db = await database;
    final startOfDay =
        DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      tableAttendance,
      where: '$columnTimestamp BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: '$columnTimestamp DESC',
    );

    List<AttendanceRecord> records = [];
    for (var map in maps) {
      final encryptedData = map[columnEncrypted] as String;
      final decryptedData = await _encryptionUtil.decryptData(encryptedData);

      records.add(
        AttendanceRecord(
          id: decryptedData[columnDniNumber],
          timestamp: DateTime.parse(map[columnTimestamp]),
          sessionId: map[columnSessionId],
          personName: decryptedData[columnPersonName],
          activityId: decryptedData[columnActivityId],
          activityName: decryptedData[columnActivityName],
          workshopId: decryptedData[columnWorkshopId],
          workshopName: decryptedData[columnWorkshopName],
          sessionName: decryptedData[columnSessionName],
          latitude: decryptedData[columnLatitude],
          longitude: decryptedData[columnLongitude],
          locationName: decryptedData[columnLocationName],
          deviceInfo: decryptedData[columnDeviceInfo],
          padronId: decryptedData[columnPadronId],
          dni: decryptedData[columnPadronDni],
        ),
      );
    }

    return records;
  }

  // Método para obtener todas las asistencias de un día específico
  Future<List<AttendanceRecord>> getAttendancesByDay(DateTime date) async {
    final db = await database;

    // Crear rango de fechas para el día
    final startOfDay =
        DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay =
        DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
          999,
        ).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      tableAttendance,
      where: '$columnTimestamp >= ? AND $columnTimestamp <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: '$columnTimestamp DESC',
    );

    List<AttendanceRecord> records = [];

    for (var map in maps) {
      final encryptedData = map[columnEncrypted] as String;
      final decryptedData = await _encryptionUtil.decryptData(encryptedData);

      records.add(
        AttendanceRecord(
          id: decryptedData[columnDniNumber],
          timestamp: DateTime.parse(map[columnTimestamp]),
          sessionId: map[columnSessionId],
          personName: decryptedData[columnPersonName],
          activityId: decryptedData[columnActivityId],
          activityName: decryptedData[columnActivityName],
          workshopId: decryptedData[columnWorkshopId],
          workshopName: decryptedData[columnWorkshopName],
          sessionName: decryptedData[columnSessionName],
          latitude: decryptedData[columnLatitude],
          longitude: decryptedData[columnLongitude],
          locationName: decryptedData[columnLocationName],
          deviceInfo: decryptedData[columnDeviceInfo],
          padronId: decryptedData[columnPadronId],
          dni: decryptedData[columnPadronDni],
        ),
      );
    }

    return records;
  }

  // Eliminar un registro individual por ID
  Future<int> deleteAttendanceRecord(String id, String sessionId) async {
    final db = await database;

    // Primero necesitamos encontrar los registros que coincidan con el DNI (id) y sessionId
    final List<Map<String, dynamic>> maps = await db.query(
      tableAttendance,
      where: '$columnSessionId = ?',
      whereArgs: [sessionId],
      orderBy: '$columnTimestamp DESC',
    );

    List<String> recordIdsToDelete = [];

    for (var map in maps) {
      final encryptedData = map[columnEncrypted] as String;
      final decryptedData = await _encryptionUtil.decryptData(encryptedData);

      if (decryptedData[columnDniNumber] == id) {
        recordIdsToDelete.add(map[columnId]);
      }
    }

    if (recordIdsToDelete.isEmpty) {
      return 0;
    }

    // Eliminar solo los registros encontrados para esta sesión
    int deletedCount = 0;
    for (var recordId in recordIdsToDelete) {
      final count = await db.delete(
        tableAttendance,
        where: '$columnId = ?',
        whereArgs: [recordId],
      );
      deletedCount += count;
    }

    // Si hay registros relacionados en la tabla de padrón, actualizar su estado
    // pero solo para esta sesión específica
    await db.update(
      tableRegistrations,
      {
        columnHasAttended: 0, // Marcar como no asistió
        columnAttendanceDate: null, // Limpiar fecha de asistencia
        columnSyncStatus: 0, // Marcar como pendiente de sincronizar
      },
      where: '$columnDni = ? AND $columnSessionId = ?',
      whereArgs: [id, sessionId],
    );

    return deletedCount;
  }

  // Eliminar todos los registros
  Future<int> deleteAllRecords() async {
    final db = await database;
    return await db.delete(tableAttendance);
  }

  // Método para verificar si un DNI ya tiene asistencia registrada en una sesión específica para el día actual
  Future<bool> hasAttendanceInSession(String dni, String sessionId) async {
    final db = await database;

    // Obtener la fecha actual en formato ISO8601 sin la hora (solo la fecha)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Formatear fechas para la consulta
    final todayString = today.toIso8601String();
    final tomorrowString = tomorrow.toIso8601String();

    // Primero verificamos en la tabla de registros
    // Buscamos registros que tengan asistencia marcada hoy
    final registrations = await db.query(
      tableRegistrations,
      where:
          '$columnDni = ? AND $columnSessionId = ? AND $columnHasAttended = 1 AND $columnAttendanceDate >= ? AND $columnAttendanceDate < ?',
      whereArgs: [dni, sessionId, todayString, tomorrowString],
    );

    if (registrations.isNotEmpty) {
      return true;
    }

    // Luego verificamos en la tabla de asistencias
    // Solo buscamos asistencias registradas hoy
    final List<Map<String, dynamic>> maps = await db.query(
      tableAttendance,
      where:
          '$columnSessionId = ? AND $columnTimestamp >= ? AND $columnTimestamp < ?',
      whereArgs: [sessionId, todayString, tomorrowString],
    );

    for (var map in maps) {
      final encryptedData = map[columnEncrypted] as String;
      final decryptedData = await _encryptionUtil.decryptData(encryptedData);

      if (decryptedData[columnDniNumber] == dni) {
        return true;
      }
    }

    return false;
  }

  // Método para obtener información de asistencia de un DNI para el día actual
  Future<Map<String, dynamic>?> getAttendanceInfoForToday(
    String dni,
    String sessionId,
  ) async {
    final db = await database;

    // Obtener la fecha actual en formato ISO8601 sin la hora (solo la fecha)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Formatear fechas para la consulta
    final todayString = today.toIso8601String();
    final tomorrowString = tomorrow.toIso8601String();

    // Primero verificamos en la tabla de registros
    final registrations = await db.query(
      tableRegistrations,
      where:
          '$columnDni = ? AND $columnSessionId = ? AND $columnHasAttended = 1 AND $columnAttendanceDate >= ? AND $columnAttendanceDate < ?',
      whereArgs: [dni, sessionId, todayString, tomorrowString],
    );

    if (registrations.isNotEmpty) {
      final map = registrations.first;
      final attendanceTime = DateTime.parse(
        map[columnAttendanceDate] as String,
      );
      final formatted =
          '${attendanceTime.hour}:${attendanceTime.minute.toString().padLeft(2, '0')}';

      // No tenemos información del dispositivo en la tabla de registros
      return {
        'dni': map[columnDni],
        'personName': map[columnFullName],
        'time': formatted,
        'source': 'registration',
        'deviceInfo': null, // No disponible para registros del padrón
      };
    }

    // Luego verificamos en la tabla de asistencias
    final List<Map<String, dynamic>> attendanceMaps = await db.query(
      tableAttendance,
      where:
          '$columnSessionId = ? AND $columnTimestamp >= ? AND $columnTimestamp < ?',
      whereArgs: [sessionId, todayString, tomorrowString],
    );

    for (var map in attendanceMaps) {
      final encryptedData = map[columnEncrypted] as String;
      final decryptedData = await _encryptionUtil.decryptData(encryptedData);

      if (decryptedData[columnDniNumber] == dni) {
        final timestamp = DateTime.parse(map[columnTimestamp]);
        final formatted =
            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

        return {
          'dni': dni,
          'personName': decryptedData[columnPersonName],
          'time': formatted,
          'source': 'attendance',
          'deviceInfo':
              decryptedData[columnDeviceInfo], // Incluir información del dispositivo
        };
      }
    }

    return null;
  }

  // Obtener las sesiones con asistencias pendientes de sincronizar
  Future<List<String>> getSessionsWithPendingSyncAttendances() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT $columnSessionId 
      FROM $tableAttendance 
      WHERE $columnSyncStatus = 0
    ''');

    return result.map((map) => map[columnSessionId] as String).toList();
  }

  // Método para verificar si una persona ha asistido a una combinación específica de actividad/taller/sesión en un día
  Future<bool> hasAttendanceBySessionAndDayForDni(
    String dni,
    String activityId,
    String workshopId,
    String sessionId,
    DateTime date,
  ) async {
    final db = await database;

    // Crear rango de fechas para el día
    final startOfDay =
        DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay =
        DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
          999,
        ).toIso8601String();

    // Verificar en la tabla de registros
    final registrations = await db.query(
      tableRegistrations,
      where:
          '$columnDni = ? AND $columnSessionId = ? AND $columnWorkshopId = ? AND $columnActivityId = ? AND $columnHasAttended = 1 AND $columnAttendanceDate >= ? AND $columnAttendanceDate <= ?',
      whereArgs: [dni, sessionId, workshopId, activityId, startOfDay, endOfDay],
    );

    if (registrations.isNotEmpty) {
      return true;
    }

    // Verificar en la tabla de asistencias
    final List<Map<String, dynamic>> maps = await db.query(
      tableAttendance,
      where:
          '$columnSessionId = ? AND $columnTimestamp >= ? AND $columnTimestamp <= ?',
      whereArgs: [sessionId, startOfDay, endOfDay],
    );

    for (var map in maps) {
      final encryptedData = map[columnEncrypted] as String;
      final decryptedData = await _encryptionUtil.decryptData(encryptedData);

      if (decryptedData[columnDniNumber] == dni &&
          decryptedData[columnActivityId] == activityId &&
          decryptedData[columnWorkshopId] == workshopId) {
        return true;
      }
    }

    return false;
  }

  // Método para crear una asistencia no registrada en el padrón
  Future<Registration> createNonRegisteredAttendance(
    String dni,
    String fullName,
    String activityId,
    String workshopId,
    String sessionId,
    String siteId,
  ) async {
    final db = await database;

    // Crear un ID único
    final id = 'NR_${dni}_${DateTime.now().millisecondsSinceEpoch}';

    // Crear el registro de asistencia
    final registration = Registration(
      id: id,
      dni: dni,
      fullName: fullName,
      activityId: activityId,
      workshopId: workshopId,
      sessionId: sessionId,
      siteId: siteId,
      hasAttended: true,
      registrationDate: DateTime.now(),
      attendanceDate: DateTime.now(),
    );

    // Insertar en la base de datos
    await db.insert(tableRegistrations, {
      columnId: registration.id,
      columnDni: registration.dni,
      columnFullName: registration.fullName,
      columnActivityId: registration.activityId,
      columnWorkshopId: registration.workshopId,
      columnSessionId: registration.sessionId,
      columnSiteId: registration.siteId,
      columnHasAttended: 1,
      columnRegistrationDate: registration.registrationDate.toIso8601String(),
      columnAttendanceDate: registration.attendanceDate!.toIso8601String(),
      columnSyncStatus: 0, // Pendiente de sincronizar
    });

    return registration;
  }

  // Método para buscar todas las asistencias por DNI
  Future<List<Registration>> getAttendancesByDni(String dni) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableRegistrations,
      where: '$columnDni = ? AND $columnHasAttended = 1',
      whereArgs: [dni],
      orderBy: '$columnAttendanceDate DESC',
    );

    return List.generate(maps.length, (i) {
      return Registration(
        id: maps[i][columnId],
        dni: maps[i][columnDni],
        fullName: maps[i][columnFullName],
        activityId: maps[i][columnActivityId],
        workshopId: maps[i][columnWorkshopId],
        sessionId: maps[i][columnSessionId],
        siteId: maps[i][columnSiteId],
        hasAttended: true,
        registrationDate: DateTime.parse(maps[i][columnRegistrationDate]),
        attendanceDate:
            maps[i][columnAttendanceDate] != null
                ? DateTime.parse(maps[i][columnAttendanceDate])
                : null,
        padronId: maps[i][columnPadronId], // Incluir el ID de padrón
      );
    });
  }

  // Método para obtener estadísticas de asistencia
  Future<Map<String, dynamic>> getAttendanceStats(String sessionId) async {
    final db = await database;

    // Obtener total de inscritos en la sesión
    final totalRegistered =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $tableRegistrations WHERE $columnSessionId = ?',
            [sessionId],
          ),
        ) ??
        0;

    // Obtener total de asistentes
    final totalAttended =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $tableRegistrations WHERE $columnSessionId = ? AND $columnHasAttended = 1',
            [sessionId],
          ),
        ) ??
        0;

    // Obtener total de asistentes no registrados (con ID que comience con NR_)
    final totalNonRegistered =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $tableRegistrations WHERE $columnSessionId = ? AND $columnHasAttended = 1 AND $columnId LIKE ?',
            [sessionId, 'NR_%'],
          ),
        ) ??
        0;

    // Calcular porcentaje de asistencia
    final attendancePercentage =
        totalRegistered > 0
            ? (totalAttended - totalNonRegistered) * 100 / totalRegistered
            : 0.0;

    return {
      'totalRegistered': totalRegistered,
      'totalAttended': totalAttended,
      'totalNonRegistered': totalNonRegistered,
      'attendancePercentage': attendancePercentage,
    };
  }

  // Método para limpiar datos antiguos (mantener solo datos de los últimos N días)
  Future<int> cleanupOldData(int daysToKeep) async {
    final db = await database;
    final cutoffDate =
        DateTime.now().subtract(Duration(days: daysToKeep)).toIso8601String();

    int deletedCount = 0;

    // Eliminar asistencias antiguas
    final attendanceCount = await db.delete(
      tableAttendance,
      where: '$columnTimestamp < ?',
      whereArgs: [cutoffDate],
    );

    deletedCount += attendanceCount;

    // Eliminar registros de padrón antiguos (solo los que no estén pendientes de sincronizar)
    final registrationsCount = await db.delete(
      tableRegistrations,
      where: '$columnRegistrationDate < ? AND $columnSyncStatus = 1',
      whereArgs: [cutoffDate],
    );

    deletedCount += registrationsCount;

    return deletedCount;
  }

  // Método para respaldar la base de datos
  Future<String> backupDatabase() async {
    final db = await database;
    await db.close();

    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDir.path, _databaseName);

    // Crear directorio de respaldo si no existe
    final backupDir = Directory(join(documentsDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create();
    }

    // Crear nombre de archivo para el respaldo
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final backupPath = join(backupDir.path, 'srciam_backup_$timestamp.db');

    // Copiar archivo de base de datos
    final dbFile = File(dbPath);
    await dbFile.copy(backupPath);

    // Reabrir la base de datos
    _database = await openDatabase(dbPath);

    return backupPath;
  }

  // Método para restaurar la base de datos desde un respaldo
  Future<bool> restoreDatabase(String backupPath) async {
    try {
      final db = await database;
      await db.close();

      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDir.path, _databaseName);

      // Copiar archivo de respaldo a la ubicación de la base de datos
      final backupFile = File(backupPath);
      await backupFile.copy(dbPath);

      // Reabrir la base de datos
      _database = await openDatabase(dbPath);

      return true;
    } catch (e) {
      print('Error restaurando base de datos: $e');
      return false;
    }
  }

  // Método para obtener el tamaño de la base de datos
  Future<String> getDatabaseSize() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDir.path, _databaseName);
    final dbFile = File(dbPath);

    if (await dbFile.exists()) {
      final sizeInBytes = await dbFile.length();

      // Convertir a unidades legibles
      if (sizeInBytes < 1024) {
        return '$sizeInBytes B';
      } else if (sizeInBytes < 1024 * 1024) {
        return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
      } else {
        return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
      }
    }

    return 'N/A';
  }

  Future<bool> checkAttendanceExists(String dni, String sessionId) async {
    final db = await database;

    // Consultar en la tabla de asistencias
    final List<Map<String, dynamic>> maps = await db.query(
      tableAttendance,
      where: '$columnSessionId = ?',
      whereArgs: [sessionId],
    );

    // Buscar en los registros desencriptados para verificar el DNI
    for (var map in maps) {
      final encryptedData = map[columnEncrypted] as String;
      final decryptedData = await _encryptionUtil.decryptData(encryptedData);

      if (decryptedData[columnDniNumber] == dni) {
        return true; // Ya existe un registro para este DNI en esta sesión
      }
    }

    return false; // No se encontró un registro para este DNI
  }
}
