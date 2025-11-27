import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  
  factory LocationService() {
    return _instance;
  }
  
  LocationService._internal();
  
  // Verificar permisos de ubicación
  Future<bool> checkLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si los servicios de ubicación están habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los servicios de ubicación están desactivados.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    // Verificar permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se requieren permisos de ubicación para registrar la asistencia.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Los permisos de ubicación están permanentemente denegados. Por favor, actívalos en la configuración.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    return true;
  }
  
  // Obtener la ubicación actual
  Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      // Solicitar ubicación con alta precisión
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Obtener dirección a partir de coordenadas
      String address = await getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      return {
        'success': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
      };
    } catch (e) {
      print('Error al obtener ubicación: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Obtener la dirección a partir de coordenadas
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude, 
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      return "Ubicación no determinada";
    } catch (e) {
      print('Error al obtener dirección: $e');
      return "No se pudo determinar la dirección";
    }
  }
}