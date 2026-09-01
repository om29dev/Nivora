import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import 'terminal_screen.dart';

/// Global terminal view destination hosted in the bottom navigation shell.
/// Connects to the active repository context or system sandbox.
class GlobalTerminalScreen extends ConsumerWidget {
  const GlobalTerminalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProject = ref.watch(activeProjectProvider);
    final projects = ref.watch(projectsListProvider);

    // If an active project exists, use its ID; otherwise fallback to first project or global sandbox
    final effectiveId = activeProject?.id ?? (projects.isNotEmpty ? projects.first.id : 'sandbox');

    return TerminalScreen(projectId: effectiveId);
  }
}
