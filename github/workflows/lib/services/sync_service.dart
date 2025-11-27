import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/registration.dart';
import '../models/user.dart';
import 'api_service.dart';
import '../database/encrypted_database_helper.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  final ApiService _apiService = ApiService();
  final EncryptedDatabaseHelper _dbHelper = EncryptedDatabaseHelper();

  Timer? _autoSyncTimer;
  bool _isSyncInProgress = false;

  // Callback para cuando se completa la sincronización
  VoidCallback? _onSyncComplete;

  factory SyncService() {
    return _instance;
  }

  SyncService._internal();

  // Verificar si hay conexión a internet
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Sincronizar maestros de datos desde el servicio web
  Future<bool> syncMasterData(User user) async {
    if (_isSyncInProgress) {
      return false; // Evitar sincronizaciones simultáneas
    }

    _isSyncInProgress = true;

    try {
      // Verificar conectividad
      if (!await hasInternetConnection()) {
        return false;
      }
      return true;
    } catch (e) {
      print('Error sincronizando datos: $e');
      return false;
    } finally {
      _isSyncInProgress = false;
      if (_onSyncComplete != null) {
        _onSyncComplete!();
      }
    }
  }
}

// Tipo para función de callback
typedef VoidCallback = void Function();
