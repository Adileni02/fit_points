import 'package:flutter/material.dart';

const Color kGreenPrimary = Color(0xFF00D26A);
const Color kGreenDark = Color(0xFF006B3F);

class RutinasPage extends StatefulWidget {
  const RutinasPage({super.key});

  @override
  State<RutinasPage> createState() => _RutinasPageState();
}

class _RutinasPageState extends State<RutinasPage> {
  // --------- FILTROS PRINCIPALES (selección única) ----------
  String _selectedNivel = 'Intermedio';
  String _selectedTipo = 'Fuerza';
  String _selectedEntorno = 'Gimnasio';

  final List<String> _niveles = ['Fácil', 'Intermedio', 'Avanzado'];
  final List<String> _tipos = ['Resistencia', 'Fuerza', 'Hipertrofia'];
  final List<String> _entornos = ['Hogar', 'Gimnasio', 'Exterior'];

  // --------- MÚSCULOS / GRUPOS (multi-selección) ----------
  final List<_NamedIcon> _muscles = [
    _NamedIcon('Abdominales', Icons.fitness_center),
    _NamedIcon('Espalda media', Icons.accessibility_new),
    _NamedIcon('Bíceps', Icons.fitness_center),
    _NamedIcon('Tríceps', Icons.fitness_center),
    _NamedIcon('Antebrazos', Icons.pan_tool_alt),
    _NamedIcon('Cuádriceps', Icons.directions_run),
    _NamedIcon('Femoral', Icons.directions_walk),
    _NamedIcon('Pantorrilla', Icons.directions_run),
    _NamedIcon('Glúteo', Icons.arrow_upward),
  ];

  final List<_NamedIcon> _generalGroups = [
    _NamedIcon('Pecho (general)', Icons.fitness_center),
    _NamedIcon('Espalda (general)', Icons.fitness_center),
    _NamedIcon('Piernas (general)', Icons.directions_run),
    _NamedIcon('Brazos', Icons.pan_tool_alt),
    _NamedIcon('Cuerpo completo', Icons.accessibility_new),
  ];

  // Selección del usuario
  final Set<String> _selectedMuscles = {};
  final Set<String> _selectedGeneralGroups = {};

  // --------- RUTINAS DE EJEMPLO (con info de músculos/grupos) ----------
  final List<Map<String, dynamic>> _allRoutines = [
    {
      'nombre': 'Full Body en casa 20 min',
      'nivel': 'Fácil',
      'tipo': 'Resistencia',
      'entorno': 'Hogar',
      'descripcion': 'Rutina suave para activar todo el cuerpo sin equipo.',
      'muscles': <String>['Abdominales', 'Cuádriceps', 'Glúteo'],
      'groups': <String>['Cuerpo completo'],
    },
    {
      'nombre': 'Fuerza en gimnasio',
      'nivel': 'Intermedio',
      'tipo': 'Fuerza',
      'entorno': 'Gimnasio',
      'descripcion':
      'Entrenamiento con pesas para tren superior e inferior.',
      'muscles': <String>['Pecho (general)', 'Bíceps', 'Tríceps'],
      'groups': <String>['Pecho (general)', 'Brazos'],
    },
    {
      'nombre': 'Hipertrofia pierna',
      'nivel': 'Avanzado',
      'tipo': 'Hipertrofia',
      'entorno': 'Gimnasio',
      'descripcion': 'Sesión intensa enfocada en cuádriceps y glúteos.',
      'muscles': <String>['Cuádriceps', 'Glúteo'],
      'groups': <String>['Piernas (general)'],
    },
    {
      'nombre': 'Cardio en parque',
      'nivel': 'Intermedio',
      'tipo': 'Resistencia',
      'entorno': 'Exterior',
      'descripcion': 'Caminata / trote con cambios de ritmo.',
      'muscles': <String>['Pantorrilla', 'Cuádriceps'],
      'groups': <String>['Piernas (general)'],
    },
  ];

  // Filtra rutinas según nivel/tipo/entorno + músculos/grupos seleccionados
  List<Map<String, dynamic>> get _filteredRoutines {
    return _allRoutines.where((r) {
      final nivelOk = r['nivel'] == _selectedNivel;
      final tipoOk = r['tipo'] == _selectedTipo;
      final entornoOk = r['entorno'] == _selectedEntorno;

      final muscles = List<String>.from(r['muscles'] ?? []);
      final groups = List<String>.from(r['groups'] ?? []);

      final musclesOk = _selectedMuscles.isEmpty ||
          muscles.any((m) => _selectedMuscles.contains(m));
      final groupsOk = _selectedGeneralGroups.isEmpty ||
          groups.any((g) => _selectedGeneralGroups.contains(g));

      return nivelOk && tipoOk && entornoOk && musclesOk && groupsOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // HEADER VERDE
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
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
              children: [
                Text(
                  'Rutina personalizada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Combina nivel, tipo de ejercicio, entorno y músculos\n'
                      'para ver rutinas recomendadas.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // ---------- FILTROS (NIVEL / TIPO / ENTORNO) ----------
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _FilterExpansion(
                  title: 'Nivel',
                  icon: Icons.speed,
                  options: _niveles,
                  selected: _selectedNivel,
                  onSelected: (value) {
                    setState(() => _selectedNivel = value);
                  },
                ),
                SizedBox(height: 8),
                _FilterExpansion(
                  title: 'Tipo de ejercicio',
                  icon: Icons.sports_gymnastics,
                  options: _tipos,
                  selected: _selectedTipo,
                  onSelected: (value) {
                    setState(() => _selectedTipo = value);
                  },
                ),
                SizedBox(height: 8),
                _FilterExpansion(
                  title: 'Entorno',
                  icon: Icons.place,
                  options: _entornos,
                  selected: _selectedEntorno,
                  onSelected: (value) {
                    setState(() => _selectedEntorno = value);
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // ---------- MÚSCULOS ESPECÍFICOS (multi-select) ----------
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  title: Text(
                    'Músculos específicos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: kGreenPrimary.withOpacity(0.12),
                    child: Icon(
                      Icons.fitness_center,
                      color: kGreenPrimary,
                    ),
                  ),
                  childrenPadding:
                  EdgeInsets.only(left: 8, right: 8, bottom: 12),
                  children: _muscles
                      .map(
                        (m) => _MuscleCard(
                      icon: m.icon,
                      label: m.label,
                      selected: _selectedMuscles.contains(m.label),
                      onTap: () {
                        setState(() {
                          if (_selectedMuscles.contains(m.label)) {
                            _selectedMuscles.remove(m.label);
                          } else {
                            _selectedMuscles.add(m.label);
                          }
                        });
                      },
                    ),
                  )
                      .toList(),
                ),
              ),
            ),
          ),

          SizedBox(height: 16),

          // ---------- RUTINAS GENERALES (multi-select) ----------
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  title: Text(
                    'Rutinas generales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: kGreenPrimary.withOpacity(0.12),
                    child: Icon(
                      Icons.accessibility_new,
                      color: kGreenPrimary,
                    ),
                  ),
                  childrenPadding:
                  EdgeInsets.only(left: 8, right: 8, bottom: 12),
                  children: _generalGroups
                      .map(
                        (g) => _MuscleCard(
                      icon: g.icon,
                      label: g.label,
                      selected:
                      _selectedGeneralGroups.contains(g.label),
                      onTap: () {
                        setState(() {
                          if (_selectedGeneralGroups.contains(g.label)) {
                            _selectedGeneralGroups.remove(g.label);
                          } else {
                            _selectedGeneralGroups.add(g.label);
                          }
                        });
                      },
                    ),
                  )
                      .toList(),
                ),
              ),
            ),
          ),

          SizedBox(height: 12),

          // Botón "Ver rutinas" (solo UI, por si luego quieres scroll o acción)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Aquí podrías hacer scroll a la lista de rutinas
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade800,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: Icon(Icons.play_arrow),
                label: Text('Ver rutinas'),
              ),
            ),
          ),

          SizedBox(height: 24),

          // ---------- LISTA DE RUTINAS RECOMENDADAS ----------
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Rutinas recomendadas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _filteredRoutines.isEmpty
                ? Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No hay rutinas que coincidan con los filtros.\n'
                    'Prueba cambiando nivel, tipo, entorno o músculos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )
                : Column(
              children: _filteredRoutines
                  .map(
                    (r) => _RoutineCard(
                  title: r['nombre'] as String? ?? '',
                  subtitle:
                  '${r['nivel']} · ${r['tipo']} · ${r['entorno']}',
                  description:
                  r['descripcion'] as String? ?? '',
                ),
              )
                  .toList(),
            ),
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------- CLASE AUXILIAR PARA NOMBRE + ICONO ----------
class _NamedIcon {
  final String label;
  final IconData icon;
  const _NamedIcon(this.label, this.icon);
}

// ---------- WIDGETS AUXILIARES ----------

class _FilterExpansion extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterExpansion({
    required this.title,
    required this.icon,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: kGreenPrimary.withOpacity(0.12),
            child: Icon(
              icon,
              color: kGreenPrimary,
            ),
          ),
          childrenPadding: EdgeInsets.only(left: 8, right: 8, bottom: 12),
          children: options
              .map(
                (opt) => _SelectableOptionCard(
              label: opt,
              selected: opt == selected,
              onTap: () => onSelected(opt),
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}

// Tarjeta seleccionable para los filtros (tipo radio) con color suave
class _SelectableOptionCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableOptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
    selected ? const Color(0xFFE9F5EF) : Colors.white; // verde clarito
    final borderColor =
    selected ? kGreenPrimary.withOpacity(0.35) : Colors.transparent;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Card(
          elevation: selected ? 1.5 : 1,
          color: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: selected ? kGreenPrimary : Colors.grey,
                ),
                SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? kGreenDark : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Tarjeta para músculos / rutinas generales (multi-select)
class _MuscleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MuscleCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
    selected ? const Color(0xFFE9F5EF) : Colors.white; // verde clarito
    final borderColor =
    selected ? kGreenPrimary.withOpacity(0.35) : Colors.transparent;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Card(
          elevation: selected ? 2 : 1.5,
          color: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: kGreenPrimary.withOpacity(0.10),
                  child: Icon(
                    icon,
                    color: kGreenPrimary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: selected ? kGreenPrimary : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Tarjeta de rutina recomendada
class _RoutineCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;

  const _RoutineCard({
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(Icons.bolt, color: kGreenPrimary),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          // Aquí podrías abrir el detalle de la rutina
        },
      ),
    );
  }
}
