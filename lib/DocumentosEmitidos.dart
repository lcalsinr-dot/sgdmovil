import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/api_service.dart';
import 'models/RetornoApi.dart';
import 'models/user.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DocumentosEmitidos extends StatefulWidget {
	final User user;
	const DocumentosEmitidos({Key? key, required this.user}) : super(key: key);

  @override
  State<DocumentosEmitidos> createState() => _AttendancePageState();  
}

class _AttendancePageState extends State<DocumentosEmitidos>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> documentos = [];
  bool _loading = true;
  String? filePath;

  @override
  void initState() {
    super.initState();    
	_fetchPosts();
  }

	Future<void> _fetchPosts() async {
		try {
			final retornoApi = await _apiService.DocumentosEmitidosHoyOficina(widget.user.siteId);
			if (retornoApi.resultado) {
				documentos=retornoApi.datos;
			} else {
			  alerta(retornoApi.mensaje.toString());
			}
		} catch (e) {
			alerta(e.toString());
		}
		setState(() {
			_loading = false;
		});
	}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documentos Emitidos de '+widget.user.lastName),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
			  itemCount: documentos.length,
			  itemBuilder: (context, index) {
				final item = documentos[index];
				return ListTile(
				  title: Text(item['de_asu']?.toString() ?? 'Sin Asunto'),
				  subtitle: Text(item['cdoc_desdoc']?.toString() ?? 'Sin Tipo Documento'),
				  leading: Icon(Icons.description),
				  trailing: Row(
					mainAxisSize: MainAxisSize.min,
					children: [
					  IconButton(
						icon: Icon(Icons.visibility, color: Colors.red),
						tooltip: 'Ver Documento',
						onPressed: () async {
							try {
							  final retornoApi = await _apiService.VerDocumentoPrincipalPDF(
								item['nu_ann'],
								item['nu_emi'],
								widget.user.siteId,
							  );

							  if (retornoApi.resultado) {
								_showPDFDialog(context, retornoApi.datos);
							  } else {
								alerta(retornoApi.mensaje.toString());
							  }
							} catch (e) {
							  alerta(e.toString());
							}
						},
					  ),
					  if(item['num_anex']>0)
						IconButton(
							icon: Icon(Icons.attach_file, color: Colors.green),
							tooltip: 'Ver Anexos',
							onPressed: () async {
								try {
								  final retornoApi = await _apiService.ListarAnexosSGD(
									item['nu_ann'],
									item['nu_emi'],
									widget.user.id,
									widget.user.siteId
								  );
								  if (retornoApi.resultado) {
									_showAnexos(context, item['nu_ann'], item['nu_emi'], retornoApi.datos);
								  } else {
									alerta(retornoApi.mensaje.toString());
								  }
								} catch (e) {
								  alerta(e.toString());
								}
							},
						),
					],
				  ),
				);
			  },
			),
    );
  }
  
  void _showAnexos(BuildContext context, String NuAnn, String NuEmi, dynamic apiData) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Anexos"),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: apiData.length,
              itemBuilder: (context, index) {
                final item = apiData[index];
                return ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(item['de_det']),
                  subtitle: Text('N° Ane: ${item['nu_ane']}'),
				  trailing: Row(
					mainAxisSize: MainAxisSize.min,
					children: [
					  if(p.extension(item['de_det']).toLowerCase()==".pdf")
						IconButton(
							icon: Icon(Icons.visibility, color: Colors.red),
							tooltip: 'Ver Anexo',
							onPressed: () async {
								try {
								  final retornoApi = await _apiService.VerAnexoPDF(
									NuAnn,
									NuEmi,
									widget.user.id,
									widget.user.siteId,
									item['nu_ane'].toString(),
								  );

								  if (retornoApi.resultado) {
									_showPDFDialog(context, retornoApi.datos);
								  } else {
									alerta(retornoApi.mensaje.toString());
								  }
								} catch (e) {
								  alerta(e.toString());
								}
							},
						),
					],
				  ),
                  onTap: () {
                    print('Seleccionado: ${item['de_det']}');
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showPDFDialog(BuildContext context, String base64String) async {
    final bytes = base64Decode(base64String);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/temp.pdf');
    await file.writeAsBytes(bytes);

    showDialog(
	  context: context,
	  builder: (dialogContext) => AlertDialog(
		title: const Text("Documento PDF"),
		contentPadding: EdgeInsets.zero,
		content: SizedBox(
		  width: 300,
		  height: 500,
		  child: PDFView(
			filePath: file.path,
			enableSwipe: true,
			swipeHorizontal: true,
			autoSpacing: false,
			pageFling: false,
		  ),
		),
		actions: [
		  TextButton(
			onPressed: () => Navigator.of(context).pop(),
			child: const Text("Cerrar"),
		  ),
		],
	  ),
	);
  }
	
	void alerta(String mensaje)
	{
		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(
				content: Text(mensaje ?? "Error desconocido"),
				backgroundColor: Colors.red,
			),
		);
	}
}