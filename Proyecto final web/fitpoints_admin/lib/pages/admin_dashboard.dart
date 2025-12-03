import 'package:flutter/material.dart';
import 'dashboard_theme.dart';
import 'points_tab.dart';
import 'users_tab.dart';
import 'notifications_tab.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 320,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kGreenStart, kGreenEnd],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'FitPoints',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Panel de administración\npara monitorear y gestionar\nlos puntos de actividad física.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: Colors.white70,
                  ),
                ),
                Spacer(),
                Text(
                  'Solo usuarios marcados como admin\npueden acceder a este panel.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: kLightBg,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: DefaultTabController(
                length: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FitPoints - Administración',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Cerrar sesión',
                              onPressed: () {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                      (_) => false,
                                );
                              },
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const TabBar(
                        indicator: BoxDecoration(
                          color: kPrimaryGreen,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.black54,
                        tabs: [
                          Tab(text: 'Puntos'),
                          Tab(text: 'Usuarios'),
                          Tab(text: 'Notificaciones'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: TabBarView(
                        children: [
                          PointsTab(),
                          UsersTab(),
                          NotificationsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
