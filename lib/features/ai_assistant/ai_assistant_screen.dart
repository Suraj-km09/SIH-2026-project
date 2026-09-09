import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ai_assistant_model.dart';
import '../../state/ai_assistant_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/feedback/loading_indicator.dart';

/// Professional Conversational RAG AI Assistant Screen for MineIntel AI.
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showHistorySidebar = true;

  final List<String> _suggestedPrompts = [
    'What was the raw coal production for Rajmahal OCP in August 2026?',
    'Are underground shaft ventilation levels within statutory DGMS limits?',
    'Show methane gas concentration telemetry averages',
    'Summarize overburden removal variance at Eastern Coalfields',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiAssistantNotifierProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    final notifier = ref.read(aiAssistantNotifierProvider.notifier);
    final success = await notifier.sendMessage(text);
    if (success) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: Row(
        children: [
          // Collapsible Conversation History Sidebar (Desktop)
          if (isDesktop && _showHistorySidebar)
            SizedBox(
              width: 280,
              child: _HistorySidebar(
                history: state.history,
                activeId: state.activeConversationId,
                isLoading: state.isHistoryLoading,
                onSelect: (id) => ref.read(aiAssistantNotifierProvider.notifier).selectConversation(id),
                onNewChat: () => ref.read(aiAssistantNotifierProvider.notifier).startNewConversation(),
                onDelete: (id) => ref.read(aiAssistantNotifierProvider.notifier).deleteConversation(id),
              ),
            ),

          // Main Chat Feed Area
          Expanded(
            child: Column(
              children: [
                // Chat Header Bar
                _buildChatHeader(context, state, isDesktop),

                // Error Banner
                if (state.errorMessage != null)
                  Container(
                    width: double.infinity,
                    color: AppColors.error.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Message Stream / Empty Prompt suggestions
                Expanded(
                  child: state.messages.isEmpty
                      ? _buildEmptyState(context)
                      : _buildMessageList(state),
                ),

                // Query Loading Progress Indicator
                if (state.isQueryLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Synthesizing authoritative mining evidence and calculating metrics...',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Chat Input Field
                _buildInputArea(state),
              ],
            ),
          ),
        ],
      ),
      // Drawer for mobile history access
      drawer: !isDesktop
          ? Drawer(
              child: _HistorySidebar(
                history: state.history,
                activeId: state.activeConversationId,
                isLoading: state.isHistoryLoading,
                onSelect: (id) {
                  Navigator.of(context).pop();
                  ref.read(aiAssistantNotifierProvider.notifier).selectConversation(id);
                },
                onNewChat: () {
                  Navigator.of(context).pop();
                  ref.read(aiAssistantNotifierProvider.notifier).startNewConversation();
                },
                onDelete: (id) => ref.read(aiAssistantNotifierProvider.notifier).deleteConversation(id),
              ),
            )
          : null,
    );
  }

  void _openHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final state = sheetRef.watch(aiAssistantNotifierProvider);

            return Container(
              height: MediaQuery.sizeOf(context).height * 0.75,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle indicator
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Sheet Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Conversation History',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.history.length}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: 'Refresh',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => sheetRef.read(aiAssistantNotifierProvider.notifier).loadHistory(),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: 'Close',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(bottomSheetContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Action button: New Session
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Start New Session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(bottomSheetContext).pop();
                          sheetRef.read(aiAssistantNotifierProvider.notifier).startNewConversation();
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 16),
                  // Thread list
                  Expanded(
                    child: state.isHistoryLoading
                        ? const Center(child: AppLoadingIndicator(message: 'Loading conversations...'))
                        : state.history.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.chat_bubble_outline, size: 44, color: AppColors.textMuted),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No Past Conversations',
                                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Start asking mining questions to begin a new intelligence session.',
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                itemCount: state.history.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 6),
                                itemBuilder: (itemCtx, index) {
                                  final item = state.history[index];
                                  final isSelected = item.id == state.activeConversationId;

                                  return Material(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.1)
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        Navigator.of(bottomSheetContext).pop();
                                        sheetRef.read(aiAssistantNotifierProvider.notifier).selectConversation(item.id);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary.withValues(alpha: 0.5)
                                                : AppColors.border,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.surface,
                                              child: Icon(
                                                Icons.chat_bubble_outline,
                                                size: 16,
                                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.title,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: AppTypography.bodySmall.copyWith(
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${item.messageCount} messages${item.updatedAt != null ? " • ${_formatRelativeTime(item.updatedAt)}" : ""}',
                                                    style: AppTypography.labelSmall.copyWith(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 18),
                                              color: AppColors.textSecondary,
                                              tooltip: 'Delete session',
                                              onPressed: () async {
                                                final confirmed = await showDialog<bool>(
                                                  context: bottomSheetContext,
                                                  builder: (dialogCtx) => AlertDialog(
                                                    title: const Text('Delete Session'),
                                                    content: const Text(
                                                        'Are you sure you want to delete this conversation session?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(dialogCtx).pop(false),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.of(dialogCtx).pop(true),
                                                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                                        child: const Text('Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirmed == true) {
                                                  sheetRef
                                                      .read(aiAssistantNotifierProvider.notifier)
                                                      .deleteConversation(item.id);
                                                }
                                              },
                                            ),
                                          ],
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
          },
        );
      },
    );
  }

  Widget _buildChatHeader(BuildContext context, AiAssistantState state, bool isDesktop) {
    final isCompact = MediaQuery.of(context).size.width < 480;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              key: const Key('ai_assistant_history_button'),
              icon: const Icon(Icons.menu, size: 20),
              tooltip: 'Conversation History',
              onPressed: () => _openHistorySheet(context),
            )
          else
            IconButton(
              icon: Icon(
                _showHistorySidebar ? Icons.format_indent_decrease : Icons.format_indent_increase,
                size: 20,
              ),
              tooltip: _showHistorySidebar ? 'Collapse History' : 'Expand History',
              onPressed: () => setState(() => _showHistorySidebar = !_showHistorySidebar),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.activeConversationTitle ?? 'Conversational RAG Assistant',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Grounded in verified statutory filings with mathematical verification',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isCompact)
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              tooltip: 'New Chat',
              onPressed: () => ref.read(aiAssistantNotifierProvider.notifier).startNewConversation(),
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Chat'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => ref.read(aiAssistantNotifierProvider.notifier).startNewConversation(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'MineIntel AI Assistant',
              style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Text(
                'Ask questions grounded strictly in uploaded statutory reports, environmental compliance data, and production records. Answers include verifiable evidence citations and calculation steps.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Suggested Inquiries',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _suggestedPrompts.map((prompt) {
                  return ActionChip(
                    label: Text(prompt, style: AppTypography.bodySmall),
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppColors.border),
                    ),
                    onPressed: () {
                      _textController.text = prompt;
                      _handleSend();
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(AiAssistantState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        return _ChatMessageBubble(message: message);
      },
    );
  }

  Widget _buildInputArea(AiAssistantState state) {
    final canSend = _textController.text.trim().isNotEmpty && !state.isQueryLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Ask about mining production, DGMS compliance, or ventilation...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const Key('ai_assistant_send_button'),
              icon: state.isQueryLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              color: canSend ? AppColors.primary : AppColors.textMuted,
              onPressed: canSend ? _handleSend : null,
              tooltip: 'Send Question',
            ),
          ],
        ),
      ),
    );
  }
}

/// Message bubble rendering user prompts and structured AI responses.
class _ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserBubble();
    }
    return _buildAssistantBubble(context);
  }

  Widget _buildUserBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          message.content,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context) {
    final confidence = message.confidence ?? 0.90;
    final confidenceColor = confidence >= 0.90
        ? AppColors.success
        : (confidence >= 0.75 ? AppColors.warning : AppColors.error);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 24,
          right: MediaQuery.sizeOf(context).width < 400 ? 16 : 36,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Assistant Pill + Confidence Rating (Overflow Protected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'MineIntel AI Response',
                      style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Confidence Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: confidenceColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: confidenceColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 12, color: confidenceColor),
                        const SizedBox(width: 4),
                        Text(
                          '${(confidence * 100).toStringAsFixed(1)}% Confidence',
                          style: AppTypography.labelSmall.copyWith(
                            color: confidenceColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Insufficient Evidence Warning Banner
            if (message.insufficientEvidence)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Insufficient Evidence in Knowledge Base',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The indexed statutory documents do not contain authoritative telemetry or verifiable records to confirm this statement with high certainty. Please index relevant document files.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // AI Answer Formatted Text (Parses ** into bold text, removing raw asterisks)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildMarkdownContent(
                context,
                message.content,
                AppTypography.bodyMedium.copyWith(height: 1.5),
              ),
            ),

            // Structured Calculation / Variance Callout (Overflow Protected)
            if (message.calculation != null)
              _buildCalculationCard(message.calculation!),

            // Verifiable Citations Badges (Overflow Protected)
            if (message.citations.isNotEmpty)
              _buildCitationsSection(message.citations),

            // Supporting Evidence Expandable Quotes
            if (message.evidence.isNotEmpty)
              _buildEvidenceSection(message.evidence),
          ],
        ),
      ),
    );
  }

  /// Parses markdown headings, bullets, and **bold** spans, filtering out raw asterisks.
  Widget _buildMarkdownContent(BuildContext context, String rawContent, TextStyle baseStyle) {
    if (rawContent.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final lines = rawContent.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        if (widgets.isNotEmpty && i < lines.length - 1) {
          widgets.add(const SizedBox(height: 6));
        }
        continue;
      }

      // Markdown Headings: ###, ##, #
      if (trimmed.startsWith('### ')) {
        final text = trimmed.substring(4);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: SelectableText.rich(
              TextSpan(
                children: _parseInlineSpans(
                  context,
                  text,
                  baseStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: (baseStyle.fontSize ?? 14) + 1,
                  ),
                ),
              ),
            ),
          ),
        );
        continue;
      } else if (trimmed.startsWith('## ') || trimmed.startsWith('# ')) {
        final text = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: SelectableText.rich(
              TextSpan(
                children: _parseInlineSpans(
                  context,
                  text,
                  baseStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: (baseStyle.fontSize ?? 14) + 2,
                  ),
                ),
              ),
            ),
          ),
        );
        continue;
      }

      // Bullet lists: *, -, •
      final isBullet = trimmed.startsWith('* ') ||
          trimmed.startsWith('- ') ||
          trimmed.startsWith('• ');

      if (isBullet) {
        final bulletContent = trimmed.substring(2).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: baseStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(
                      children: _parseInlineSpans(context, bulletContent, baseStyle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Standard paragraph line
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SelectableText.rich(
            TextSpan(
              children: _parseInlineSpans(context, trimmed, baseStyle),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Parses **bold**, ***bold-italic***, *italic*, and `code` into styled spans,
  /// stripping and filtering out all raw `**` asterisks.
  List<InlineSpan> _parseInlineSpans(BuildContext context, String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final inlineRegex = RegExp(r'(\*\*\*(.*?)\*\*\*|\*\*(.*?)\*\*|\*([^*]+)\*|`([^`]+)`)');

    int lastIndex = 0;
    for (final match in inlineRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        final plain = text.substring(lastIndex, match.start).replaceAll('**', '');
        if (plain.isNotEmpty) {
          spans.add(TextSpan(text: plain, style: baseStyle));
        }
      }

      if (match.group(2) != null) {
        // ***bold-italic***
        spans.add(TextSpan(
          text: match.group(2)!.replaceAll('**', ''),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (match.group(3) != null) {
        // **bold**
        spans.add(TextSpan(
          text: match.group(3)!.replaceAll('**', ''),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(4) != null) {
        // *italic*
        spans.add(TextSpan(
          text: match.group(4)!,
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (match.group(5) != null) {
        // `code`
        spans.add(TextSpan(
          text: match.group(5)!,
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      final remaining = text.substring(lastIndex).replaceAll('**', '');
      if (remaining.isNotEmpty) {
        spans.add(TextSpan(text: remaining, style: baseStyle));
      }
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text.replaceAll('**', ''), style: baseStyle));
    }

    return spans;
  }

  Widget _buildCalculationCard(AiCalculationModel calc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Mathematical Verification & Operational Variance',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              if (calc.variance != null)
                Text.rich(
                  TextSpan(
                    text: 'Variance: ',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    children: [
                      TextSpan(
                        text: calc.variance!,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: calc.variance!.startsWith('-') ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              if (calc.target != null)
                Text.rich(
                  TextSpan(
                    text: 'Target Baseline: ',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    children: [
                      TextSpan(
                        text: calc.target!,
                        style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (calc.formula != null) ...[
            const SizedBox(height: 6),
            Text(
              'Formula: ${calc.formula}',
              style: AppTypography.bodySmall.copyWith(
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCitationsSection(List<AiCitationModel> citations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Citations (${citations.length})',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: citations.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        c.documentName,
                        style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'p. ${c.pageNumber}',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection(List<AiEvidenceModel> evidence) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        dense: true,
        title: Row(
          children: [
            const Icon(Icons.menu_book, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Supporting Evidence Quotes (${evidence.length})',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        children: evidence.map((e) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${e.text}"',
                  style: AppTypography.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Source: ${e.source}${e.pageNumber != null ? ' (Page ${e.pageNumber})' : ''}',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        ),
      ),
    );
  }
}

/// Conversation history sidebar for browsing and deleting sessions.
class _HistorySidebar extends StatelessWidget {
  final List<ConversationThreadModel> history;
  final String? activeId;
  final bool isLoading;
  final ValueChanged<String> onSelect;
  final VoidCallback onNewChat;
  final ValueChanged<String> onDelete;

  const _HistorySidebar({
    required this.history,
    required this.activeId,
    required this.isLoading,
    required this.onSelect,
    required this.onNewChat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Sidebar Top
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onNewChat,
              ),
            ),
          ),
          const Divider(height: 1),

          // Thread List
          Expanded(
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: isLoading
                  ? const Center(child: AppLoadingIndicator(message: 'Loading sessions...'))
                  : history.isEmpty
                      ? Center(
                          child: Text(
                            'No past sessions',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          final isSelected = item.id == activeId;

                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                            leading: Icon(
                              Icons.chat_bubble_outline,
                              size: 16,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${item.messageCount} messages${item.updatedAt != null ? " • ${_formatRelativeTime(item.updatedAt)}" : ""}',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16),
                              color: AppColors.textSecondary,
                              tooltip: 'Delete session',
                              onPressed: () => onDelete(item.id),
                            ),
                            onTap: () => onSelect(item.id),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRelativeTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  final local = dt.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${local.month}/${local.day}/${local.year}';
}

