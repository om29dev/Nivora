import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/git_types.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_file_row.dart';
import '../../core/widgets/nivora_input.dart';

class FileExplorerScreen extends ConsumerStatefulWidget {
  final String projectId;

  const FileExplorerScreen({super.key, required this.projectId});

  @override
  ConsumerState<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends ConsumerState<FileExplorerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeProject = ref.watch(activeProjectProvider);
    final intelState = ref.watch(projectIntelligenceProvider);
    final gitStatusAsync = ref.watch(gitStatusProvider);

    final gitFilesMap = <String, GitFileStatusType>{};
    gitStatusAsync.whenData((status) {
      for (final f in status.files) {
        gitFilesMap[f.path] = f.status;
      }
    });

    final filteredFiles = intelState.scannedFiles.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.relativePath.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Project',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/project/${widget.projectId}');
            }
          },
        ),
        title: const Text('Files'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: NivoraInput(
              controller: _searchController,
              hintText: 'Search files in repository...',
              prefixIcon: Icons.search_rounded,
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: intelState.isIndexing
                ? const Center(child: CircularProgressIndicator(color: AppColors.electricCyan))
                : filteredFiles.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'No files scanned' : 'No matching files found',
                          style: AppTypography.bodySecondary,
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredFiles.length,
                        itemBuilder: (ctx, idx) {
                          final file = filteredFiles[idx];
                          final gitStatus = gitFilesMap[file.relativePath] ?? GitFileStatusType.clean;

                          return NivoraFileRow(
                            fileName: file.relativePath,
                            isDirectory: file.isDirectory,
                            gitStatus: gitStatus,
                            onTap: () async {
                              if (!file.isDirectory && activeProject != null) {
                                await ref
                                    .read(editorProvider.notifier)
                                    .openFile(activeProject.path, file.relativePath);
                                if (context.mounted) {
                                  context.push('/project/${widget.projectId}/editor');
                                }
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
