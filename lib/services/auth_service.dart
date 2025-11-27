import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user.dart';
import '../models/RetornoApi.dart';
import '../models/registration.dart';
import 'api_service.dart';
import '../database/encrypted_database_helper.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _userIdKey = 'user_id';
  final String _sessionKey = 'session_active';
  final ApiService _apiService = ApiService();
  final EncryptedDatabaseHelper _dbHelper = EncryptedDatabaseHelper();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Iniciar sesión
  Future<RetornoApi> login(String email, String password) async {
    bool resultado=false;
	String? mensaje;
	Map<String, dynamic>? datos;
	final retornoApi = await _apiService.login(email, password);
	if(retornoApi.resultado)
	{		
		datos=retornoApi.datos;
		resultado=true;
	}
	else
		mensaje=retornoApi.mensaje;
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
  }

  // Verificar si hay una sesión activa
  Future<bool> isLoggedIn() async {
    try {
      final sessionActive = await _secureStorage.read(key: _sessionKey);
      return sessionActive == 'true';
    } catch (e) {
      print('Error verificando sesión: $e');
      return false;
    }
  }

  // Obtener datos del usuario actual
  Future<User?> getCurrentUser() async {
    try {
      final userId = await _secureStorage.read(key: _userIdKey);
      
      if (userId == null) {
        return null;
      }
      
      return await _dbHelper.getUser(userId);
    } catch (e) {
      print('Error obteniendo usuario: $e');
      return null;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      await _secureStorage.delete(key: _sessionKey);
      await _secureStorage.delete(key: _userIdKey);
    } catch (e) {
      print('Error cerrando sesión: $e');
    }
  }
  
  // Verificar si hay conexión a internet
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}