import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sirciam_app/models/attendance_record.dart';
import '../models/user.dart';
import '../models/activity.dart';
import '../models/workshop.dart';
import '../models/session.dart';
import '../models/registration.dart';
import '../models/RetornoAPI.dart';

class ApiService {
  // URL base para la API - cambiar según el entorno
  static const String baseUrl =
      'http://192.168.16.87:15000'; // Reemplazar con tu URL real

  // Tiempos de espera para las solicitudes HTTP
  static const int connectionTimeout = 15000; // 15 segundos
  static const int responseTimeout = 30000; // 30 segundos

  // Headers comunes para todas las solicitudes
  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'User-Agent': 'MIMP-SIRCIAM-App/1.0.0',
    };
  }

  // Método para manejar errores HTTP
  Exception _handleError(http.Response response) {
    try {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      final String errorMessage = errorData['message'] ?? 'Error desconocido';
      return Exception(
        'Error del servidor: $errorMessage (${response.statusCode})',
      );
    } catch (e) {
      return Exception(
        'Error HTTP ${response.statusCode}: ${response.reasonPhrase}',
      );
    }
  }

  // Autenticación y obtención de datos del usuario
  Future<RetornoApi> login(String email, String password) async {
	bool resultado=false;
	String? mensaje;
	Map<String, dynamic>? datos;
	Map<String, dynamic>? retorno;
	
	final response = await http.post(
		Uri.parse('$baseUrl/api/sgd/login'),
		headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		body: {'usuario': email, 'clave': password},
	);
	if (response.statusCode == 200) {
		retorno=jsonDecode(response.body);
		if(retorno?["resultado"]==1)
		{
			datos=retorno?["usuario"];
			resultado=true;
		}
		else
			mensaje=retorno?["mensaje"];
	} else {
		mensaje="La API devolvió un statusCode no válido";
	}
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
}
  //Listar los documentos de Oficina que estan para firmar
  Future<RetornoApi> ListaDocumentosFirmarOficina(String CodDep) async {
	bool resultado=false;
	String? mensaje;
	dynamic? datos;
	Map<String, dynamic>? retorno;
	
	final response = await http.post(
		Uri.parse('$baseUrl/api/sgd/ParaFirmarOficina'),
		headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		body: {'CodDep': CodDep},
	);
	if (response.statusCode == 200) {
		retorno=jsonDecode(response.body);
		if(retorno?["resultado"]==1)
		{
			datos=retorno?["datos"];
			resultado=true;
		}
		else
			mensaje=retorno?["mensaje"];
	} else {
		mensaje="La API devolvió un statusCode no válido";
	}
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
}

//Listar los documentos de Oficina que estan para firmar
  Future<RetornoApi> ListarVBExpediente(String NuAnn,String NuEmi,String CodDep) async {
	bool resultado=false;
	String? mensaje;
	dynamic? datos;
	Map<String, dynamic>? retorno;
	
	final response = await http.post(
		Uri.parse('$baseUrl/api/sgd/ListarVBExpediente'),
		headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		body: {'NuAnn': NuAnn,'NuEmi': NuEmi,'CodDep': CodDep},
	);
	if (response.statusCode == 200) {
		retorno=jsonDecode(response.body);
		if(retorno?["resultado"]==1)
		{
			datos=retorno?["datos"];
			resultado=true;
		}
		else
			mensaje=retorno?["mensaje"];
	} else {
		mensaje="La API devolvió un statusCode no válido";
	}
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
}

  //Emitir Expediente
  Future<RetornoApi> EmitirExpedienteOficina(String NuAnn, String NuEmi, String CodEmp, String CodDep, String CodCertificado) async {
	bool resultado=false;
	String? mensaje;
	dynamic? datos;
	Map<String, dynamic>? retorno;
	
	final response = await http.post(
		Uri.parse('$baseUrl/api/sgd/EmitirExpeOficina'),
		headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		body: {'NuAnn': NuAnn,'NuEmi': NuEmi,'CodEmp': CodEmp,'CodDep': CodDep,'CodCertificado': CodCertificado},
	);
	if (response.statusCode == 200) {
		retorno=jsonDecode(response.body);
		if(retorno?["resultado"]==1)
		{
			datos=retorno?["datos"];
			resultado=true;
		}
		else
			mensaje=retorno?["mensaje"];
	} else {
		mensaje="La API devolvió un statusCode no válido";
	}
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
}

  //Listar los documentos Profesionales que estan para firmar
  Future<RetornoApi> ListaDocumentosFirmarProfesionales(String CodEmp) async {
	bool resultado=false;
	String? mensaje;
	dynamic? datos;
	Map<String, dynamic>? retorno;
	
	final response = await http.post(
		Uri.parse('$baseUrl/api/sgd/ParaFirmarProfesional'),
		headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		body: {'CodEmp': CodEmp},
	);
	if (response.statusCode == 200) {
		retorno=jsonDecode(response.body);
		if(retorno?["resultado"]==1)
		{
			datos=retorno?["datos"];
			resultado=true;
		}
		else
			mensaje=retorno?["mensaje"];
	} else {
		mensaje="La API devolvió un statusCode no válido";
	}
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
}

//Emitir Expediente
  Future<RetornoApi> EmitirExpedienteProfesional(String NuAnn, String NuEmi, String CodEmp, String CodDep, String CodCertificado) async {
	bool resultado=false;
	String? mensaje;
	dynamic? datos;
	Map<String, dynamic>? retorno;
	
	final response = await http.post(
		Uri.parse('$baseUrl/api/sgd/EmitirExpeProfesional'),
		headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		body: {'NuAnn': NuAnn,'NuEmi': NuEmi,'CodEmp': CodEmp,'CodDep': CodDep,'CodCertificado': CodCertificado},
	);
	if (response.statusCode == 200) {
		retorno=jsonDecode(response.body);
		if(retorno?["resultado"]==1)
		{
			datos=retorno?["datos"];
			resultado=true;
		}
		else
			mensaje=retorno?["mensaje"];
	} else {
		mensaje="La API devolvió un statusCode no válido";
	}
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
}

//Listar los documentos Profesionales que estan para firmar
  Future<RetornoApi> ListaDocumentosVB(String CodEmp) async {
	bool resultado=false;
	String? mensaje;
	dynamic? datos;
	Map<String, dynamic>? retorno;
	
	final response = await http.post(
		Uri.parse('$baseUrl/api/sgd/ParaDarVB'),
		headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		body: {'CodEmp': CodEmp},
	);
	if (response.statusCode == 200) {
		retorno=jsonDecode(response.body);
		if(retorno?["resultado"]==1)
		{
			datos=retorno?["datos"];
			resultado=true;
		}
		else
			mensaje=retorno?["mensaje"];
	} else {
		mensaje="La API devolvió un statusCode no válido";
	}
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
}

//Dar Visto Bueno
  Future<RetornoApi> EmitirVistoBueno(String NuAnn, String NuEmi, String CodEmp, String CodCertificado) async {
	bool resultado=false;
	String? mensaje;
	dynamic? datos;
	Map<String, dynamic>? retorno;
	
	final response = await http.post(
		Uri.parse('$baseUrl/api/sgd/DarVB'),
		headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		body: {'NuAnn': NuAnn,'NuEmi': NuEmi,'CodEmp': CodEmp,'CodCertificado': CodCertificado},
	);
	if (response.statusCode == 200) {
		retorno=jsonDecode(response.body);
		if(retorno?["resultado"]==1)
		{
			datos=retorno?["datos"];
			resultado=true;
		}
		else
			mensaje=retorno?["mensaje"];
	} else {
		mensaje="La API devolvió un statusCode no válido";
	}
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
}

//Ver PDF expediente
  Future<RetornoApi> VerDocumentoPrincipalPDF(String NuAnn, String NuEmi, String CodDep) async {
	bool resultado=false;
	String? mensaje;
	dynamic? datos;
	Map<String, dynamic>? retorno;
	
	final response = await http.post(
		Uri.parse('$baseUrl/api/sgd/VerDocumentoPrincipalPDF'),
		headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		body: {'NuAnn': NuAnn,'NuEmi': NuEmi,'CodDep': CodDep},
	);
	if (response.statusCode == 200) {
		retorno=jsonDecode(response.body);
		if(retorno?["resultado"]==1)
		{
			datos=retorno?["datos"];
			resultado=true;
		}
		else
			mensaje=retorno?["mensaje"];
	} else {
		mensaje="La API devolvió un statusCode no válido";
	}
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
}

//Listar Anexos
  Future<RetornoApi> ListarAnexosSGD(String NuAnn, String NuEmi, String CodEmp, String CodDep) async {
	bool resultado=false;
	String? mensaje;
	dynamic? datos;
	Map<String, dynamic>? retorno;
	
	final response = await http.post(
		Uri.parse('$baseUrl/api/sgd/ListarAnexosSGD'),
		headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		body: {'NuAnn': NuAnn,'NuEmi': NuEmi,'CodDep': CodDep},
	);
	if (response.statusCode == 200) {
		retorno=jsonDecode(response.body);
		if(retorno?["resultado"]==1)
		{
			datos=retorno?["datos"];
			resultado=true;
		}
		else
			mensaje=retorno?["mensaje"];
	} else {
		mensaje="La API devolvió un statusCode no válido";
	}
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
}

//Ver Anexo
  Future<RetornoApi> VerAnexoPDF(String NuAnn, String NuEmi, String CodEmp, String CodDep, String NuAne) async {
	bool resultado=false;
	String? mensaje;
	dynamic? datos;
	Map<String, dynamic>? retorno;
	
	final response = await http.post(
		Uri.parse('$baseUrl/api/sgd/VerAnexoPDF'),
		headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		body: {'NuAnn': NuAnn,'NuEmi': NuEmi,'CodDep': CodDep,'NuAne': NuAne},
	);
	if (response.statusCode == 200) {
		retorno=jsonDecode(response.body);
		if(retorno?["resultado"]==1)
		{
			datos=retorno?["datos"];
			resultado=true;
		}
		else
			mensaje=retorno?["mensaje"];
	} else {
		mensaje="La API devolvió un statusCode no válido";
	}
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
}

//Firmar Anexo
  Future<RetornoApi> FirmaAvanzadaAnexo(String tipo, String NuAnn, String NuEmi, String CodEmp, String CodDep, String NuAne, String CodCertificado, String PosX, String PosY) async {
	bool resultado=false;
	String? mensaje;
	dynamic? datos;
	Map<String, dynamic>? retorno;
	
	final response = await http.post(
		Uri.parse('$baseUrl/api/sgd/FirmaAvanzadaAnexo'),
		headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		body: {'tipo': tipo,'NuAnn': NuAnn,'NuEmi': NuEmi,'CodEmp': CodEmp,'CodDep': CodDep,'NuAne': NuAne, 'CodCertificado': CodCertificado, 'PosX': PosX, 'PosY':PosY},
	);
	if (response.statusCode == 200) {
		retorno=jsonDecode(response.body);
		if(retorno?["resultado"]==1)
		{
			datos=retorno?["datos"];
			resultado=true;
		}
		else
			mensaje=retorno?["mensaje"];
	} else {
		mensaje="La API devolvió un statusCode no válido";
	}
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
}

//Firmar Anexo
  Future<RetornoApi> DocumentosEmitidosHoyOficina(String CodDep) async {
	bool resultado=false;
	String? mensaje;
	dynamic? datos;
	Map<String, dynamic>? retorno;
	
	final response = await http.post(
		Uri.parse('$baseUrl/api/sgd/DocumentosEmitidosHoyOficina'),
		headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		body: {'CodDep': CodDep},
	);
	if (response.statusCode == 200) {
		retorno=jsonDecode(response.body);
		if(retorno?["resultado"]==1)
		{
			datos=retorno?["datos"];
			resultado=true;
		}
		else
			mensaje=retorno?["mensaje"];
	} else {
		mensaje="La API devolvió un statusCode no válido";
	}
	return RetornoApi(
	  resultado: resultado,
	  mensaje: mensaje,
	  datos:datos,
	);
}
}
