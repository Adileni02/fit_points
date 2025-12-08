import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class FitPoint {
  final String id;        // id del doc en Firestore (usaremos osmId)
  final String name;
  final String type;      // park, gym, fitness_centre, etc.
  final LatLng position;
  final String? description;
  final String? level;

  FitPoint({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    this.description,
    this.level,
  });

  factory FitPoint.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FitPoint(
      id: doc.id,
      name: data['name'] ?? 'Sin nombre',
      type: data['type'] ?? 'unknown',
      position: LatLng(
        (data['lat'] as num).toDouble(),
        (data['lng'] as num).toDouble(),
      ),
      description: data['description'] as String?,
      level: data['level'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'lat': position.latitude,
      'lng': position.longitude,
      'description': description ?? '',
      'level': level ?? '',
      'source': 'overpass',
      'osmId': id,
      'city': 'Tepic',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
