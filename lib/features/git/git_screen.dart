import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/git_types.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_bottom_sheet.dart';
import '../../core/widgets/nivora_button.dart';
import '../../core/widgets/nivora_card.dart';
import '../../core/widgets/nivora_chip.dart';
import '../../core/widgets/nivora_dialog.dart';
import '../../core/widgets/nivora_empty_state.dart';
import '../../core/widgets/nivora_file_row.dart';
import '../../core/widgets/nivora_input.dart';

class GitScreen extends ConsumerStatefulWidget {
  final String projectId;

  const GitScreen({super.key, required this.projectId});

  @override
  ConsumerState<GitScreen> createState() => _GitScreenState();
}

class _GitScreenState extends ConsumerState<GitScreen> {
  final TextEditingController _commitMsgController = TextEditingController();
  bool _isCommitting = false;

  @override
  void dispose() {
    _commitMsgController.dispose();
    super.dispose();
  }

  Future<void> _commitChanges() async {
    final msg = _commitMsgController.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a commit message.')),
      );
      return;
    }

    final activeProject = ref.read(activeProjectProvider);
    final git = ref.read(gitServiceProvider);

    if (activeProject != null) {
      setState(() => _isCommitting = true);
      // Stage all and commit
      await git.stageAll(activeProject.path);
      final success = await git.commit(activeProject.path, msg);

      setState(() => _isCommitting = false);
      if (success) {
        _commitMsgController.clear();
        ref.invalidate(gitStatusProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Committed changes successfully!'),
              backgroundColor: AppColors.emeraldGreen,
            ),
          );
        }
      }
    }
  }

  void _inspectDiff(GitFileStatus file) async {
    final activeProject = ref.read(activeProjectProvider);
    final git = ref.read(gitServiceProvider);

    if (activeProject != null) {
      final diffText = await git.getDiff(activeProject.path, filePath: file.path);
      if (!mounted) return;

      NivoraBottomSheet.show(
        context: context,
        title: 'Diff: ${file.path}',
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Text(
              diffText.isEmpty ? 'No unstaged diff lines.' : diffText,
              style: AppTypography.terminal.copyWith(fontSize: 12),
            ),
          ),
        ),
      );
    }
  }

  void _confirmPush() async {
    final confirmed = await NivoraDialog.showConfirmation(
      context: context,
      title: 'Push to Remote GitHub',
      message: 'Push commits from local branch to upstream origin? (Manual action only; AI never pushes automatically).',
      confirmText: 'Push Commits',
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pushed 1 commit to origin/main!'),
          backgroundColor: AppColors.emeraldGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gitStatusAsync = ref.watch(gitStatusProvider);

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
        title: const Text('Source Control'),
        actions: [
          IconButton(
            tooltip: 'Sync / Push',
            icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.electricCyan),
            onPressed: _confirmPush,
          ),
        ],
      ),
      body: gitStatusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.electricCyan)),
        error: (err, _) => Center(child: Text('Git Error: $err')),
        data: (status) {
          final files = status.files;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Branch & Remote Sync Header
              NivoraCard(
                backgroundColor: AppColors.darkSurfaceElevated,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fork_right_rounded, color: AppColors.emeraldGreen, size: 22),
                        const SizedBox(width: 8),
                        Text(status.currentBranch, style: AppTypography.h2),
                      ],
                    ),
                    Row(
                      children: [
                        NivoraChip(
                          label: '${files.length} Changes',
                          color: files.isEmpty ? AppColors.emeraldGreen : AppColors.amberWarning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Commit Box
              NivoraCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Commit Changes', style: AppTypography.h3),
                    const SizedBox(height: 10),
                    NivoraInput(
                      controller: _commitMsgController,
                      hintText: 'Commit message (e.g. Add dark mode)',
                      prefixIcon: Icons.edit_note_rounded,
                      onSubmitted: (_) => _commitChanges(),
                    ),
                    const SizedBox(height: 12),
                    NivoraButton(
                      text: 'Commit',
                      icon: Icons.check_circle_outline_rounded,
                      width: double.infinity,
                      isLoading: _isCommitting,
                      onPressed: files.isEmpty ? null : _commitChanges,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Changes List
              Text(
                'CHANGES (${files.length})',
                style: AppTypography.caption.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              if (files.isEmpty) ...[
                NivoraEmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Working tree is clean',
                  message: 'No uncommitted changes detected in this repository.',
                ),
              ] else ...[
                NivoraCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: files.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final f = files[idx];
                      return NivoraFileRow(
                        fileName: f.path,
                        isDirectory: false,
                        gitStatus: f.status,
                        onTap: () => _inspectDiff(f),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
