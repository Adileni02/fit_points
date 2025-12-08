import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dashboard_theme.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  int? _lastCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Notificaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aquí se muestran los últimos usuarios registrados en tiempo real. Cada vez que alguien nuevo ingresa a la app, aparecerá una notificación.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar notificaciones: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (_lastCount == null) {
                    _lastCount = docs.length;
                  } else if (docs.length > _lastCount!) {
                    final nuevos = docs.length - _lastCount!;
                    _lastCount = docs.length;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            nuevos == 1
                                ? 'Se registró un nuevo usuario.'
                                : 'Se registraron $nuevos nuevos usuarios.',
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: kPrimaryGreen,
                        ),
                      );
                    });
                  }

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aún no hay usuarios registrados.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: Color(0xFFE0E0E0),
                    ),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>?;

                      final name =
                      (data?['name'] ?? data?['nombre'] ?? '').toString();
                      final email = (data?['email'] ?? '').toString();
                      final createdAt = data?['createdAt'];

                      DateTime? createdAtDate;
                      if (createdAt is Timestamp) {
                        createdAtDate = createdAt.toDate();
                      }

                      final createdText = createdAtDate != null
                          ? _formatDateTime(createdAtDate)
                          : 'Fecha no disponible';

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: kPrimaryGreen,
                          child: Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          name.isEmpty ? 'Usuario sin nombre' : name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '$email\nRegistrado: $createdText',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    dt = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
