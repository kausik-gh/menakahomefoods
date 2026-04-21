import 'package:flutter/material.dart';
import '../../../widgets/map_placeholder_widget.dart';

/// Map SDK removed — shows a styled placeholder (live tracking message).
class TrackingMapWidget extends StatelessWidget {
  final int currentStep;
  final AnimationController pulseController;
  final bool isTablet;
  final double? riderLat;
  final double? riderLng;
  final double? customerLat;
  final double? customerLng;

  const TrackingMapWidget({
    super.key,
    required this.currentStep,
    required this.pulseController,
    this.isTablet = false,
    this.riderLat,
    this.riderLng,
    this.customerLat,
    this.customerLng,
  });

  @override
  Widget build(BuildContext context) {
    final mapHeight = isTablet ? 320.0 : 260.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MapPlaceholderWidget(height: mapHeight),
    );
  }
}
