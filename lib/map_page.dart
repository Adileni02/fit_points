import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'location_service.dart';
import 'fit_point.dart';
import 'home_page.dart'; // usando kGreenPrimary / kGreenDark

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  // Centro por defecto (Tepic aprox)
  static const LatLng _center = LatLng(21.5010, -104.8940);

  // Ubicación actual del usuario
  LatLng? _currentLatLng;
  StreamSubscription<Position>? _positionStreamSub;

  // Puntos desde Firestore
  List<FitPoint> _points = [];
  bool _loadingPoints = true;

  // Suscripción a Firestore (tiempo real)
  StreamSubscription<QuerySnapshot>? _fitpointsSub;

  FitPoint? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _subscribeToFitpoints();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _fitpointsSub?.cancel();
    super.dispose();
  }

  // ---------- GPS: ubicación actual ----------

  Future<void> _initLocation() async {
    debugPrint('🛰 Iniciando _initLocation...');

    try {
      final pos = await LocationService.determinePosition();
      debugPrint('✅ Posición inicial: ${pos.latitude}, ${pos.longitude}');

      final firstLatLng = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _currentLatLng = firstLatLng;
      });

      // Centra el mapa en la posición inicial del usuario
      _mapController.move(firstLatLng, 16);

      // Escucha cambios de ubicación en tiempo real
      _positionStreamSub =
          LocationService.getPositionStream().listen((Position newPos) {
            final newLatLng = LatLng(newPos.latitude, newPos.longitude);
            debugPrint('🔁 Nueva posición: ${newPos.latitude}, ${newPos.longitude}');

            setState(() {
              _currentLatLng = newLatLng;
            });

            // El mapa sigue al usuario (si no quieres esto, quítalo)
            _mapController.move(newLatLng, _mapController.camera.zoom);
          });
    } catch (e) {
      debugPrint('❌ Error al inicializar ubicación: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
        ),
      );
    }
  }

  void _centerOnUserOrDefault() {
    final target = _currentLatLng ?? _center;
    _mapController.move(target, 16);
  }

  // ---------- Firestore: FitPoints ----------

  void _subscribeToFitpoints() {
    _fitpointsSub = FirebaseFirestore.instance
        .collection('fitpoints')
        .snapshots()
        .listen((snapshot) {
      final points =
      snapshot.docs.map((doc) => FitPoint.fromFirestore(doc)).toList();

      setState(() {
        _points = points;
        _loadingPoints = false;
      });

      debugPrint('📍 FitPoints cargados: ${points.length}');
    }, onError: (e) {
      debugPrint('❌ Error al escuchar fitpoints: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar FitPoints: $e')),
      );
      setState(() {
        _loadingPoints = false;
      });
    });
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    const greenPrimary = kGreenPrimary;
    const greenDark = kGreenDark;

    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              minZoom: 10,
              maxZoom: 19,
            ),
            children: [
              // Capa base de OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.proyecto_final',
              ),

              // Marcadores de FitPoints desde Firestore
              if (!_loadingPoints)
                MarkerLayer(
                  markers: _points.map((p) {
                    IconData iconData;
                    Color iconColor;

                    switch (p.type) {
                      case 'park':
                        iconData = Icons.park;
                        iconColor = Colors.green[700]!;
                        break;

                      case 'gym':
                      case 'fitness_centre':
                        iconData = Icons.fitness_center;
                        iconColor = Colors.redAccent;
                        break;

                      case 'sports_centre':
                        iconData = Icons.sports;
                        iconColor = Colors.orange;
                        break;

                      case 'pitch':
                      case 'track':
                      case 'stadium':
                        iconData = Icons.sports_soccer;
                        iconColor = Colors.blueGrey;
                        break;

                      default:
                        iconData = Icons.place;
                        iconColor = Colors.blue;
                    }

                    return Marker(
                      point: p.position,
                      width: 42,
                      height: 42,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPoint = p;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              iconData,
                              color: iconColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Marcador de la ubicación actual del usuario
              if (_currentLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLatLng!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.25),
                          border: Border.all(
                            color: Colors.blue,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.circle,
                            color: Colors.blue,
                            size: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Encabezado flotante
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                padding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [greenDark, greenPrimary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mapa de FitPoints',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _loadingPoints
                          ? 'Cargando lugares para entrenar...'
                          : 'Encuentra parques, gimnasios y puntos para entrenar cerca de ti.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botones flotantes (zoom y centrar)
          Positioned(
            right: 16,
            bottom: 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in_button',
                  backgroundColor: Colors.white,
                  mini: true,
                  onPressed: () {
                    final camera = _mapController.camera;
                    _mapController.move(
                      camera.center,
                      camera.zoom + 1,
                    );
                  },
                  child: Icon(
                    Icons.add,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out_button',
                  backgroundColor: Colors.white,
                  mini: true,
                  onPressed: () {
                    final camera = _mapController.camera;
                    _mapController.move(
                      camera.center,
                      camera.zoom - 1,
                    );
                  },
                  child: Icon(
                    Icons.remove,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'center_button',
                  backgroundColor: Colors.white,
                  mini: false,
                  onPressed: _centerOnUserOrDefault,
                  child: Icon(
                    Icons.my_location,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Tarjeta inferior con detalle del FitPoint seleccionado
          if (_selectedPoint != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.place, color: greenPrimary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedPoint!.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedPoint = null;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_selectedPoint!.type} · (${_selectedPoint!.position.latitude.toStringAsFixed(5)}, '
                            '${_selectedPoint!.position.longitude.toStringAsFixed(5)})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 8),
                      if ((_selectedPoint!.description ?? '').isNotEmpty)
                        Text(
                          _selectedPoint!.description!,
                          style: TextStyle(fontSize: 13),
                        ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // Aquí podrías abrir detalle, navegación, rutinas, etc.
                            },
                            icon: Icon(Icons.fitness_center, size: 18),
                            label: Text(
                              'Ver rutinas sugeridas',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
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
