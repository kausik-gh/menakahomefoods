import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Replaces map SDK widgets — live tracking UI placeholder.
class MapPlaceholderWidget extends StatelessWidget {
  final double height;

  const MapPlaceholderWidget({super.key, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A7C59)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 48,
              color: Color(0xFF4A7C59),
            ),
            const SizedBox(height: 8),
            Text(
              'Live tracking coming soon',
              style: GoogleFonts.poppins(
                color: const Color(0xFF4A7C59),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
