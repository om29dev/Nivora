import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/blast_radius_data.dart';

/// High-performance CustomPainter for the blast radius concentric ring
/// visualization. Uses only Canvas primitives — no 3D packages.
///
/// Layout:
///   • Center: target file node (electric purple glow)
///   • Ring 1: 1st-degree dependencies
///   • Ring 2: 2nd-degree dependencies
///   • Connections: thin neon blue lines with subtle opacity
class BlastRadiusCanvas extends StatefulWidget {
  final BlastRadiusData data;

  const BlastRadiusCanvas({super.key, required this.data});

  @override
  State<BlastRadiusCanvas> createState() => _BlastRadiusCanvasState();
}

class _BlastRadiusCanvasState extends State<BlastRadiusCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.4,
      maxScale: 4.0,
      boundaryMargin: const EdgeInsets.all(200),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, _) {
          return CustomPaint(
            size: const Size(600, 600),
            painter: _BlastRadiusPainter(
              data: widget.data,
              pulseValue: _pulseAnim.value,
            ),
          );
        },
      ),
    );
  }
}

/// ============================================================
///  CUSTOM PAINTER — all rendering happens here for 60fps perf
/// ============================================================
class _BlastRadiusPainter extends CustomPainter {
  final BlastRadiusData data;
  final double pulseValue;

  _BlastRadiusPainter({required this.data, required this.pulseValue});

  // --- Semantic Intel Colors ---
  static const Color _deepSpaceBg = Color(0xFF0A0A0F);
  static const Color _neonBlue = Color(0xFF00D4FF);
  static const Color _electricPurple = Color(0xFFBF5AF2);
  static const Color _ring1Color = Color(0xFF0EA5E9);
  static const Color _ring2Color = Color(0xFF64748B);
  static const Color _riskHigh = Color(0xFFEF4444);
  static const Color _riskMedium = Color(0xFFF59E0B);
  static const Color _riskLow = Color(0xFF10B981);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2 - 20;
    final ring1Radius = maxRadius * 0.45;
    final ring2Radius = maxRadius * 0.82;

    // Background fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _deepSpaceBg,
    );

    // Draw concentric ring guides
    _drawRingGuide(canvas, center, ring1Radius);
    _drawRingGuide(canvas, center, ring2Radius);

    // Separate nodes by degree
    final firstDegree = data.nodes
        .where((n) => n.degree == DependencyDegree.firstDegree)
        .toList();
    final secondDegree = data.nodes
        .where((n) => n.degree == DependencyDegree.secondDegree)
        .toList();

    // Compute positions
    final positions = <String, Offset>{};
    positions[data.target.id] = center;

    for (var i = 0; i < firstDegree.length; i++) {
      final angle = (2 * pi * i / firstDegree.length) - pi / 2;
      positions[firstDegree[i].id] = Offset(
        center.dx + ring1Radius * cos(angle),
        center.dy + ring1Radius * sin(angle),
      );
    }

    for (var i = 0; i < secondDegree.length; i++) {
      final angle =
          (2 * pi * i / secondDegree.length) - pi / 2 + pi / secondDegree.length;
      positions[secondDegree[i].id] = Offset(
        center.dx + ring2Radius * cos(angle),
        center.dy + ring2Radius * sin(angle),
      );
    }

    // Draw edges first (behind nodes)
    for (final edge in data.edges) {
      final from = positions[edge.fromId];
      final to = positions[edge.toId];
      if (from != null && to != null) {
        _drawEdge(canvas, from, to, edge.weight);
      }
    }

    // Draw second-degree nodes (behind first-degree)
    for (final node in secondDegree) {
      final pos = positions[node.id];
      if (pos != null) _drawNode(canvas, pos, node, 10);
    }

    // Draw first-degree nodes
    for (final node in firstDegree) {
      final pos = positions[node.id];
      if (pos != null) _drawNode(canvas, pos, node, 14);
    }

    // Draw center target node with glow
    _drawTargetNode(canvas, center, data.target);

    // Draw labels
    for (final node in data.nodes) {
      final pos = positions[node.id];
      if (pos != null) {
        _drawLabel(canvas, pos, node);
      }
    }
  }

  void _drawRingGuide(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = _neonBlue.withAlpha(18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, paint);

    // Subtle dashed concentric fill
    final fillPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          _neonBlue.withAlpha(4),
          _neonBlue.withAlpha(0),
        ],
      );
    canvas.drawCircle(center, radius, fillPaint);
  }

  void _drawEdge(Canvas canvas, Offset from, Offset to, double weight) {
    final paint = Paint()
      ..color = _neonBlue.withAlpha((35 + weight * 15).toInt().clamp(0, 255))
      ..strokeWidth = 0.8 + weight * 0.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(from, to, paint);

    // Subtle glow line
    final glowPaint = Paint()
      ..color = _neonBlue.withAlpha(8)
      ..strokeWidth = 3.0 + weight
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(from, to, glowPaint);
  }

  void _drawNode(Canvas canvas, Offset pos, DependencyNode node, double radius) {
    final riskColor = _colorForRisk(node.riskScore);
    final isFirst = node.degree == DependencyDegree.firstDegree;

    // Outer glow
    canvas.drawCircle(
      pos,
      radius + 6,
      Paint()
        ..color = (isFirst ? _ring1Color : _ring2Color).withAlpha(20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Node body
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = _deepSpaceBg
        ..style = PaintingStyle.fill,
    );

    // Border ring
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = isFirst ? _ring1Color.withAlpha(180) : _ring2Color.withAlpha(120)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Risk indicator dot
    canvas.drawCircle(
      Offset(pos.dx + radius * 0.55, pos.dy - radius * 0.55),
      3.5,
      Paint()..color = riskColor,
    );
  }

  void _drawTargetNode(Canvas canvas, Offset center, DependencyNode target) {
    // Outer pulsing glow
    final glowRadius = 26.0 + pulseValue * 8;
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..color = _electricPurple.withAlpha((pulseValue * 50).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Secondary glow ring
    canvas.drawCircle(
      center,
      22,
      Paint()
        ..color = _electricPurple.withAlpha(40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Core circle
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          18,
          [
            _electricPurple,
            _electricPurple.withAlpha(180),
          ],
        ),
    );

    // Inner highlight
    canvas.drawCircle(
      Offset(center.dx - 4, center.dy - 4),
      6,
      Paint()..color = Colors.white.withAlpha(40),
    );
  }

  void _drawLabel(Canvas canvas, Offset pos, DependencyNode node) {
    final isTarget = node.degree == DependencyDegree.target;
    final fontSize = isTarget ? 11.0 : 9.0;
    final color =
        isTarget ? Colors.white : Colors.white.withAlpha(180);

    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    ))
      ..pushStyle(ui.TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: 'Inter',
        fontWeight: isTarget ? FontWeight.w700 : FontWeight.w400,
        letterSpacing: isTarget ? 0.3 : 0,
      ))
      ..addText(node.label);

    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 120));

    final labelOffset = Offset(
      pos.dx - paragraph.width / 2,
      pos.dy + (isTarget ? 26 : 18),
    );

    // Label background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        labelOffset.dx - 4,
        labelOffset.dy - 1,
        paragraph.width + 8,
        paragraph.height + 2,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = _deepSpaceBg.withAlpha(200),
    );

    canvas.drawParagraph(paragraph, labelOffset);
  }

  Color _colorForRisk(double risk) {
    if (risk > 0.7) return _riskHigh;
    if (risk > 0.4) return _riskMedium;
    return _riskLow;
  }

  @override
  bool shouldRepaint(covariant _BlastRadiusPainter oldDelegate) {
    // Only repaint on pulse change (for the glow animation)
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.data != data;
  }
}
