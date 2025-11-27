import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  
  factory DeviceInfoService() {
    return _instance;
  }
  
  DeviceInfoService._internal();
  
  // Obtener información del dispositivo como un string único
  Future<String> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return await _getAndroidDeviceInfo();
      } else if (Platform.isIOS) {
        return await _getIosDeviceInfo();
      } else {
        return 'Dispositivo desconocido';
      }
    } catch (e) {
      print('Error obteniendo información del dispositivo: $e');
      return 'Dispositivo desconocido';
    }
  }
  
  // Obtener información de dispositivos Android
  Future<String> _getAndroidDeviceInfo() async {
    final AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
    
    return '${androidInfo.manufacturer} ${androidInfo.model}';
  }
  
  // Obtener información de dispositivos iOS
  Future<String> _getIosDeviceInfo() async {
    final IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
    
    String model = iosInfo.model ?? 'iPhone';
    if (model.toLowerCase().contains('iphone') && iosInfo.name != null) {
      return 'Apple ${iosInfo.name}';
    }
    return 'Apple $model';
  }
}