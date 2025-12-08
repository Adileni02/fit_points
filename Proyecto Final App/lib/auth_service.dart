import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Instancia de FirebaseAuth para manejar login/registro
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instancia de Firestore para guardar info extra del usuario
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Registro de usuario + creación de documento en Firestore + envío de correo de verificación
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required int age,
  }) async {
    try {
      // Crea el usuario en Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Envía correo de verificación al usuario
      await cred.user!.sendEmailVerification();

      // Guarda datos básicos y configuración inicial en Firestore
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'age': age,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        // Datos para manejar racha de inicio de sesión
        'loginStreak': 0,      // racha inicial
        'lastLoginDate': null, // aún sin primer login registrado
      });

      return null; // null = todo salió bien
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Error de autenticación';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // Login con validación de correo verificado y actualización de racha
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Inicia sesión con Firebase Auth
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Si el correo no está verificado, vuelve a enviar enlace y cierra sesión
      if (!cred.user!.emailVerified) {
        await cred.user!.sendEmailVerification();
        await _auth.signOut();

        return 'Debes verificar tu correo antes de iniciar sesión. '
            'Te enviamos un enlace a $email. Revisa tu bandeja de entrada o spam.';
      }

      // Si todo bien, actualiza la racha de inicio de sesión
      await _updateLoginStreak(cred.user!);

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Error de autenticación';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // Cierra sesión del usuario actual
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Stream para escuchar cambios en el estado de autenticación (logueado / no logueado)
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ------------ LÓGICA DE RACHA DE INICIO DE SESIÓN ------------

  // Actualiza la racha de días seguidos que el usuario ha iniciado sesión
  Future<void> _updateLoginStreak(User user) async {
    final docRef = _db.collection('users').doc(user.uid);

    // Transacción para asegurar lectura y escritura consistentes
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);

      final now = DateTime.now();
      // Nos quedamos solo con año/mes/día (sin hora) para comparar por día
      final today = DateTime(now.year, now.month, now.day);

      int streak = 1; // valor por defecto si no hay datos previos

      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        final lastLoginTs = data['lastLoginDate'];

        if (lastLoginTs != null && lastLoginTs is Timestamp) {
          final lastDate = lastLoginTs.toDate();
          final lastDay =
          DateTime(lastDate.year, lastDate.month, lastDate.day);
          final diffDays = today.difference(lastDay).inDays;

          if (diffDays == 0) {
            // Ya inició sesión hoy → mantener misma racha
            streak = (data['loginStreak'] ?? 1) as int;
          } else if (diffDays == 1) {
            // Inició sesión ayer → aumentar racha
            streak = ((data['loginStreak'] ?? 0) as int) + 1;
          } else {
            // Pasó más de un día sin iniciar sesión → reiniciar racha
            streak = 1;
          }
        }
      }

      // Guarda fecha del día de hoy y nueva racha
      tx.set(
        docRef,
        {
          'lastLoginDate': Timestamp.fromDate(today),
          'loginStreak': streak,
        },
        SetOptions(merge: true), // solo actualiza estos campos
      );
    });
  }
}
