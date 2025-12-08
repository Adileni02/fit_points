import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'location_service.dart';
import 'fit_point.dart';
import 'home_page.dart'; // kGreenPrimary / kGreenDark

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  static const LatLng _center = LatLng(21.5010, -104.8940);

  LatLng? _currentLatLng;
  StreamSubscription<Position>? _positionStreamSub;

  List<FitPoint> _points = [];
  bool _loadingPoints = true;
  StreamSubscription<QuerySnapshot>? _fitpointsSub;

  FitPoint? _selectedPoint;

  String _selectedCategory = 'all'; // all, gym, park, sports, other
  String _searchQuery = '';
  bool _followUser = true;

  List<FitPoint> _searchResults = [];
  bool _showSuggestions = false;

  List<LatLng> _routePoints = [];
  bool _loadingRoute = false;

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

  // ---------- GPS ----------

  Future<void> _initLocation() async {
    try {
      final pos = await LocationService.determinePosition();
      final firstLatLng = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _currentLatLng = firstLatLng;
      });

      _mapController.move(firstLatLng, 16);

      _positionStreamSub =
          LocationService.getPositionStream().listen((Position newPos) {
            final newLatLng = LatLng(newPos.latitude, newPos.longitude);

            setState(() {
              _currentLatLng = newLatLng;
            });

            if (_followUser) {
              final camera = _mapController.camera;
              _mapController.move(newLatLng, camera.zoom);
            }
          });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: $e')),
      );
    }
  }

  void _centerOnUserOrDefault() {
    final target = _currentLatLng ?? _center;
    _mapController.move(target, 16);
  }

  void _toggleFollowUser() {
    setState(() => _followUser = !_followUser);
    if (_followUser && _currentLatLng != null) {
      _mapController.move(_currentLatLng!, 16);
    }
  }

  // ---------- Firestore ----------

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
    }, onError: (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar FitPoints: $e')),
      );
      setState(() => _loadingPoints = false);
    });
  }

  // ---------- Filtros / búsqueda ----------

  bool _matchesCategory(FitPoint p) {
    switch (_selectedCategory) {
      case 'gym':
        return p.type == 'gym' || p.type == 'fitness_centre';
      case 'park':
        return p.type == 'park';
      case 'sports':
        return p.type == 'sports_centre' ||
            p.type == 'pitch' ||
            p.type == 'track' ||
            p.type == 'stadium';
      case 'other':
        return !(p.type == 'gym' ||
            p.type == 'fitness_centre' ||
            p.type == 'park' ||
            p.type == 'sports_centre' ||
            p.type == 'pitch' ||
            p.type == 'track' ||
            p.type == 'stadium');
      case 'all':
      default:
        return true;
    }
  }

  List<FitPoint> get _filteredPoints {
    final query = _searchQuery.trim().toLowerCase();

    return _points.where((p) {
      if (!_matchesCategory(p)) return false;
      if (query.isNotEmpty) {
        return p.name.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  void _updateSearchResults(String value) {
    final query = value.trim().toLowerCase();

    setState(() {
      _searchQuery = value;

      if (query.isEmpty) {
        _searchResults = [];
        _showSuggestions = false;
      } else {
        final results = _points.where((p) {
          if (!_matchesCategory(p)) return false;
          return p.name.toLowerCase().contains(query);
        }).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        _searchResults = results.take(8).toList();
        _showSuggestions = _searchResults.isNotEmpty;
      }
    });
  }

  void _goToFirstMatchingPoint() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return;

    FitPoint? match;
    for (final p in _points) {
      if (p.name.toLowerCase().contains(query)) {
        match = p;
        break;
      }
    }

    if (match != null) {
      _focusOnPoint(match);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró ese lugar.')),
      );
    }
  }

  void _focusOnPoint(FitPoint p) {
    _mapController.move(p.position, 17);
    setState(() {
      _selectedPoint = p;
      _routePoints = []; // limpia ruta al cambiar destino
      _showSuggestions = false;
    });
    FocusScope.of(context).unfocus();
  }

  // ---------- Distancia ----------

  String? _distanceToSelected() {
    if (_currentLatLng == null || _selectedPoint == null) return null;

    final meters = Geolocator.distanceBetween(
      _currentLatLng!.latitude,
      _currentLatLng!.longitude,
      _selectedPoint!.position.latitude,
      _selectedPoint!.position.longitude,
    );

    if (meters >= 1000) {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(1)} km de ti';
    } else {
      return '${meters.toStringAsFixed(0)} m de ti';
    }
  }

  // ---------- Ruta "Cómo llegar" ----------

  Future<void> _getRouteToSelected() async {
    if (_currentLatLng == null || _selectedPoint == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas tu ubicación y un punto seleccionado.'),
        ),
      );
      return;
    }

    setState(() {
      _loadingRoute = true;
      _routePoints = [];
    });

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/foot/'
            '${_currentLatLng!.longitude},${_currentLatLng!.latitude};'
            '${_selectedPoint!.position.longitude},${_selectedPoint!.position.latitude}'
            '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        throw Exception('No se encontró ruta.');
      }

      final geometry = routes[0]['geometry'];
      final coords = geometry['coordinates'] as List;

      final points = coords.map<LatLng>((coord) {
        final lon = coord[0] as num;
        final lat = coord[1] as num;
        return LatLng(lat.toDouble(), lon.toDouble());
      }).toList();

      setState(() => _routePoints = points);

      if (_routePoints.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(_routePoints);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo calcular la ruta: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingRoute = false);
      }
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    const greenPrimary = kGreenPrimary;
    const greenDark = kGreenDark;

    return Scaffold(
      body: Stack(
        children: [
          // MAPA
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              minZoom: 10,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.proyecto_final',
              ),

              if (!_loadingPoints)
                MarkerLayer(
                  markers: _filteredPoints.map((p) {
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
                        onTap: () => _focusOnPoint(p),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(iconData, color: iconColor, size: 24),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Ruta en VERDE
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4,
                      color: greenPrimary, // ← verde de tu app
                    ),
                  ],
                ),

              if (_currentLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLatLng!,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.25),
                          border: Border.all(color: Colors.blue, width: 3),
                        ),
                        child: const Center(
                          child: Icon(Icons.circle, color: Colors.blue, size: 8),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // CABECERA + BUSCADOR + FILTROS (más pegado y semi-transparente)
          SafeArea(
            top: true,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        greenDark.withOpacity(0.88),
                        greenPrimary.withOpacity(0.88),
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mapa de FitPoints',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _loadingPoints
                            ? 'Cargando lugares...'
                            : 'Filtra o busca un lugar para entrenar.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // BUSCADOR
                      TextField(
                        onChanged: _updateSearchResults,
                        onSubmitted: (_) => _goToFirstMatchingPoint(),
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Buscar (ej. Parque, Gim)...',
                          hintStyle: const TextStyle(color: Colors.black45),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.96),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      // SUGERENCIAS
                      if (_showSuggestions)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.96),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final p = _searchResults[index];

                              IconData iconData;
                              switch (p.type) {
                                case 'park':
                                  iconData = Icons.park;
                                  break;
                                case 'gym':
                                case 'fitness_centre':
                                  iconData = Icons.fitness_center;
                                  break;
                                case 'sports_centre':
                                case 'pitch':
                                case 'track':
                                case 'stadium':
                                  iconData = Icons.sports_soccer;
                                  break;
                                default:
                                  iconData = Icons.place;
                              }

                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  iconData,
                                  size: 18,
                                  color: kGreenPrimary,
                                ),
                                title: Text(
                                  p.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                                subtitle: Text(
                                  p.type,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                                onTap: () => _focusOnPoint(p),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 5),

                      // FILTROS
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterButton(
                              id: 'all',
                              label: 'Todos',
                              icon: Icons.filter_alt,
                            ),
                            const SizedBox(width: 4),
                            _buildFilterButton(
                              id: 'gym',
                              label: 'Gimnasios',
                              icon: Icons.fitness_center,
                            ),
                            const SizedBox(width: 4),
                            _buildFilterButton(
                              id: 'park',
                              label: 'Parques',
                              icon: Icons.park,
                            ),
                            const SizedBox(width: 4),
                            _buildFilterButton(
                              id: 'sports',
                              label: 'Deporte',
                              icon: Icons.sports_soccer,
                            ),
                            const SizedBox(width: 4),
                            _buildFilterButton(
                              id: 'other',
                              label: 'Otros',
                              icon: Icons.place,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // FABs
          Positioned(
            right: 12,
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
                    _mapController.move(camera.center, camera.zoom + 1);
                  },
                  child: const Icon(Icons.add, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                FloatingActionButton(
                  heroTag: 'zoom_out_button',
                  backgroundColor: Colors.white,
                  mini: true,
                  onPressed: () {
                    final camera = _mapController.camera;
                    _mapController.move(camera.center, camera.zoom - 1);
                  },
                  child: const Icon(Icons.remove, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                FloatingActionButton(
                  heroTag: 'follow_user_button',
                  mini: true,
                  backgroundColor:
                  _followUser ? greenPrimary : Colors.white,
                  onPressed: _toggleFollowUser,
                  child: Icon(
                    _followUser
                        ? Icons.navigation
                        : Icons.navigation_outlined,
                    color: _followUser ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                FloatingActionButton(
                  heroTag: 'center_button',
                  backgroundColor: Colors.white,
                  mini: false,
                  onPressed: _centerOnUserOrDefault,
                  child: const Icon(Icons.my_location, color: Colors.black87),
                ),
              ],
            ),
          ),

          // TARJETA DEL FITPOINT
          if (_selectedPoint != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
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
                            Icon(Icons.place, color: greenPrimary, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _selectedPoint!.name,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              splashRadius: 18,
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _selectedPoint = null;
                                  _routePoints = [];
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedPoint!.type,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                        if (_distanceToSelected() != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _distanceToSelected()!,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if ((_selectedPoint!.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _selectedPoint!.description!,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed:
                              _loadingRoute ? null : _getRouteToSelected,
                              icon: _loadingRoute
                                  ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(Icons.directions_walk, size: 16, color: Colors.green),
                              label: Text(
                                _loadingRoute
                                    ? 'Calculando...'
                                    : 'Cómo llegar',
                                style: const TextStyle(fontSize: 12, color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ------- BOTONES DE FILTRO -------

  Widget _buildFilterButton({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final bool selected = _selectedCategory == id;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = id);
        _updateSearchResults(_searchQuery);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(selected ? 0.9 : 0.5),
            width: selected ? 1.3 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? kGreenPrimary : Colors.white,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? kGreenPrimary : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
