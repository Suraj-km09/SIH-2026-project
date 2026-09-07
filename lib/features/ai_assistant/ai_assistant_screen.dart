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
      backgroundColor: AppColors.background,
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

  Widget _buildChatHeader(BuildContext context, AiAssistantState state, bool isDesktop) {
    final isCompact = MediaQuery.of(context).size.width < 480;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu, size: 20),
              tooltip: 'Conversations',
              onPressed: () => Scaffold.of(context).openDrawer(),
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
        color: AppColors.surface,
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
        margin: const EdgeInsets.only(bottom: 24, right: 40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Assistant Pill + Confidence Rating
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  Text(
                    'MineIntel AI Response',
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
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

            // AI Answer Main Text
            Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                message.content,
                style: AppTypography.bodyMedium.copyWith(height: 1.5),
              ),
            ),

            // Structured Calculation / Variance Callout
            if (message.calculation != null)
              _buildCalculationCard(message.calculation!),

            // Verifiable Citations Badges
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
              Text(
                'Mathematical Verification & Operational Variance',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (calc.variance != null) ...[
                Text('Variance: ', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                Text(
                  calc.variance!,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: calc.variance!.startsWith('-') ? AppColors.error : AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (calc.target != null) ...[
                Text('Target Baseline: ', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                Text(
                  calc.target!,
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
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
                    Text(
                      c.documentName,
                      style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
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
            Text(
              'Supporting Evidence Quotes (${evidence.length})',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
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
        color: AppColors.surface,
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
              color: AppColors.surface,
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
                              '${item.messageCount} messages',
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
