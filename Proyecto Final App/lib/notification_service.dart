import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // 👉 mensajes motivacionales para las notificaciones locales
  final List<String> _mensajesMotivacionales = [
    '¡Cada paso cuenta, sigue así! 💪',
    'Hoy es un buen día para superar tu propia marca 🏃‍♀️',
    'Tu cuerpo puede más de lo que tu mente cree ✨',
    'No tienes que ser el mejor, solo mejor que ayer 🙌',
    '5 minutos de movimiento son mejor que 0 minutos 🔥',
    'Tu versión futura te va a agradecer este esfuerzo 💚',
    'Pequeños pasos = grandes resultados a largo plazo 🚀',
  ];

  int _lastStepsNotified = 0; // último valor de pasos al que ya notificamos
  final int _stepDeltaThreshold = 500; // cada cuántos pasos notificar
  final int _minStepsForNotify = 500;  // mínimo de pasos para empezar a notificar

  Future<void> init() async {
    // Configuración inicial de notificaciones locales (solo Android aquí)
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Aquí manejas qué pasa cuando el usuario toca la notificación
      },
    );

    // 👇 Android 13+: pedir permiso de notificaciones
    if (Platform.isAndroid) {
      final androidImpl =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidImpl?.requestNotificationsPermission();
    }

    // 👇 Cada vez que se inicializa el servicio (app abierta en frío) mandamos un mensaje motivacional
    await showRandomMotivational();
  }

  // ---------------------------------------------------------------------------
  // 0) CANAL DE NOTIFICACIÓN BASE
  // ---------------------------------------------------------------------------

  NotificationDetails _buildNotificationDetails() {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'fitpoints_channel', // ID del canal
      'Notificaciones FitPoints', // Nombre del canal
      channelDescription: 'Notificaciones locales de FitPoints',
      importance: Importance.max,
      priority: Priority.high,
    );

    return const NotificationDetails(
      android: androidDetails,
    );
  }

  // ---------------------------------------------------------------------------
  // 1) NOTIFICACIONES MOTIVACIONALES
  // ---------------------------------------------------------------------------

  /// Mostrar un mensaje motivacional aleatorio una sola vez
  Future<void> showRandomMotivational() async {
    final random = Random();
    final mensaje =
    _mensajesMotivacionales[random.nextInt(_mensajesMotivacionales.length)];

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // id único
      'FitPoints',
      mensaje,
      _buildNotificationDetails(),
    );
  }

  // ---------------------------------------------------------------------------
  // 2) NOTIFICACIONES LIGADAS AL PODÓMETRO (PASOS)
  // ---------------------------------------------------------------------------

  /// Llama a este método desde donde YA estés leyendo los pasos.
  /// Por ejemplo: cada vez que se actualice el contador de pasos del día.
  Future<void> handleNewSteps(int steps) async {
    // Evitar spam: solo notificar cuando supere el mínimo
    // y haya avanzado al menos _stepDeltaThreshold pasos desde la última notificación.
    if (steps >= _minStepsForNotify &&
        steps - _lastStepsNotified >= _stepDeltaThreshold) {
      _lastStepsNotified = steps;

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '¡Buen ritmo! 💚',
        'Llevas $steps pasos hoy. ¡Sigue moviéndote! 🏃‍♂️',
        _buildNotificationDetails(),
      );
    }
  }

  // Si quieres lanzar una notificación manual con los pasos actuales:
  Future<void> showStepsNow(int steps) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Progreso de hoy',
      'Vas en $steps pasos, ¡vas muy bien! 🔥',
      _buildNotificationDetails(),
    );
  }
}
