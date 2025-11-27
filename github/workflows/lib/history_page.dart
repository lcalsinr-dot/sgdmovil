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

class HistoryPage extends StatefulWidget {
  final User user;
  const HistoryPage({Key? key, required this.user}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> documentos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();    
	_fetchPosts();
  }

	Future<void> _fetchPosts() async {
		try {
			final retornoApi = await _apiService.ListaDocumentosFirmarProfesionales(widget.user.id);
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
        title: Text('Documentos Pendientes para '+widget.user.firstName),
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
						icon: Icon(Icons.assignment_turned_in, color: Colors.orange),
						onPressed: () {
						  _showAboutDialog(context,item['nu_ann'],item['nu_emi']);
						},
					  ),
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
					],
				  ),				  
				);
			  },
			),
    );
  }
  
  void _showAboutDialog(BuildContext context, String NuAnn, String NuEmi) {
    final TextEditingController _textController = TextEditingController();
	showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Firmar y Emitir Documento'),
            content: Column(              
			  mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
					controller: _textController,
					decoration: InputDecoration(labelText: 'Clave Certificado'),
				),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
					try {
					  final retornoApi = await _apiService.EmitirExpedienteProfesional(
						NuAnn,
						NuEmi,
						widget.user.id,
						widget.user.siteId,
						_textController.text,
					  );

					  if (retornoApi.resultado) {
						Navigator.of(context).pop();
						_fetchPosts();
						alerta("Emitido Correctamente");
					  } else {
						throw Exception(retornoApi.mensaje);
					  }
					  Navigator.pop(context); // cerrar el diálogo
					} catch (e) {
					  alerta(e.toString());
					}
				},
                child: const Text('Firmar y Emitir'),
              )
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