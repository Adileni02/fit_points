import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color kGreenPrimary = Color(0xFF00D26A);
const Color kGreenDark = Color(0xFF006B3F);
const Color kBgColor = Color(0xFFF5F5F5);

class RutinasPage extends StatefulWidget {
  const RutinasPage({super.key});

  @override
  State<RutinasPage> createState() => _RutinasPageState();
}

class _RutinasPageState extends State<RutinasPage> {
  String _selectedNivelLabel = 'Intermedio';
  String? _selectedObjetivoLabel = 'Resistencia';
  String? _selectedEntornoLabel = 'Calistenia';

  final Set<String> _selectedMuscleLabels = {};

  final Map<String, String> _niveles = {
    'Fácil': 'facil',
    'Intermedio': 'intermedio',
    'Avanzado': 'avanzado',
  };

  final Map<String, String> _objetivos = {
    'Resistencia': 'resistencia',
    'Fuerza': 'fuerza',
    'Hipertrofia': 'hipertrofia',
  };

  final Map<String, String> _entornos = {
    'Calistenia': 'peso_corporal',
    'Gimnasio': 'gimnasio',
  };

  final List<_MuscleOption> _muscles = const [
    _MuscleOption('Abdominales', 'abdomen', Icons.fitness_center),
    _MuscleOption('Espalda', 'espalda', Icons.accessibility_new),
    _MuscleOption('Bíceps', 'biceps', Icons.accessibility),
    _MuscleOption('Tríceps', 'triceps', Icons.accessibility), // 🔹 NUEVO
    _MuscleOption('Pecho', 'pecho', Icons.sports_gymnastics),
    _MuscleOption('Piernas', 'pierna', Icons.directions_run),
  ];


  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBgColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFiltersCard(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildResultsTitle(),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildResultsList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
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
        children: const [
          Text(
            'Rutinas personalizadas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Elige tu nivel, objetivo y área de enfoque.\n'
                'Te mostramos rutinas diseñadas para ti.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI: CARD DE FILTROS
  // ---------------------------------------------------------------------------
  Widget _buildFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubtitle('Nivel'),
          const SizedBox(height: 8),
          _buildSegmentedFilter(
            labels: _niveles.keys.toList(),
            selectedLabel: _selectedNivelLabel,
            onSelected: (value) {
              setState(() => _selectedNivelLabel = value);
            },
          ),
          const SizedBox(height: 16),

          _buildSubtitle('Tipo de ejercicio'),
          const SizedBox(height: 8),
          _buildSegmentedFilter(
            labels: _objetivos.keys.toList(),
            selectedLabel: _selectedObjetivoLabel,
            onSelected: (value) {
              setState(() => _selectedObjetivoLabel = value);
            },
          ),
          const SizedBox(height: 16),

          _buildSubtitle('Entorno'),
          const SizedBox(height: 8),
          _buildSegmentedFilter(
            labels: _entornos.keys.toList(),
            selectedLabel: _selectedEntornoLabel,
            onSelected: (value) {
              setState(() => _selectedEntornoLabel = value);
            },
          ),
          const SizedBox(height: 16),

          _buildSubtitle('Área de enfoque'),
          const SizedBox(height: 4),
          const Text(
            'Puedes seleccionar varias opciones.',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 8),
          _buildMuscleGrid(),
        ],
      ),
    );
  }

  // ahora pedimos al menos 1 músculo
  bool get _hasFullSelection =>
      _selectedObjetivoLabel != null &&
          _selectedEntornoLabel != null &&
          _selectedMuscleLabels.isNotEmpty;

  Widget _buildSubtitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  /// Segmentado genérico para nivel / objetivo / entorno
  Widget _buildSegmentedFilter({
    required List<String> labels,
    required String? selectedLabel,
    required ValueChanged<String> onSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kBgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: labels.map((label) {
          final isSelected = label == selectedLabel;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(label),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    )
                  ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? kGreenDark : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Grid de músculos tipo cards (multi-selección, 2 columnas)
  Widget _buildMuscleGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2; // 2 columnas
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _muscles.map((m) {
            final bool isSelected = _selectedMuscleLabels.contains(m.label);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedMuscleLabels.remove(m.label);
                  } else {
                    _selectedMuscleLabels.add(m.label);
                  }
                });
              },
              child: Container(
                width: itemWidth,
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? kGreenPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color:
                    isSelected ? kGreenPrimary : Colors.grey.shade300,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : kGreenPrimary.withOpacity(0.1),
                      child: Icon(
                        m.icon,
                        size: 20,
                        color: isSelected ? Colors.white : kGreenPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                          isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // RESULTADOS
  // ---------------------------------------------------------------------------
  Widget _buildResultsTitle() {
    if (!_hasFullSelection) {
      return const Text(
        'Selecciona todas las opciones para ver las rutinas disponibles.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return const Text(
      'Rutinas recomendadas',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildResultsList() {
    if (!_hasFullSelection) {
      return const SizedBox.shrink();
    }

    final objetivoValue = _objetivos[_selectedObjetivoLabel]!;
    final entornoValue = _entornos[_selectedEntornoLabel]!;
    final nivelValue = _niveles[_selectedNivelLabel]!;

    // Lista de valores de Firestore para los músculos seleccionados
    final selectedMuscleValues = _muscles
        .where((m) => _selectedMuscleLabels.contains(m.label))
        .map((m) => m.firestoreValue)
        .toList();

    Query query = FirebaseFirestore.instance
        .collection('rutinas')
        .where('objetivo', isEqualTo: objetivoValue)
        .where('entorno', isEqualTo: entornoValue)
        .where('nivel', isEqualTo: nivelValue);

    // un músculo -> isEqualTo, varios -> whereIn
    if (selectedMuscleValues.length == 1) {
      query = query.where('musculo', isEqualTo: selectedMuscleValues.first);
    } else {
      query = query.where('musculo', whereIn: selectedMuscleValues);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: kGreenPrimary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Error al cargar rutinas: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'No encontramos rutinas para esa combinación.\n'
                  'Prueba cambiando el nivel u objetivo.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final nombre =
                data['nombre'] as String? ?? 'Rutina sin nombre';
            final ejerciciosRaw =
                data['ejercicios'] as List<dynamic>? ?? [];
            final ejercicios =
            ejerciciosRaw.cast<Map<String, dynamic>>();

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_selectedNivelLabel} · '
                          '${_selectedObjetivoLabel} · '
                          '${_selectedEntornoLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...ejercicios.map((e) {
                      final nombreEj = e['nombre'] ?? '';
                      final series = e['series'] ?? '';
                      final reps = e['reps'] ?? '';
                      final descanso = e['descanso_seg'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '• $nombreEj — $series x $reps  (descanso ${descanso}s)',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Helper para músculo
class _MuscleOption {
  final String label;
  final String firestoreValue;
  final IconData icon;

  const _MuscleOption(this.label, this.firestoreValue, this.icon);
}
