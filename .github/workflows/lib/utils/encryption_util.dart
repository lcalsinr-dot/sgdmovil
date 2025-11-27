import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionUtil {
  static final EncryptionUtil _instance = EncryptionUtil._internal();
  final secureStorage = const FlutterSecureStorage();
  final String _encryptionKeyName = 'srciam_db_key';
  
  factory EncryptionUtil() {
    return _instance;
  }
  
  EncryptionUtil._internal();
  
  // Generar/obtener clave de encriptación
  Future<String> getEncryptionKey() async {
    String? storedKey = await secureStorage.read(key: _encryptionKeyName);
    
    if (storedKey == null) {
      // Generar una nueva clave si no existe
      final key = base64Encode(List<int>.generate(32, (_) => DateTime.now().millisecondsSinceEpoch % 255));
      await secureStorage.write(key: _encryptionKeyName, value: key);
      return key;
    }
    
    return storedKey;
  }

  // Encriptar datos
  Future<String> encryptData(Map<String, dynamic> data) async {
    final String key = await getEncryptionKey();
    final keyBytes = sha256.convert(utf8.encode(key)).bytes;
    final ivBytes = List<int>.generate(16, (_) => DateTime.now().millisecondsSinceEpoch % 255);
    final iv = encrypt.IV(Uint8List.fromList(ivBytes));
    
    final encrypter = encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key(Uint8List.fromList(keyBytes.sublist(0, 32))),
        mode: encrypt.AESMode.cbc,
      ),
    );
    
    final jsonData = jsonEncode(data);
    final encrypted = encrypter.encrypt(jsonData, iv: iv);
    
    // Combinar IV y datos cifrados para almacenamiento
    final combined = base64Encode(ivBytes) + '.' + encrypted.base64;
    return combined;
  }

  // Desencriptar datos
  Future<Map<String, dynamic>> decryptData(String encryptedData) async {
    final String key = await getEncryptionKey();
    final keyBytes = sha256.convert(utf8.encode(key)).bytes;
    
    final parts = encryptedData.split('.');
    final ivString = parts[0];
    final dataString = parts[1];
    
    final ivBytes = base64Decode(ivString);
    final iv = encrypt.IV(Uint8List.fromList(ivBytes));
    
    final encrypter = encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key(Uint8List.fromList(keyBytes.sublist(0, 32))),
        mode: encrypt.AESMode.cbc,
      ),
    );
    
    final decrypted = encrypter.decrypt64(dataString, iv: iv);
    return jsonDecode(decrypted) as Map<String, dynamic>;
  }
}