import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'theme.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const SrciamApp());
}

class SrciamApp extends StatelessWidget {
  const SrciamApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIRCIAM',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final isLoggedIn = await _authService.isLoggedIn();
    
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }
    
    if (_isLoggedIn) {
      // Obtener el usuario actual
      return FutureBuilder(
        future: _authService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            return HomePage(user: snapshot.data!);
          }
          
          // Si hay algún problema, volvemos a la pantalla de login
          return const LoginPage();
        },
      );
    }
    
    return const LoginPage();
  }
}