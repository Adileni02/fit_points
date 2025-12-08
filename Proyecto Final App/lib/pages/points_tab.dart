import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dashboard_theme.dart';

class PointsTab extends StatefulWidget {
  const PointsTab({super.key});
  @override
  State<PointsTab> createState() => _PointsTabState();
}

class _PointsTabState extends State<PointsTab> {
  LatLng? _lastCenter;
  final List<String> _selectedIds = [];
  String _searchQuery = '';
  bool _isMapExpanded = false;

  Future<Position?> _getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // -------- NUEVO PUNTO --------
  Future<void> _openNewPointDialog() async {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'park');
    final cityCtrl = TextEditingController(text: 'Tepic');
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();

    bool active = true;
    String? error;
    LatLng? selectedPoint = const LatLng(21.5, -104.9);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Nuevo punto'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          hintText: 'Parque Ecológico, Smart Fit, etc.',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: typeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          hintText: 'park, fitness_centre, pitch, etc.',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ciudad',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: latCtrl,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                signed: true,
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Latitud',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: lngCtrl,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                signed: true,
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Longitud',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 230,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: selectedPoint ??
                                  const LatLng(21.5, -104.9),
                              initialZoom: 13,
                              onTap: (tap, point) {
                                setStateDialog(() {
                                  selectedPoint = point;
                                  latCtrl.text =
                                      point.latitude.toStringAsFixed(6);
                                  lngCtrl.text =
                                      point.longitude.toStringAsFixed(6);
                                  error = null;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                'com.example.fitpoints_admin',
                              ),
                              if (selectedPoint != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: selectedPoint!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: kPrimaryGreen,
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Activo'),
                          const SizedBox(width: 8),
                          Switch(
                            value: active,
                            activeColor: kPrimaryGreen,
                            onChanged: (v) {
                              setStateDialog(() {
                                active = v;
                              });
                            },
                          ),
                        ],
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            error!,
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
                    final type = typeCtrl.text.trim();
                    final city = cityCtrl.text.trim();
                    final lat = double.tryParse(
                        latCtrl.text.trim().replaceAll(',', '.'));
                    final lng = double.tryParse(
                        lngCtrl.text.trim().replaceAll(',', '.'));

                    if (name.isEmpty ||
                        type.isEmpty ||
                        city.isEmpty ||
                        lat == null ||
                        lng == null) {
                      setStateDialog(() {
                        error =
                        'Completa nombre, tipo, ciudad y coordenadas válidas.';
                      });
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('fitpoints')
                          .add({
                        'name': name,
                        'type': type,
                        'city': city,
                        'lat': lat,
                        'lng': lng,
                        'active': active,
                        'createdAt': FieldValue.serverTimestamp(),
                        'source': 'admin-panel',
                        'description': '',
                        'level': '',
                        'osmId': null,
                      });
                      Navigator.of(ctx).pop();
                    } catch (e) {
                      setStateDialog(() {
                        error = 'Error al guardar: $e';
                      });
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    typeCtrl.dispose();
    cityCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
  }

  // -------- EDITAR PUNTO --------
  Future<void> _openEditPointDialog(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final currentName = (data['name'] ?? data['nombre'] ?? '').toString();
    final currentType = (data['type'] ?? data['tipo'] ?? '').toString();
    final currentCity = (data['city'] ?? data['ciudad'] ?? '').toString();

    final currentLat = ((data['lat'] ?? data['latitude']) ?? 0.0) as num;
    final currentLng = ((data['lng'] ?? data['longitude']) ?? 0.0) as num;
    final currentActive = (data['active'] ?? data['activo'] ?? false) == true;

    final nameCtrl = TextEditingController(text: currentName);
    final typeCtrl = TextEditingController(text: currentType);
    final cityCtrl = TextEditingController(text: currentCity);
    final latCtrl = TextEditingController(
      text: currentLat.toDouble().toStringAsFixed(6),
    );
    final lngCtrl = TextEditingController(
      text: currentLng.toDouble().toStringAsFixed(6),
    );

    bool active = currentActive;
    String? error;
    LatLng? selectedPoint = LatLng(
      currentLat.toDouble(),
      currentLng.toDouble(),
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Editar punto'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          hintText: 'Parque Ecológico, Smart Fit, etc.',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: typeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          hintText: 'park, fitness_centre, pitch, etc.',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ciudad',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: latCtrl,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                signed: true,
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Latitud',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: lngCtrl,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                signed: true,
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Longitud',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 230,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: selectedPoint ??
                                  const LatLng(21.5, -104.9),
                              initialZoom: 13,
                              onTap: (tap, point) {
                                setStateDialog(() {
                                  selectedPoint = point;
                                  latCtrl.text =
                                      point.latitude.toStringAsFixed(6);
                                  lngCtrl.text =
                                      point.longitude.toStringAsFixed(6);
                                  error = null;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                'com.example.fitpoints_admin',
                              ),
                              if (selectedPoint != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: selectedPoint!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: kPrimaryGreen,
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Activo'),
                          const SizedBox(width: 8),
                          Switch(
                            value: active,
                            activeColor: kPrimaryGreen,
                            onChanged: (v) {
                              setStateDialog(() {
                                active = v;
                              });
                            },
                          ),
                        ],
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            error!,
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
                    final type = typeCtrl.text.trim();
                    final city = cityCtrl.text.trim();
                    final lat = double.tryParse(
                      latCtrl.text.trim().replaceAll(',', '.'),
                    );
                    final lng = double.tryParse(
                      lngCtrl.text.trim().replaceAll(',', '.'),
                    );

                    if (name.isEmpty ||
                        type.isEmpty ||
                        city.isEmpty ||
                        lat == null ||
                        lng == null) {
                      setStateDialog(() {
                        error =
                        'Completa nombre, tipo, ciudad y coordenadas válidas.';
                      });
                      return;
                    }

                    try {
                      await doc.reference.update({
                        'name': name,
                        'type': type,
                        'city': city,
                        'lat': lat,
                        'lng': lng,
                        'active': active,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      Navigator.of(ctx).pop();
                    } catch (e) {
                      setStateDialog(() {
                        error = 'Error al actualizar: $e';
                      });
                    }
                  },
                  child: const Text('Guardar cambios'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    typeCtrl.dispose();
    cityCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Puntos de actividad física',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _openNewPointDialog,
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
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo punto'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: TextField(
                onChanged: (v) {
                  setState(() {
                    _searchQuery = v.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, tipo o ciudad...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                    .collection('fitpoints')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar datos: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  final allDocs = snapshot.data?.docs ?? [];
                  if (allDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay puntos registrados todavía.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  final docs = allDocs.where((doc) {
                    if (_searchQuery.isEmpty) return true;

                    final data = doc.data() as Map<String, dynamic>?;
                    if (data == null) return false;

                    final name =
                    (data['name'] ?? data['nombre'] ?? '').toString();
                    final type =
                    (data['type'] ?? data['tipo'] ?? '').toString();
                    final city =
                    (data['city'] ?? data['ciudad'] ?? '').toString();

                    final haystack =
                    '$name $type $city'.toLowerCase();
                    return haystack.contains(_searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No se encontraron puntos con ese criterio.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
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
                            columnSpacing: 28,
                            columns: const [
                              DataColumn(label: Text('Nombre')),
                              DataColumn(label: Text('Tipo')),
                              DataColumn(label: Text('Lat')),
                              DataColumn(label: Text('Lng')),
                              DataColumn(label: Text('Activo')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: docs.map((doc) {
                              final data =
                              doc.data() as Map<String, dynamic>?;
                              final id = doc.id;

                              final name =
                              (data?['name'] ?? data?['nombre'] ?? '')
                                  .toString();
                              final type =
                              (data?['type'] ?? data?['tipo'] ?? '')
                                  .toString();
                              final lat =
                              ((data?['lat'] ?? data?['latitude']) ??
                                  0.0) as num;
                              final lng =
                              ((data?['lng'] ?? data?['longitude']) ??
                                  0.0) as num;
                              final active = (data?['active'] ??
                                  data?['activo'] ??
                                  false) ==
                                  true;

                              final isSelected =
                              _selectedIds.contains(id);

                              return DataRow(
                                selected: isSelected,
                                color:
                                MaterialStateProperty.resolveWith(
                                      (states) {
                                    if (isSelected) {
                                      return const Color(0xFFE8F5E9);
                                    }
                                    if (states.contains(
                                        MaterialState.hovered)) {
                                      return const Color(0xFFF5F5F5);
                                    }
                                    return Colors.transparent;
                                  },
                                ),
                                onSelectChanged: (_) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedIds.remove(id);
                                    } else {
                                      _selectedIds.add(id);
                                    }
                                    _lastCenter = LatLng(
                                      lat.toDouble(),
                                      lng.toDouble(),
                                    );
                                  });
                                },
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        if (isSelected)
                                          Container(
                                            width: 4,
                                            height: 24,
                                            margin:
                                            const EdgeInsets.only(
                                                right: 8),
                                            decoration: BoxDecoration(
                                              color: kPrimaryGreen,
                                              borderRadius:
                                              BorderRadius.circular(
                                                  999),
                                            ),
                                          ),
                                        Flexible(child: Text(name)),
                                      ],
                                    ),
                                  ),
                                  DataCell(TypeChip(type: type)),
                                  DataCell(Text(lat
                                      .toDouble()
                                      .toStringAsFixed(6))),
                                  DataCell(Text(lng
                                      .toDouble()
                                      .toStringAsFixed(6))),
                                  DataCell(ActiveBadge(active: active)),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'Editar',
                                          icon: Icon(
                                            Icons.edit_rounded,
                                            color: isSelected
                                                ? kPrimaryGreen
                                                : Colors.black54,
                                          ),
                                          onPressed: () {
                                            _openEditPointDialog(doc);
                                          },
                                        ),
                                        IconButton(
                                          tooltip: 'Eliminar',
                                          icon: const Icon(
                                            Icons.delete_rounded,
                                            color: Colors.black54,
                                          ),
                                          onPressed: () async {
                                            await doc.reference
                                                .delete();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mapa de puntos',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isMapExpanded = !_isMapExpanded;
                              });
                            },
                            icon: Icon(
                              _isMapExpanded
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              size: 18,
                            ),
                            label: Text(_isMapExpanded
                                ? 'Reducir mapa'
                                : 'Ampliar mapa'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: _isMapExpanded ? 420 : 260,
                        child: PointsMap(
                          docs: docs,
                          selectedIds: _selectedIds,
                          lastCenter: _lastCenter,
                        ),
                      ),
                    ],
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

// ---------------- MAPA ----------------

class PointsMap extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final List<String> selectedIds;
  final LatLng? lastCenter;

  const PointsMap({
    super.key,
    required this.docs,
    required this.selectedIds,
    this.lastCenter,
  });

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No hay puntos para mostrar.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    final markers = <Marker>[];
    final polyMain = <LatLng>[];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final lat = (data['lat'] ?? data['latitude']) as num?;
      final lng = (data['lng'] ?? data['longitude']) as num?;

      if (lat == null || lng == null) continue;

      final point = LatLng(lat.toDouble(), lng.toDouble());
      final name =
      (data['name'] ?? data['nombre'] ?? '').toString();
      final isSelected = selectedIds.contains(doc.id);

      if (isSelected) polyMain.add(point);

      markers.add(
        Marker(
          point: point,
          width: isSelected ? 48 : 40,
          height: isSelected ? 48 : 40,
          child: Tooltip(
            message: name.isEmpty ? 'Punto sin nombre' : name,
            child: Icon(
              Icons.location_on,
              color: isSelected ? kPrimaryGreen : Colors.red,
              size: isSelected ? 38 : 32,
            ),
          ),
        ),
      );
    }

    if (markers.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Los puntos no tienen coordenadas válidas.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    final center = lastCenter ?? markers.first.point;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13,
          minZoom: 10,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate:
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.fitpoints_admin',
          ),
          if (polyMain.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: polyMain,
                  strokeWidth: 4,
                  color: Colors.blueAccent,
                ),
              ],
            ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
