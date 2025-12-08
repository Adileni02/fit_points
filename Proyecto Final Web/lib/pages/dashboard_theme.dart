import 'package:flutter/material.dart';

const kPrimaryGreen = Color(0xFF2DD14F);
const kGreenStart = Color(0xFF00B340);
const kGreenEnd = Color(0xFF2DD14F);
const kLightBg = Color(0xFFF5F5FB);

class TypeChip extends StatelessWidget {
  final String type;
  const TypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final normalized = type.toLowerCase();
    final color = (normalized == 'park' || normalized == 'parque')
        ? kPrimaryGreen
        : const Color(0xFF4FC3F7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color.darken(),
        ),
      ),
    );
  }
}

class ActiveBadge extends StatelessWidget {
  final bool active;
  const ActiveBadge({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? kPrimaryGreen : Colors.redAccent;
    final text = active ? 'Sí' : 'No';

    return Row(
      children: [
        Icon(
          active ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

extension ColorUtils on Color {
  Color darken([double amount = 0.15]) {
    final hsl = HSLColor.fromColor(this);
    final adjusted =
    hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return adjusted.toColor();
  }
}
