import 'package:flutter/material.dart';

class WaterButton extends StatelessWidget {
  final VoidCallback onPressed;
  const WaterButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.water_drop),
        label: const Text("Arroser la plante (+10 XP)"),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 5,
        ),
      ),
    );
  }
}
