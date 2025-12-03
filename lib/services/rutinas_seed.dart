import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Carga el archivo assets/rutinas.json y lo inserta en la colección `rutinas` en Firestore.
/// Solo lo hace si la colección está vacía (para no duplicar).
Future<void> seedRutinasIfEmpty() async {
  final CollectionReference rutinasRef =
  FirebaseFirestore.instance.collection('rutinas');

  // Ver si ya hay al menos una rutina
  final existing = await rutinasRef.limit(1).get();
  if (existing.docs.isNotEmpty) {
    print('⚠️ La colección "rutinas" ya tiene datos, no se vuelven a cargar.');
    return;
  }

  // Leer el JSON de assets
  final String jsonStr = await rootBundle.loadString('assets/rutinas.json');
  final List<dynamic> data = json.decode(jsonStr);

  // Usamos un batch para escribir varias a la vez
  final WriteBatch batch = FirebaseFirestore.instance.batch();

  for (final item in data) {
    final docRef = rutinasRef.doc(); // genera un ID automático
    batch.set(docRef, item);
  }

  await batch.commit();
  print('✅ Rutinas cargadas en Firestore correctamente.');
}