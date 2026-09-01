import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_code_header.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String projectId;

  const EditorScreen({super.key, required this.projectId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  final List<String> _keyboardShortcuts = [
    'Tab',
    '{',
    '}',
    '(',
    ')',
    '[',
    ']',
    ';',
    '=>',
    '"',
    "'",
    '/',
    '\$',
    '=',
    ':',
  ];

  @override
  void initState() {
    super.initState();
    final editorState = ref.read(editorProvider);
    _textController = TextEditingController(text: editorState.content);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _insertText(String text) {
    final toInsert = text == 'Tab' ? '  ' : text;
    final val = _textController.value;
    final start = val.selection.start;
    final end = val.selection.end;

    if (start >= 0 && end >= 0) {
      final newText = val.text.replaceRange(start, end, toInsert);
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + toInsert.length),
      );
      ref.read(editorProvider.notifier).updateContent(newText);
    } else {
      _textController.text += toInsert;
      ref.read(editorProvider.notifier).updateContent(_textController.text);
    }
  }

  void _saveFile() async {
    final activeProject = ref.read(activeProjectProvider);
    if (activeProject != null) {
      await ref.read(editorProvider.notifier).saveFile(activeProject.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File saved successfully.'),
            duration: Duration(seconds: 1),
            backgroundColor: AppColors.emeraldGreen,
          ),
        );
      }
    }
  }

  void _scanAndFeedToAI() {
    final editorState = ref.read(editorProvider);
    final filePath = editorState.filePath ?? 'src/App.tsx';
    final content = _textController.text;

    final prompt = 'Scanned file: `$filePath`\n\n```\n$content\n```\nPlease inspect this file, check for bugs, optimization, or styling improvements, and let\'s continue with chat.';

    context.push('/project/${widget.projectId}/ai', extra: prompt);
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/project/${widget.projectId}/files');
            }
          },
        ),
        title: Text(editorState.filePath ?? 'Editor'),
        actions: [
          IconButton(
            tooltip: 'Scan & Feed File to AI Chat',
            icon: const Icon(Icons.document_scanner_rounded, color: AppColors.electricCyan),
            onPressed: _scanAndFeedToAI,
          ),
          IconButton(
            tooltip: 'Save',
            icon: Icon(
              Icons.save_outlined,
              color: editorState.isModified ? AppColors.electricCyan : AppColors.textSecondaryOf(context),
            ),
            onPressed: editorState.isModified ? _saveFile : null,
          ),
        ],
      ),
      body: Column(
        children: [
          NivoraCodeHeader(
            filePath: editorState.filePath ?? 'Untitled',
            isModified: editorState.isModified,
            onSave: _saveFile,
            onAskAI: _scanAndFeedToAI,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line numbers
                  _LineNumbersWidget(text: _textController.text),
                  const SizedBox(width: 12),
                  // Code input field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: AppTypography.code.copyWith(
                        color: AppColors.text(context),
                      ),
                      cursorColor: AppColors.electricCyan,
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (val) {
                        ref.read(editorProvider.notifier).updateContent(val);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Virtual developer keyboard accessory bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? AppColors.surface(context),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerTheme.color ?? AppColors.border(context),
                ),
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: _keyboardShortcuts.length,
              itemBuilder: (ctx, idx) {
                final keyText = _keyboardShortcuts[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => _insertText(keyText),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated(context),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(context).dividerTheme.color ?? AppColors.border(context),
                        ),
                      ),
                      child: Text(
                        keyText,
                        style: AppTypography.code.copyWith(
                          color: AppColors.text(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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

class _LineNumbersWidget extends StatelessWidget {
  final String text;

  const _LineNumbersWidget({required this.text});

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(text).length + 1;
    final numbers = List.generate(lineCount, (i) => '${i + 1}').join('\n');

    return Text(
      numbers,
      style: AppTypography.code.copyWith(
        color: AppColors.textMuted,
      ),
      textAlign: TextAlign.right,
    );
  }
}
