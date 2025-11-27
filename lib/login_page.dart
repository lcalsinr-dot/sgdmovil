import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'home_page.dart';
import 'services/auth_service.dart';
import '../models/user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isOfflineMode = false;
  final AuthService _authService = AuthService();
  
  // Inicializa directamente para evitar errores late
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeIn,
    );
    
    // Iniciar la animación
    _animationController!.forward();
    
    // Verificar conectividad inicial
    _checkConnectivity();
    
    // Escuchar cambios de conectividad
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOfflineMode = result == ConnectivityResult.none;
      });
    });
  }
  
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOfflineMode = connectivityResult == ConnectivityResult.none;
    });
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
	if (_formKey.currentState!.validate()) {
		bool resultado=false;
		String? mensaje;
		late User user;
		try{
			final retornoApi = await _authService.login(_emailController.text.trim(), _passwordController.text.trim());
			if(retornoApi.resultado)
			{
				user=User(
				  id: retornoApi.datos?['cemp_codemp'] ?? "",
				  email: retornoApi.datos?['cod_user'] ?? "",
				  password: '', // No almacenamos la contraseña real
				  firstName: retornoApi.datos?['cdes_user'] ?? "",
				  lastName: retornoApi.datos?['de_dependencia'] ?? "",
				  siteId: retornoApi.datos?['co_dependencia'] ?? "",
				  dni: '',
				  token: '',
				);
				resultado=true;
			}
			else
				mensaje=retornoApi.mensaje;
		} catch (e) {
			mensaje=e.toString();
		}
		if(resultado)
		{
			Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => HomePage(user: user),
              ),
              (route) => false,
            );
		}
		else
			ScaffoldMessenger.of(context).showSnackBar(
			  SnackBar(
				content: Text(mensaje ?? "Error desconocido"),
				backgroundColor: Colors.red,
			  ),
			);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Comprobar que las animaciones estén inicializadas
    final bool animationsReady = _fadeAnimation != null && _animationController != null;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFd32f2f),
              const Color(0xFFd32f2f).withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: animationsReady 
                ? FadeTransition(
                    opacity: _fadeAnimation!,
                    child: _buildLoginContent(),
                  )
                : _buildLoginContent(), // Fallback si las animaciones no están listas
            ),
          ),
        ),
      ),
    );
  }
  
  // Extraer el contenido a un método separado para reutilizarlo
  Widget _buildLoginContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Logo
        Container(
          width: 240,
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Image.asset(
            'assets/images/logo_mimp.png',
            fit: BoxFit.contain,
          ),
        ),
        
        const SizedBox(height: 20),
        // Título 
        const Text(
          'SGD Movil',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        // Subtítulo 
        const Text(
          'Sistema de Gestión Documental',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Indicador de modo sin conexión
        if (_isOfflineMode)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Sin conexión a internet. El inicio de sesión requiere conexión.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 40),
        
        // Formulario
        Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Campo de email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su usuario';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Campo de contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  
                  // Opción Recordarme y Olvidó contraseña
                  Row(
                    children: [
                      // Checkbox 
                      Checkbox(
                        value: _rememberMe,
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Recordarme'),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // Función para recuperar contraseña
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Función en desarrollo: Recuperar contraseña'),
                            ),
                          );
                        },
                        child: Text(
                          '¿Olvidó su contraseña?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Botón de inicio de sesión
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isOfflineMode || _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Información de copyright
        Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Text(
            '© ${DateTime.now().year} Ministerio de la Mujer y Poblaciones Vulnerables',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}