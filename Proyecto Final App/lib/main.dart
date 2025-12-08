import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'package:fit_points/login_page.dart';
import 'package:fit_points/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FitPointsApp());
}

class FitPointsApp extends StatelessWidget {
  const FitPointsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitPoints',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00D26A)),
        useMaterial3: false,
      ),
      // 👇 en vez de home: HomePage(), usamos el AuthGate
      home: const AuthGate(),
    );
  }
}


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si NO hay usuario logueado → LoginPage
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // Si SÍ hay usuario → HomePage
        return HomePage();
      },
    );
  }
}
