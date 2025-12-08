import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'fit_point.dart';

// Servicio que consulta Overpass y guarda lugares en Firestore
class OverpassToFirestoreService {
  static const String _endpoint = 'https://overpass-api.de/api/interpreter';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Importa parques/gimnasios de la zona de Tepic y los guarda en "fitpoints"
  Future<void> importTepicPlacesToFirestore() async {
    // Bounding box aproximado de Tepic
    const double south = 21.40;
    const double north = 21.60;
    const double west = -105.00;
    const double east = -104.75;

    // Consulta Overpass QL para parques, gimnasios y zonas deportivas
    final String query = '''
[out:json][timeout:25];
(
  node["leisure"="park"]($south,$west,$north,$east);
  way["leisure"="park"]($south,$west,$north,$east);
  relation["leisure"="park"]($south,$west,$north,$east);

  node["amenity"="gym"]($south,$west,$north,$east);
  way["amenity"="gym"]($south,$west,$north,$east);
  relation["amenity"="gym"]($south,$west,$north,$east);

  node["leisure"="fitness_centre"]($south,$west,$north,$east);
  way["leisure"="fitness_centre"]($south,$west,$north,$east);
  relation["leisure"="fitness_centre"]($south,$west,$north,$east);

  node["amenity"="sports_centre"]($south,$west,$north,$east);
  way["amenity"="sports_centre"]($south,$west,$north,$east);
  relation["amenity"="sports_centre"]($south,$west,$north,$east);

  node["leisure"="pitch"]($south,$west,$north,$east);
  way["leisure"="pitch"]($south,$west,$north,$east);
  relation["leisure"="pitch"]($south,$west,$north,$east);
);
out center;
''';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'data': query},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error Overpass: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final List elements = data['elements'] as List? ?? [];

    final batch = _db.batch();
    final collection = _db.collection('fitpoints');

    for (final e in elements) {
      final tags = (e['tags'] ?? {}) as Map<String, dynamic>;

      // Coordenadas (node: lat/lon directo, way/relation: center)
      double? lat;
      double? lon;

      if (e['lat'] != null && e['lon'] != null) {
        lat = (e['lat'] as num).toDouble();
        lon = (e['lon'] as num).toDouble();
      } else if (e['center'] != null) {
        final center = e['center'] as Map<String, dynamic>;
        lat = (center['lat'] as num?)?.toDouble();
        lon = (center['lon'] as num?)?.toDouble();
      }

      if (lat == null || lon == null) continue;

      // Datos básicos
      final String osmId = e['id'].toString();
      final String name = tags['name']?.toString() ?? 'Sin nombre';

      // Detección simple de tipo según tags OSM
      String type = 'unknown';

      final leisure = tags['leisure']?.toString();
      final amenity = tags['amenity']?.toString();

      if (leisure == 'park') type = 'park';
      if (amenity == 'gym') type = 'gym';
      if (leisure == 'fitness_centre') type = 'fitness_centre';
      if (amenity == 'sports_centre') type = 'sports_centre';
      if (leisure == 'pitch') type = 'pitch';
      if (leisure == 'track') type = 'track';
      if (leisure == 'stadium') type = 'stadium';

      final fitPoint = FitPoint(
        id: osmId,
        name: name,
        type: type,
        position: LatLng(lat, lon),
      );

      final docRef = collection.doc(osmId);
      batch.set(docRef, fitPoint.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  // Borra de Firestore los fitpoints sin nombre real (vacío o "sin nombre")
  Future<int> deleteNamelessFitPoints() async {
    final collection = _db.collection('fitpoints');
    final snapshot = await collection.get();

    int deletedCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final String name =
      (data['name'] ?? '').toString().toLowerCase().trim();

      final bool isNameless =
          name.isEmpty || name.contains('sin nombre');

      if (isNameless) {
        await doc.reference.delete();
        deletedCount++;
      }
    }

    return deletedCount;
  }
}
