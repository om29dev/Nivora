import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../models/blast_radius_data.dart';

class _Node3D {
  final DependencyNode node;
  final double x;
  final double y;
  final double z;
  final bool isTarget;

  _Node3D({
    required this.node,
    required this.x,
    required this.y,
    required this.z,
    this.isTarget = false,
  });
}

class _ProjectedNode {
  final DependencyNode node;
  final Offset screenPos;
  final double depth; // z after rotation
  final double scale;
  final double radius;
  final bool isTarget;

  _ProjectedNode({
    required this.node,
    required this.screenPos,
    required this.depth,
    required this.scale,
    required this.radius,
    required this.isTarget,
  });
}

/// Interactive 3D Spatial Spherical Graph Canvas for Blast Radius Intelligence
class BlastRadiusCanvas extends StatefulWidget {
  final BlastRadiusData data;
  final ValueChanged<DependencyNode>? onNodeSelected;

  const BlastRadiusCanvas({
    super.key,
    required this.data,
    this.onNodeSelected,
  });

  @override
  State<BlastRadiusCanvas> createState() => _BlastRadiusCanvasState();
}

class _BlastRadiusCanvasState extends State<BlastRadiusCanvas>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // 3D Camera Angles
  double _rotX = 0.25; // Pitch
  double _rotY = 0.0;  // Yaw
  double _zoom = 1.0;
  bool _autoOrbit = true;

  DependencyNode? _selectedNode;
  final Map<String, Offset> _latestScreenPositions = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_pulseController);

    // Auto-orbit ticker loop
    _pulseController.addListener(() {
      if (_autoOrbit && mounted) {
        setState(() {
          _rotY += 0.007;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _autoOrbit = false;
      _rotY += details.delta.dx * 0.012;
      _rotX = (_rotX - details.delta.dy * 0.012).clamp(-1.2, 1.2);
    });
  }

  void _onTapUp(TapUpDetails details, Size canvasSize) {
    final tapPos = details.localPosition;
    DependencyNode? closestNode;
    double closestDist = 45.0; // hit test radius

    for (final entry in _latestScreenPositions.entries) {
      final dist = (entry.value - tapPos).distance;
      if (dist < closestDist) {
        closestDist = dist;
        if (entry.key == widget.data.target.id) {
          closestNode = widget.data.target;
        } else {
          final found = widget.data.nodes.where((n) => n.id == entry.key);
          if (found.isNotEmpty) closestNode = found.first;
        }
      }
    }

    if (closestNode != null) {
      setState(() {
        _selectedNode = closestNode;
      });
      if (widget.onNodeSelected != null) {
        widget.onNodeSelected!(closestNode);
      }
      _showNodeDetailsModal(closestNode);
    }
  }

  void _showNodeDetailsModal(DependencyNode node) {
    final isTarget = node.id == widget.data.target.id;
    final affectedNodes = widget.data.edges
        .where((e) => e.fromId == node.id || e.toId == node.id)
        .length;
    final riskPercent = (node.riskScore * 100).toInt();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _colorForRisk(node.riskScore),
                        boxShadow: [
                          BoxShadow(
                            color: _colorForRisk(node.riskScore).withAlpha(100),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        node.label,
                        style: AppTypography.h2.copyWith(color: Colors.white, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isTarget
                            ? AppColors.violetAccent.withAlpha(40)
                            : AppColors.electricCyan.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isTarget ? AppColors.violetAccent : AppColors.electricCyan,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isTarget ? 'ROOT TARGET' : (node.degree == DependencyDegree.firstDegree ? '1ST DEGREE' : '2ND DEGREE'),
                        style: TextStyle(
                          color: isTarget ? AppColors.violetAccent : AppColors.electricCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricCol('Blast Radius Impact', '$affectedNodes Connected Nodes', AppColors.electricCyan),
                      Container(width: 1, height: 36, color: Colors.white.withAlpha(30)),
                      _buildMetricCol('Coupling Risk', '$riskPercent%', _colorForRisk(node.riskScore)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isTarget
                      ? 'This is the primary file under modification. Any refactoring here directly propagates changes across $affectedNodes linked modules.'
                      : 'Changes to ${widget.data.target.label} cascade into this module with a risk score of $riskPercent%. Direct callers and AST symbols will require regression validation.',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.hub_rounded, size: 16),
                        label: const Text('Focus in 3D Space'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCol(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _colorForRisk(double risk) {
    if (risk > 0.7) return const Color(0xFFEF4444);
    if (risk > 0.4) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanUpdate: _onPanUpdate,
          onTapUp: (details) => _onTapUp(details, size),
          child: Stack(
            children: [
              // 3D Spatial Canvas
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, _) {
                  return CustomPaint(
                    size: size,
                    painter: _BlastRadius3DPainter(
                      data: widget.data,
                      rotX: _rotX,
                      rotY: _rotY,
                      zoom: _zoom,
                      pulseValue: _pulseAnim.value,
                      selectedNodeId: _selectedNode?.id,
                      onPositionsComputed: (posMap) {
                        _latestScreenPositions.clear();
                        _latestScreenPositions.addAll(posMap);
                      },
                    ),
                  );
                },
              ),

              // Floating 3D Navigation Controls
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withAlpha(200),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.electricCyan.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _autoOrbit ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                          color: AppColors.electricCyan,
                          size: 18,
                        ),
                        tooltip: _autoOrbit ? 'Pause Orbit' : 'Auto-Orbit 3D',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _autoOrbit = !_autoOrbit),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 18),
                        tooltip: 'Zoom In',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _zoom = (_zoom + 0.15).clamp(0.6, 2.2)),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.zoom_out_rounded, color: Colors.white70, size: 18),
                        tooltip: 'Zoom Out',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _zoom = (_zoom - 0.15).clamp(0.6, 2.2)),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                        tooltip: 'Reset Camera',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() {
                          _rotX = 0.25;
                          _rotY = 0.0;
                          _zoom = 1.0;
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // Tap hint pill
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '👆 Tap any 3D node to inspect blast radius & coupling',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ============================================================
///  3D CUSTOM PAINTER (Perspective Projection + Depth Sorting)
/// ============================================================
class _BlastRadius3DPainter extends CustomPainter {
  final BlastRadiusData data;
  final double rotX;
  final double rotY;
  final double zoom;
  final double pulseValue;
  final String? selectedNodeId;
  final ValueChanged<Map<String, Offset>> onPositionsComputed;

  _BlastRadius3DPainter({
    required this.data,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    required this.pulseValue,
    this.selectedNodeId,
    required this.onPositionsComputed,
  });

  static const Color _deepSpaceBg = Color(0xFF0A0A0F);
  static const Color _neonBlue = Color(0xFF00D4FF);
  static const Color _electricPurple = Color(0xFFBF5AF2);
  static const Color _ring1Color = Color(0xFF0EA5E9);
  static const Color _ring2Color = Color(0xFF64748B);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = min(size.width, size.height) * 0.42 * zoom;

    // Background fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _deepSpaceBg,
    );

    // Draw 3D Gimbal Orbit Rings
    _draw3DOrbitRing(canvas, center, baseRadius * 0.50, rotX, rotY, _ring1Color.withAlpha(30));
    _draw3DOrbitRing(canvas, center, baseRadius * 0.90, rotX, rotY, _ring2Color.withAlpha(20));

    // Build 3D spatial coordinates on multi-altitude spherical shell
    final raw3DNodes = <_Node3D>[];
    raw3DNodes.add(_Node3D(node: data.target, x: 0, y: 0, z: 0, isTarget: true));

    final firstDegree = data.nodes.where((n) => n.degree == DependencyDegree.firstDegree).toList();
    final secondDegree = data.nodes.where((n) => n.degree == DependencyDegree.secondDegree).toList();

    final r1 = baseRadius * 0.50;
    for (int i = 0; i < firstDegree.length; i++) {
      final theta = (2 * pi * i) / max(1, firstDegree.length);
      final phi = (i % 2 == 0 ? 0.35 : -0.35); // 3D elevation
      raw3DNodes.add(_Node3D(
        node: firstDegree[i],
        x: r1 * cos(theta) * cos(phi),
        y: r1 * sin(phi),
        z: r1 * sin(theta) * cos(phi),
      ));
    }

    final r2 = baseRadius * 0.90;
    for (int i = 0; i < secondDegree.length; i++) {
      final theta = (2 * pi * i) / max(1, secondDegree.length) + (pi / max(1, secondDegree.length));
      final phi = (i % 3 == 0 ? 0.55 : (i % 3 == 1 ? -0.55 : 0.0)); // Varied 3D pitch
      raw3DNodes.add(_Node3D(
        node: secondDegree[i],
        x: r2 * cos(theta) * cos(phi),
        y: r2 * sin(phi),
        z: r2 * sin(theta) * cos(phi),
      ));
    }

    // Perspective Projection Calculation
    const cameraDistance = 800.0;
    final projectedMap = <String, _ProjectedNode>{};
    final screenPosMap = <String, Offset>{};

    for (final node3D in raw3DNodes) {
      // Rotate around Y (Yaw)
      final x1 = node3D.x * cos(rotY) + node3D.z * sin(rotY);
      final z1 = -node3D.x * sin(rotY) + node3D.z * cos(rotY);

      // Rotate around X (Pitch)
      final y2 = node3D.y * cos(rotX) - z1 * sin(rotX);
      final z2 = node3D.y * sin(rotX) + z1 * cos(rotX);

      // Perspective scale factor
      final perspective = cameraDistance / (cameraDistance + z2);
      final screenX = center.dx + x1 * perspective;
      final screenY = center.dy + y2 * perspective;
      final screenPos = Offset(screenX, screenY);

      final baseNodeRadius = node3D.isTarget ? 18.0 : (node3D.node.degree == DependencyDegree.firstDegree ? 13.0 : 10.0);
      final scaledRadius = (baseNodeRadius * perspective).clamp(5.0, 36.0);

      projectedMap[node3D.node.id] = _ProjectedNode(
        node: node3D.node,
        screenPos: screenPos,
        depth: z2,
        scale: perspective,
        radius: scaledRadius,
        isTarget: node3D.isTarget,
      );

      screenPosMap[node3D.node.id] = screenPos;
    }

    onPositionsComputed(screenPosMap);

    // Draw 3D Synaptic Edges
    for (int i = 0; i < data.edges.length; i++) {
      final edge = data.edges[i];
      final fromP = projectedMap[edge.fromId];
      final toP = projectedMap[edge.toId];
      if (fromP != null && toP != null) {
        final avgDepth = (fromP.depth + toP.depth) / 2;
        final depthAlpha = ((cameraDistance - avgDepth) / (cameraDistance * 1.5)).clamp(0.2, 1.0);

        final edgePaint = Paint()
          ..color = _neonBlue.withAlpha((40 * depthAlpha).toInt() + (edge.weight * 10).toInt())
          ..strokeWidth = (0.8 + edge.weight * 0.4) * fromP.scale
          ..style = PaintingStyle.stroke;

        canvas.drawLine(fromP.screenPos, toP.screenPos, edgePaint);

        // Moving 3D energy pulse packet
        final t = (pulseValue + (i * 0.18)) % 1.0;
        final pulsePos = Offset.lerp(fromP.screenPos, toP.screenPos, t)!;
        canvas.drawCircle(
          pulsePos,
          2.5 * fromP.scale,
          Paint()..color = _neonBlue.withAlpha((200 * depthAlpha).toInt()),
        );
      }
    }

    // Sort nodes by Depth (Z-Buffer Painter's Algorithm: distant nodes first)
    final sortedProjected = projectedMap.values.toList()
      ..sort((a, b) => b.depth.compareTo(a.depth));

    // Draw Nodes in 3D Order
    for (final pNode in sortedProjected) {
      final depthAlpha = ((cameraDistance - pNode.depth) / (cameraDistance * 1.5)).clamp(0.3, 1.0);
      final isSelected = pNode.node.id == selectedNodeId;

      if (pNode.isTarget) {
        // Target Node with 3D Core Aura
        final glowRadius = (pNode.radius + 12) * (1.0 + (pulseValue * 0.2));
        canvas.drawCircle(
          pNode.screenPos,
          glowRadius,
          Paint()
            ..color = _electricPurple.withAlpha((70 * depthAlpha).toInt())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
        );

        canvas.drawCircle(
          pNode.screenPos,
          pNode.radius,
          Paint()
            ..shader = ui.Gradient.radial(
              Offset(pNode.screenPos.dx - pNode.radius * 0.3, pNode.screenPos.dy - pNode.radius * 0.3),
              pNode.radius * 1.4,
              [const Color(0xFFE879F9), _electricPurple],
            ),
        );

        canvas.drawCircle(
          pNode.screenPos,
          pNode.radius,
          Paint()
            ..color = Colors.white.withAlpha((220 * depthAlpha).toInt())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 * pNode.scale,
        );
      } else {
        // Satellite 3D Node
        final isFirst = pNode.node.degree == DependencyDegree.firstDegree;
        final nodeColor = isFirst ? _ring1Color : _ring2Color;
        final riskColor = _colorForRisk(pNode.node.riskScore);

        // Selection ring
        if (isSelected) {
          canvas.drawCircle(
            pNode.screenPos,
            pNode.radius + 6,
            Paint()
              ..color = AppColors.electricCyan.withAlpha(200)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0,
          );
        }

        // 3D Spherical Sphere lighting
        canvas.drawCircle(
          pNode.screenPos,
          pNode.radius,
          Paint()
            ..shader = ui.Gradient.radial(
              Offset(pNode.screenPos.dx - pNode.radius * 0.35, pNode.screenPos.dy - pNode.radius * 0.35),
              pNode.radius * 1.3,
              [
                nodeColor.withAlpha((255 * depthAlpha).toInt()),
                const Color(0xFF0F172A),
              ],
            ),
        );

        canvas.drawCircle(
          pNode.screenPos,
          pNode.radius,
          Paint()
            ..color = nodeColor.withAlpha((180 * depthAlpha).toInt())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2 * pNode.scale,
        );

        // Risk rating dot
        canvas.drawCircle(
          Offset(pNode.screenPos.dx + pNode.radius * 0.55, pNode.screenPos.dy - pNode.radius * 0.55),
          3.5 * pNode.scale,
          Paint()..color = riskColor.withAlpha((240 * depthAlpha).toInt()),
        );
      }

      // Draw Depth-Scaled Text Pill
      _draw3DLabel(canvas, pNode, depthAlpha, isSelected);
    }
  }

  void _draw3DOrbitRing(Canvas canvas, Offset center, double radius, double rX, double rY, Color color) {
    final path = Path();
    const segments = 48;
    for (int i = 0; i <= segments; i++) {
      final theta = (2 * pi * i) / segments;
      final x = radius * cos(theta);
      final z = radius * sin(theta);

      // Rotate Y then X
      final x1 = x * cos(rY) + z * sin(rY);
      final z1 = -x * sin(rY) + z * cos(rY);
      final y2 = -z1 * sin(rX);
      final z2 = z1 * cos(rX);

      const camDist = 800.0;
      final p = camDist / (camDist + z2);
      final pt = Offset(center.dx + x1 * p, center.dy + y2 * p);

      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _draw3DLabel(Canvas canvas, _ProjectedNode pNode, double depthAlpha, bool isSelected) {
    final isTarget = pNode.isTarget;
    final fontSize = ((isTarget ? 11.0 : 9.0) * pNode.scale).clamp(7.0, 13.0);
    final color = isTarget
        ? Colors.white
        : Colors.white.withAlpha((200 * depthAlpha).toInt().clamp(80, 255));

    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    ))
      ..pushStyle(ui.TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: 'Inter',
        fontWeight: isTarget || isSelected ? FontWeight.w700 : FontWeight.w500,
      ))
      ..addText(pNode.node.label);

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: 120 * pNode.scale));

    final labelOffset = Offset(
      pNode.screenPos.dx - paragraph.width / 2,
      pNode.screenPos.dy + pNode.radius + 4,
    );

    // Pill background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        labelOffset.dx - 4,
        labelOffset.dy - 1,
        paragraph.width + 8,
        paragraph.height + 2,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(
      bgRect,
      Paint()..color = const Color(0xFF0A0F1D).withAlpha((180 * depthAlpha).toInt()),
    );

    if (isSelected || isTarget) {
      canvas.drawRRect(
        bgRect,
        Paint()
          ..color = (isTarget ? _electricPurple : AppColors.electricCyan).withAlpha((160 * depthAlpha).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    canvas.drawParagraph(paragraph, labelOffset);
  }

  Color _colorForRisk(double risk) {
    if (risk > 0.7) return const Color(0xFFEF4444);
    if (risk > 0.4) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  bool shouldRepaint(covariant _BlastRadius3DPainter old) {
    return old.rotX != rotX ||
        old.rotY != rotY ||
        old.zoom != zoom ||
        old.pulseValue != pulseValue ||
        old.selectedNodeId != selectedNodeId ||
        old.data != data;
  }
}
