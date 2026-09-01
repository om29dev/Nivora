import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/project.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_dialog.dart';
import '../../core/widgets/nivora_empty_state.dart';
import '../../core/widgets/nivora_project_card.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProject(Project project) {
    ref.read(activeProjectProvider.notifier).state = project;
    ref.read(projectIntelligenceProvider.notifier).indexProject(project.path);
    context.push('/project/${project.id}');
  }

  void _confirmDelete(Project project) async {
    final confirmed = await NivoraDialog.showConfirmation(
      context: context,
      title: 'Delete Repository',
      message: 'Are you sure you want to remove ${project.name}? This will delete local repository files.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      ref.read(projectsListProvider.notifier).deleteProject(project.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsListProvider);
    final activeProject = ref.watch(activeProjectProvider);

    final filteredProjects = _searchQuery.isEmpty
        ? projects
        : projects.where((p) {
            final query = _searchQuery.toLowerCase();
            return p.name.toLowerCase().contains(query) ||
                p.language.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('Repositories'),
        actions: [
          IconButton(
            tooltip: 'Clone Repository',
            icon: const Icon(Icons.add_rounded, color: AppColors.electricCyan),
            onPressed: () => context.push('/clone'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: AppTypography.bodyOf(context),
              decoration: InputDecoration(
                hintText: 'Search repositories...',
                hintStyle: TextStyle(color: AppColors.textMutedOf(context), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.electricCyan, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
            ),
          ),

          // Repository List
          Expanded(
            child: filteredProjects.isEmpty
                ? NivoraEmptyState(
                    icon: Icons.folder_open_rounded,
                    title: _searchQuery.isEmpty ? 'No Local Repositories' : 'No Matches Found',
                    message: _searchQuery.isEmpty
                        ? 'Clone a repository from GitHub to inspect, vibe-code, and run locally.'
                        : 'No repositories match "$_searchQuery".',
                    actionText: _searchQuery.isEmpty ? 'Clone Repository' : null,
                    onAction: _searchQuery.isEmpty ? () => context.push('/clone') : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project = filteredProjects[index];
                      final isActive = activeProject?.id == project.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Stack(
                          children: [
                            NivoraProjectCard(
                              project: project,
                              onTap: () => _openProject(project),
                              onDelete: () => _confirmDelete(project),
                            ),
                            if (isActive)
                              Positioned(
                                top: 8,
                                right: 38,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.electricCyan.withAlpha(30),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.electricCyan, width: 1),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: AppTypography.captionOf(context).copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.electricCyan,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
