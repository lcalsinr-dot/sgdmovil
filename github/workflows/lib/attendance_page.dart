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

class AttendancePage extends StatefulWidget {
  final User user;
  const AttendancePage({Key? key, required this.user}) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();  
}

class _AttendancePageState extends State<AttendancePage>
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
			final retornoApi = await _apiService.ListaDocumentosFirmarOficina(widget.user.siteId);
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
        title: Text('Documentos Pendientes para '+widget.user.lastName),
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
					  if(item['co_empleado']==widget.user.id&&item['num_anex_firma']==0&&item['vb_pendientes']==0)
						  IconButton(
							icon: Icon(Icons.assignment_turned_in, color: Colors.orange),
							tooltip: 'Firmar Documento',
							onPressed: () {
							  _showAboutDialog(context,item['nu_ann'],item['nu_emi']);
							},
						  ),
					  if(item['vb_totales']>0)
						  IconButton(
							icon: Icon(Icons.download_done, color: item['vb_pendientes']>0?Colors.red:Colors.green),
							tooltip: 'Vistos Buenos',
							onPressed: () async {
								try {
								  final retornoApi = await _apiService.ListarVBExpediente(
									item['nu_ann'],
									item['nu_emi'],
									widget.user.siteId
								  );
								  if (retornoApi.resultado) {
									_showVistosBuenos(context, item['nu_ann'], item['nu_emi'], retornoApi.datos);
								  } else {
									alerta(retornoApi.mensaje.toString());
								  }
								} catch (e) {
								  alerta(e.toString());
								}
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
					  if(item['num_anex']>0)
						IconButton(
							icon: Icon(Icons.attach_file, color: item['num_anex_firma']>0?Colors.red:Colors.green),
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
  
  void _showAboutDialog(BuildContext context, String NuAnn, String NuEmi) {
  final TextEditingController _textController = TextEditingController();
  bool _obscureText = true;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Firmar y Emitir Documento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _textController,
                  decoration: InputDecoration(
                    labelText: 'Clave Certificado',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureText,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    final retornoApi = await _apiService.EmitirExpedienteOficina(
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
                      alerta(retornoApi.mensaje.toString());
                    }
                  } catch (e) {
                    alerta(e.toString());
                  }
                },
                child: const Text('Firmar y Emitir'),
              )
            ],
          );
        },
      );
    },
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
					  if(p.extension(item['de_det']).toLowerCase()==".pdf")
						IconButton(
							icon: Icon(Icons.assignment_turned_in, color: Colors.orange),
							tooltip: 'VB Anexo',
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
									_showPDFDialogFirmar(context, '2', retornoApi.datos,NuAnn,NuEmi,item['nu_ane'].toString());
								  } else {
									alerta(retornoApi.mensaje.toString());
								  }
								} catch (e) {
								  alerta(e.toString());
								}
							},
						),
					  if(p.extension(item['de_det']).toLowerCase()==".pdf")
						IconButton(
							icon: Icon(Icons.draw, color: Colors.orange),
							tooltip: 'Firmar Anexo',
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
									_showPDFDialogFirmar(context, '1', retornoApi.datos,NuAnn,NuEmi,item['nu_ane'].toString());
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
  
  void _showVistosBuenos(BuildContext context, String NuAnn, String NuEmi, dynamic apiData) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Vistos Buenos"),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: apiData.length,
              itemBuilder: (context, index) {
                final item = apiData[index];
                return ListTile(
                  leading: Icon(
					item['in_vb']=='1'?Icons.download_done:(item['in_vb']=='0'?Icons.punch_clock:Icons.question_mark),
					color: item['in_vb']=='1'?Colors.green:(item['in_vb']=='0'?Colors.orange:Colors.red)
					),
                  title: Text(item['cemp_apepat']+' '+item['cemp_apemat']+' '+item['cemp_denom']),
                  subtitle: Text(item['de_sigla']),				  
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
  Future<void> _showPDFDialogFirmar(BuildContext context, String tipo, String base64String, String NuAnn, String NuEmi, String NuAne) async {
    final bytes = base64Decode(base64String);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/temp.pdf');
    await file.writeAsBytes(bytes);
	final widgetWidth = 300.0; // px
	final widgetHeight = 500.0; // px

    showDialog(
	  context: context,
	  builder: (dialogContext) => AlertDialog(
		title: const Text("Documento PDF"),
		contentPadding: EdgeInsets.zero,
		content: SizedBox(
		  width: widgetWidth,
		  height: widgetHeight,
		  child: GestureDetector(
			onTapDown: (TapDownDetails details) {
			  RenderBox box = dialogContext.findRenderObject() as RenderBox;
			  final localPosition = box.globalToLocal(details.globalPosition);
			  /*final posX = localPosition.dx;
			  final posY = localPosition.dy;
			  const pdfWidth = 595.0; // puntos
			  const pdfHeight = 842.0; // puntos
			  // Convertimos a puntos
			  final pdfPosX = (posX / widgetWidth) * pdfWidth;
			  final pdfPosY = ((widgetHeight - posY) / widgetHeight) * pdfHeight;*/
			  //alerta('PosX='+localPosition.dx.toInt().toString()+' PosY='+localPosition.dy.toInt().toString());
			  
			  final PosX_i=60;
			  final PosX_f=341;
			  final PosY_i=124;
			  final PosY_f=616;
			  
			  final posX = localPosition.dx-PosX_i;
			  final posY = localPosition.dy-PosY_i;
			  const pdfWidth = 595.0; // puntos
			  const pdfHeight = 842.0; // puntos
			  // Convertimos a puntos
			  final pdfPosX = (posX / (PosX_f-PosX_i)) * pdfWidth;
			  final pdfPosY = (((PosY_f-PosY_i) - posY) / (PosY_f-PosY_i)) * pdfHeight;
			  
			  _showIngresarClaveCertificadoAnexo(context, tipo, NuAnn, NuEmi, NuAne, pdfPosX.toInt().toString(), pdfPosY.toInt().toString());
			},
			child: PDFView(
			  filePath: file.path,
			  enableSwipe: true,
			  swipeHorizontal: true,
			  autoSpacing: false,
			  pageFling: false,
			),
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
  
  void _showIngresarClaveCertificadoAnexo(BuildContext context, String tipo, String NuAnn, String NuEmi, String NuAne, String PosX, String PosY) {
    final TextEditingController _textController = TextEditingController();
	showDialog(
		context: context,
		builder: (context) {
		  bool _obscureText = true;
		  return StatefulBuilder(
			builder: (context, setState) {
			  return AlertDialog(
				title: const Text('Firmar y Subir Anexo'),
				content: Column(
				  mainAxisSize: MainAxisSize.min,
				  children: [
					TextFormField(
					  controller: _textController,
					  decoration: InputDecoration(
						labelText: 'Clave Certificado',
						suffixIcon: IconButton(
						  icon: Icon(
							_obscureText
								? Icons.visibility_off
								: Icons.visibility,
						  ),
						  onPressed: () {
							setState(() {
							  _obscureText = !_obscureText;
							});
						  },
						),
					  ),
					  obscureText: _obscureText,
					),
				  ],
				),
				actions: [
				  TextButton(
					onPressed: () async {
					  try {
						final retornoApi = await _apiService.FirmaAvanzadaAnexo(
						  tipo,
						  NuAnn,
						  NuEmi,
						  widget.user.id,
						  widget.user.siteId,
						  NuAne,
						  _textController.text,
						  PosX,
						  PosY,
						);

						if (retornoApi.resultado) {
						  ScaffoldMessenger.of(context).showSnackBar(
							const SnackBar(
							  content: Text('Correcto'),
							  duration: Duration(seconds: 2),
							),
						  );
						  Navigator.of(context, rootNavigator: true).pop(); // Cierra diálogo
						  Navigator.of(context, rootNavigator: true).pop(); // Otras acciones
						} else {
						  alerta(retornoApi.mensaje.toString());
						}
					  } catch (e) {
						alerta(e.toString());
					  }
					},
					child: const Text('Firmar y Subir'),
				  ),
				],
			  );
			},
		  );
		},
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