import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

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

// Home con bottom navigation hacia Dashboard, Mapa, Rutinas y Perfil
class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _DashboardPage(),
      MapPage(),
      RutinasPage(),
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
        items: [
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

// Página principal con accesos rápidos y resumen del día
class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header degradado con mensaje de bienvenida
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
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
          child: Column(
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
        SizedBox(height: 24),

        // Tarjetas rápidas para secciones principales
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _HomeCard(
                  icon: Icons.map,
                  title: 'Mapa de puntos',
                  subtitle: 'Ver lugares para entrenar',
                  onTap: () {
                    // Aquí podrías cambiar de tab al mapa
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _HomeCard(
                  icon: Icons.fitness_center,
                  title: 'Rutinas',
                  subtitle: 'Ver entrenamientos',
                  onTap: () {
                    // Aquí podrías cambiar de tab a rutinas
                  },
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Acceso al podómetro
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _HomeCard(
            icon: Icons.directions_walk,
            title: 'Podómetro',
            subtitle: 'Revisa tus pasos de hoy',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PedometerPage(),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 24),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Hoy para ti',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(height: 8),
      ],
    );
  }
}

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
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
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
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
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

class _RoutineItem extends StatelessWidget {
  final String title;
  final String level;
  final String type;

  const _RoutineItem({
    required this.title,
    required this.level,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.bolt, color: kGreenPrimary),
        title: Text(title),
        subtitle: Text('$level · $type'),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          // Aquí podrías abrir el detalle de la rutina
        },
      ),
    );
  }
}

// Página de perfil con datos básicos y racha de uso
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
        children: [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      )
          : ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header verde con nombre y correo
          Container(
            width: double.infinity,
            padding:
            EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    _getInitials(name),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
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

          SizedBox(height: 24),

          if (_error != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red),
              ),
            )
          else ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _ProfileInfoCard(
                name: name,
                email: email,
                age: age,
              ),
            ),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tu progreso',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _StreakCard(streak: streak),
            ),
          ],

          SizedBox(height: 24),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
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
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.logout),
                label: Text(
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
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de la cuenta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            _infoRow(Icons.person, 'Nombre', name),
            SizedBox(height: 8),
            _infoRow(Icons.email, 'Correo', email),
            SizedBox(height: 8),
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
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
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

// Tarjeta que muestra la racha de días consecutivos
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
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Racha de FitPoints',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _subtitle(),
                    style: TextStyle(
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

// Pantalla de podómetro: muestra pasos y puntos estimados
class PedometerPage extends StatefulWidget {
  const PedometerPage({super.key});

  @override
  State<PedometerPage> createState() => _PedometerPageState();
}

class _PedometerPageState extends State<PedometerPage> {
  Stream<StepCount>? _stepCountStream;
  int _steps = 0;
  String _status = 'Inicializando...';

  @override
  void initState() {
    super.initState();
    _initPedometer();
  }

  // Pide permisos y se suscribe al stream del podómetro
  Future<void> _initPedometer() async {
    final permissionStatus = await Permission.activityRecognition.request();

    if (!permissionStatus.isGranted) {
      setState(() {
        _status = 'Permiso de actividad denegado';
      });
      return;
    }

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream!.listen(
      _onStepData,
      onError: _onStepError,
      cancelOnError: false,
    );

    setState(() {
      _status = 'Contando pasos...';
    });
  }

  void _onStepData(StepCount event) {
    setState(() {
      _steps = event.steps;
      _status = 'Contando pasos...';
    });
  }

  void _onStepError(error) {
    setState(() {
      _status = 'Error al leer pasos';
    });
  }

  // 1 punto cada 20 pasos
  int get _fitPoints => (_steps / 20).floor();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kGreenDark,
        title: Text('Podómetro'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding:
                EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: 60,
                      color: kGreenPrimary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Pasos de hoy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$_steps',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding:
                EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.star, color: kGreenPrimary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FitPoints estimados',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$_fitPoints puntos (1 punto cada 20 pasos)',
                            style: TextStyle(
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
            Spacer(),
            Text(
              'Camina con tu dispositivo en el bolsillo para registrar tus pasos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
