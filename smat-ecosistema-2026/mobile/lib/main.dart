import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_page.dart';
import 'services/auth_service.dart';

void main() => runApp(const SMATApp());

class SMATApp extends StatelessWidget {
  const SMATApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMAT Mobile',

      // El home depende de la verificación del token
      home: FutureBuilder<String?>(
        future: AuthService().getToken(),

        builder: (context, snapshot) {

          // Mientras verifica el token
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Si existe token -> Home
          if (snapshot.hasData && snapshot.data != null) {
            return const HomePage();
          }

          // Si no existe token -> Login
          return const LoginScreen();
        },
      ),
    );
  }
}