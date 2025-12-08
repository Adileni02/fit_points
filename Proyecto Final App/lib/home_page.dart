import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'notification_service.dart';
import 'auth_service.dart';
import 'map_page.dart';
import 'login_page.dart';
import 'rutinas_page.dart';

const Color kGreenPrimary = Color(0xFF00D26A);
const Color kGreenDark = Color(0xFF006B3F);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _DashboardPage(),
      const MapPage(),
      const RutinasPage(),
      _ProfilePage(
        onLogout: () async {
          await _authService.logout();
        },
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: kGreenPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Rutinas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ---------- DASHBOARD / INICIO ----------
class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  void _showInfoDialog(
      BuildContext context, {
        required String title,
        required String description,
      }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Entendido',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header degradado
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kGreenDark, kGreenPrimary],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                'Bienvenido a FitPoints',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Empieza tu día con una buena rutina o encuentra un lugar '
                    'para entrenar cerca de ti.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Tarjetas rápidas
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _HomeCard(
                  icon: Icons.map,
                  title: 'Mapa de puntos',
                  subtitle: 'Ver lugares para entrenar',
                  onTap: () {
                    _showInfoDialog(
                      context,
                      title: 'Mapa de puntos',
                      description:
                      'En el mapa podrás ver parques, gimnasios y otros '
                          'puntos recomendados cerca de ti para entrenar.',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HomeCard(
                  icon: Icons.fitness_center,
                  title: 'Rutinas',
                  subtitle: 'Ver entrenamientos',
                  onTap: () {
                    _showInfoDialog(
                      context,
                      title: 'Rutinas',
                      description:
                      'Aquí encontrarás rutinas personalizadas según tu '
                          'nivel, objetivo, entorno y músculos que quieras entrenar.',
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ---------- PODÓMETRO ----------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _HomeCard(
            icon: Icons.directions_walk,
            title: 'Podómetro',
            subtitle: 'Revisa tus pasos de hoy',
            onTap: () {
              // Ahora solo navegamos; la pantalla de podómetro se encarga del permiso
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PedometerPage(),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Hoy para ti',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Botón de mensajes motivacionales
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: () {
              NotificationService().showRandomMotivational();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: kGreenPrimary,
              elevation: 2,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite),
                SizedBox(width: 8),
                Text('Motívame 💚'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ---------- CARD REUTILIZABLE ----------
class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kGreenPrimary.withOpacity(0.15),
              child: Icon(icon, color: kGreenPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- PERFIL ----------
class _ProfilePage extends StatefulWidget {
  final Future<void> Function() onLogout;

  const _ProfilePage({required this.onLogout});

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  bool _loading = true;
  Map<String, dynamic>? _userData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'No hay usuario autenticado';
          _loading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'No se encontraron datos de perfil';
          _loading = false;
        });
        return;
      }

      setState(() {
        _userData = doc.data();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar perfil: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final name = _userData?['name'] ?? 'Sin nombre';
    final email = _userData?['email'] ?? currentUser?.email ?? '';
    final age = _userData?['age'];
    final streak = (_userData?['loginStreak'] ?? 0) as int;

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: _loading
          ? ListView(
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      )
          : ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header verde
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kGreenDark, kGreenPrimary],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    _getInitials(name),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ProfileInfoCard(
                name: name,
                email: email,
                age: age,
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tu progreso',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StreakCard(streak: streak),
            ),
          ],

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await widget.onLogout();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    final initials = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    return initials;
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final String name;
  final String email;
  final dynamic age;

  const _ProfileInfoCard({
    required this.name,
    required this.email,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    final ageText = age != null ? age.toString() : 'N/D';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de la cuenta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.person, 'Nombre', name),
            const SizedBox(height: 8),
            _infoRow(Icons.email, 'Correo', email),
            const SizedBox(height: 8),
            _infoRow(Icons.cake, 'Edad', ageText),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kGreenPrimary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------- TARJETA RACHA ----------
class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({required this.streak});

  String _subtitle() {
    if (streak <= 0) {
      return 'Empieza tu racha entrando hoy 💪';
    } else if (streak == 1) {
      return '¡Llevas 1 día seguido usando FitPoints! 🔥';
    } else {
      return 'Llevas $streak días seguidos usando FitPoints 🔥';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(23),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Racha de FitPoints',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- PANTALLA PODÓMETRO ----------
class PedometerPage extends StatefulWidget {
  const PedometerPage({super.key});

  @override
  State<PedometerPage> createState() => _PedometerPageState();
}

class _PedometerPageState extends State<PedometerPage> {
  Stream<StepCount>? _stepCountStream;
  int _steps = 0;
  String _status = 'Inicializando...';

  bool _checkingPermission = true; // mientras revisamos permiso
  bool _hasPermission = false;     // si ya hay permiso o no

  @override
  void initState() {
    super.initState();
    _checkPermissionOnStart();
  }

  /// Revisa permiso al entrar
  Future<void> _checkPermissionOnStart() async {
    final status = await Permission.activityRecognition.status;

    if (status.isGranted) {
      _startPedometer();
      setState(() {
        _hasPermission = true;
        _checkingPermission = false;
        _status = 'Contando pasos...';
      });
    } else {
      setState(() {
        _hasPermission = false;
        _checkingPermission = false;
        _status = 'Permiso de actividad requerido';
      });
    }
  }

  /// Botón "Conceder permiso"
  Future<void> _requestPermission() async {
    final status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      _startPedometer();
      setState(() {
        _hasPermission = true;
        _status = 'Contando pasos...';
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _status =
        'El permiso está bloqueado. Actívalo desde Ajustes > Aplicaciones > Permisos.';
      });
      await openAppSettings();
    } else {
      setState(() {
        _hasPermission = false;
        _status = 'Sin permiso de actividad, no se pueden contar pasos.';
      });
    }
  }

  void _startPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream!.listen(
      _onStepData,
      onError: _onStepError,
      cancelOnError: false,
    );
  }

  void _onStepData(StepCount event) {
    setState(() {
      _steps = event.steps;
      _status = 'Contando pasos...';
    });

    NotificationService().handleNewSteps(event.steps);
  }

  void _onStepError(error) {
    setState(() {
      _status = 'Error al leer pasos';
    });
  }

  int get _fitPoints => (_steps / 20).floor();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kGreenDark,
        title: const Text('Podómetro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _checkingPermission
            ? const Center(child: CircularProgressIndicator())
            : !_hasPermission
        // Pantalla para pedir permiso
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_walk,
              size: 60,
              color: kGreenPrimary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Para usar el podómetro necesitas permitir el acceso '
                  'a la actividad física.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreenPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Conceder permiso'),
            ),
          ],
        )
        // UI normal cuando ya hay permiso
            : Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_walk,
                      size: 60,
                      color: kGreenPrimary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pasos de hoy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_steps',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: kGreenPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FitPoints estimados',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_fitPoints puntos (1 punto cada 20 pasos)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                NotificationService().showStepsNow(_steps);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreenPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.notifications),
              label: const Text(
                'Ver pasos en notificación',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const Text(
              'Camina con tu dispositivo en el bolsillo para registrar tus pasos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
