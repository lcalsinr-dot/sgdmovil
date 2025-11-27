import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'attendance_page.dart';
import 'history_page.dart';
import 'models/user.dart';
import 'login_page.dart';
import 'settings_screen.dart';
import 'DocumentosEmitidos.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/api_service.dart';
import 'dart:math' as math;

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Iniciar animación después de un breve retraso
    Future.delayed(Duration(milliseconds: 200), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Método auxiliar para construir items de error
  Widget _buildErrorItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // Agregar también un método para diagnosticar el estado de la sincronización
  Future<Map<String, dynamic>> _diagnoseSyncIssues() async {
    Map<String, dynamic> diagnosticData = {};

    try {
      // Verificar conexión a internet
      final hasConnection = await _syncService.hasInternetConnection();
      diagnosticData['internet_connection'] = hasConnection;

      // Verificar estado del token
      final user = await _authService.getCurrentUser();
      diagnosticData['has_user'] = user != null;
      diagnosticData['has_token'] =
          user?.token != null && user!.token.isNotEmpty;

      // Verificar conectividad con el servidor
      if (hasConnection) {
        try {
          final response = await http
              .get(
                Uri.parse('${ApiService.baseUrl}/actuator/health'),
                headers: {'Accept': 'application/json'},
              )
              .timeout(const Duration(seconds: 5));

          diagnosticData['server_reachable'] = response.statusCode == 200;
          diagnosticData['server_status_code'] = response.statusCode;

          try {
            final responseData = jsonDecode(response.body);
            diagnosticData['server_message'] =
                responseData['message'] ?? 'No message';
          } catch (_) {
            diagnosticData['server_message'] = 'Could not parse response';
          }
        } catch (e) {
          diagnosticData['server_reachable'] = false;
          diagnosticData['server_error'] = e.toString();
        }
      }

      return diagnosticData;
    } catch (e) {
      print('Error durante el diagnóstico: $e');
      return {'diagnostic_error': e.toString()};
    }
  }

  Future<void> _logout(BuildContext context) async {
    // Añadir efecto de diálogo de confirmación
    final bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Cerrar sesión'),
                content: const Text(
                  '¿Estás seguro de que deseas cerrar la sesión?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      await _authService.logout();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const LoginPage(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutQuart;

              var tween = Tween(
                begin: begin,
                end: end,
              ).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el tamaño de la pantalla
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar:
          true, // Permite que el contenido se extienda detrás de la AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_mimp.png',
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('ResysERP'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Container(
        // Gradiente de fondo
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar del usuario con efecto de pulso
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Image.asset(
                              'assets/images/logo_mimp.png',
                              width: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Mensaje de bienvenida con efecto de fade
                      Opacity(
                        opacity: _animationController.value,
                        child: Column(
                          children: [
                            Text(
                              'Bienvenido(a),',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              widget.user.firstName.isNotEmpty
                                  ? widget.user.firstName
                                  : widget.user.email.split('@')[0],
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Texto descriptivo con animación
                      FadeTransition(
                        opacity: _animationController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(_animationController),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Sistema de Gestion Documental Movil',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Tarjetas de opciones con animación
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          // Tarjeta de Documentos de Oficina
                          _buildOptionCard(
                            icon: Icons.document_scanner,
                            title: 'Documentos de Oficina',
                            color: Colors.blue,
                            delay: 0.1,
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) =>AttendancePage(user: widget.user),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Tarjeta de Documentos Profesionales
                          _buildOptionCard(
                            icon: Icons.person,
                            title: 'Documentos Profesionales',
                            color: Colors.green,
                            delay: 0.2,
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) =>HistoryPage(user: widget.user),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Tarjeta de Vistos Buenos Pendientes
                          _buildOptionCard(
                            icon: Icons.check,
                            title: 'Vistos Buenos Pendientes',
                            color: Colors.orange,
                            delay: 0.3,
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => SettingsScreen(user: widget.user),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Tarjeta de Documento Emitidos
                          _buildOptionCard(
                            icon: Icons.drive_file_move_outline,
                            title: 'Documentos Emitidos Hoy',
                            color: Colors.cyan,
                            delay: 0.3,
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => DocumentosEmitidos(user: widget.user),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                ),
                              );
                            },
                          ),
						  
						  // Tarjeta de Acerca de
                          _buildOptionCard(
                            icon: Icons.info,
                            title: 'Acerca de',
                            color: Colors.purple,
                            delay: 0.4,
                            onTap: () {
                              _showAboutDialog(context);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Texto de pie de página con animación
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(0.7, 1.0, curve: Curves.easeOut),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'OGTI © MIMP © ${DateTime.now().year}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Método para construir tarjetas de opciones animadas
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Calcular valor de animación con retraso
        final double animValue = math.max(
          0,
          math.min(1, (_animationController.value - delay) / (1 - delay)),
        );

        return Transform.scale(
          scale: 0.5 + (0.5 * animValue),
          child: Opacity(
            opacity: animValue,
            child: GestureDetector(
              onTap: onTap,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.7)],
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onTap,
                    splashColor: Colors.white.withOpacity(0.3),
                    highlightColor: Colors.white.withOpacity(0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 50, color: Colors.white),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Diálogo de "Acerca de"
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Acerca de SGD Movil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_mimp.png', height: 80),
                const SizedBox(height: 16),
                const Text(
                  'Sistema de Gestión Documental Movil',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Versión 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Desarrollado por la Oficina General de Tecnologías de la Información',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }
}
