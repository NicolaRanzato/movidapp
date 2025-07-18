import 'package:flutter/material.dart';

class PulsatingDotMarker extends StatefulWidget {
  final Color color;
  final double size;

  const PulsatingDotMarker({
    super.key,
    this.color = Colors.blue,
    this.size = 20.0,
  });

  @override
  _PulsatingDotMarkerState createState() => _PulsatingDotMarkerState();
}

class _PulsatingDotMarkerState extends State<PulsatingDotMarker> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      width: widget.size,
      height: widget.size,
    );
  }
}
