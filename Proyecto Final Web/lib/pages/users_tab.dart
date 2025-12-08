import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dashboard_theme.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  String _searchQuery = '';

  Future<void> _openUserDialog({DocumentSnapshot? doc}) async {
    final isEdit = doc != null;
    final data = doc?.data() as Map<String, dynamic>?;

    final nameCtrl = TextEditingController(text: data?['name'] ?? data?['nombre'] ?? '');
    final emailCtrl = TextEditingController(text: data?['email'] ?? '');
    final ageCtrl = TextEditingController(text: data?['age']?.toString() ?? '');

    String role = (data?['role'] ?? 'user').toString();
    bool isAdmin = (data?['isAdmin'] ?? false) == true;

    String? localError;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(isEdit ? 'Editar usuario' : 'Nuevo usuario'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          hintText: 'Nombre completo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          hintText: 'usuario@correo.com',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ageCtrl,
                        keyboardType: const TextInputType.numberWithOptions(),
                        decoration: const InputDecoration(
                          labelText: 'Edad',
                          hintText: '23',
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(labelText: 'Rol'),
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('User')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          DropdownMenuItem(
                            value: 'coach',
                            child: Text('Coach / Entrenador'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => role = value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Acceso a panel admin'),
                          const SizedBox(width: 8),
                          Switch(
                            value: isAdmin,
                            activeColor: kPrimaryGreen,
                            onChanged: (value) {
                              setStateDialog(() {
                                isAdmin = value;
                                if (isAdmin && role == 'user') {
                                  role = 'admin';
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (localError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            localError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final ageText = ageCtrl.text.trim();
                    final age = int.tryParse(ageText);

                    if (name.isEmpty || email.isEmpty) {
                      setStateDialog(() {
                        localError = 'Nombre y correo son obligatorios.';
                      });
                      return;
                    }
                    if (ageText.isNotEmpty && age == null) {
                      setStateDialog(() {
                        localError = 'La edad debe ser un número entero.';
                      });
                      return;
                    }

                    try {
                      final payload = <String, dynamic>{
                        'name': name,
                        'email': email,
                        'age': age,
                        'role': role,
                        'isAdmin': isAdmin,
                        'updatedAt': FieldValue.serverTimestamp(),
                      };

                      if (!isEdit) {
                        payload['createdAt'] = FieldValue.serverTimestamp();
                      }

                      if (isEdit) {
                        await doc!.reference.update(payload);
                      } else {
                        await FirebaseFirestore.instance.collection('users').add(payload);
                      }

                      Navigator.of(ctx).pop();
                    } catch (e) {
                      setStateDialog(() {
                        localError = 'Error al guardar usuario: $e';
                      });
                    }
                  },
                  child: Text(isEdit ? 'Guardar cambios' : 'Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
    ageCtrl.dispose();
  }

  Future<void> _confirmDeleteUser(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>?;
    final name = (data?['name'] ?? data?['nombre'] ?? '').toString();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Eliminar usuario'),
        content: Text('¿Seguro que deseas eliminar a "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Usuarios registrados',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openUserDialog(),
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Nuevo usuario'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, correo o rol...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('name', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar usuarios: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  final allDocs = snapshot.data?.docs ?? [];

                  if (allDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay usuarios registrados.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  final docs = allDocs.where((doc) {
                    if (_searchQuery.isEmpty) return true;
                    final data = doc.data() as Map<String, dynamic>?;
                    if (data == null) return false;

                    final name = (data['name'] ?? data['nombre'] ?? '').toString();
                    final email = (data['email'] ?? '').toString();
                    final role = (data['role'] ?? '').toString();

                    final haystack = ('$name $email $role').toLowerCase();
                    return haystack.contains(_searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No se encontraron usuarios con ese criterio.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: DataTable(
                      headingTextStyle:
                      theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                      dataTextStyle: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                      headingRowColor:
                      MaterialStateProperty.resolveWith(
                            (states) => const Color(0xFFF3F4F8),
                      ),
                      columnSpacing: 32,
                      columns: const [
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Correo')),
                        DataColumn(label: Text('Edad')),
                        DataColumn(label: Text('Rol')),
                        DataColumn(label: Text('Admin')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>?;

                        final name = (data?['name'] ?? data?['nombre'] ?? '').toString();
                        final email = (data?['email'] ?? '').toString();
                        final age = data?['age'];
                        final role = (data?['role'] ?? '').toString().isEmpty
                            ? 'user'
                            : data!['role'].toString();
                        final isAdmin = (data?['isAdmin'] ?? false) == true;

                        return DataRow(
                          cells: [
                            DataCell(Text(name)),
                            DataCell(Text(email)),
                            DataCell(Text(age?.toString() ?? '-')),
                            DataCell(Text(role)),
                            DataCell(
                              Switch(
                                value: isAdmin,
                                activeColor: kPrimaryGreen,
                                trackColor: MaterialStateProperty.resolveWith(
                                      (states) => kPrimaryGreen.withOpacity(0.3),
                                ),
                                onChanged: (value) {
                                  doc.reference.update({'isAdmin': value});
                                },
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Restablecer contraseña',
                                    icon: const Icon(Icons.lock_reset_rounded,
                                        color: Colors.black54),
                                    onPressed: () async {
                                      try {
                                        await FirebaseAuth.instance
                                            .sendPasswordResetEmail(email: email);

                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Correo enviado a $email',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                            Text('Error: $e'),
                                            backgroundColor:
                                            Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Editar',
                                    icon: const Icon(Icons.edit_rounded),
                                    onPressed: () => _openUserDialog(doc: doc),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    icon: const Icon(Icons.delete_rounded,
                                        color: Colors.redAccent),
                                    onPressed: () => _confirmDeleteUser(doc),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
