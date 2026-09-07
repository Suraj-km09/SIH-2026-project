import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_assistant_model.dart';
import '../repositories/ai_assistant_repository.dart';
import 'app_state.dart';

@immutable
class AiAssistantState {
  final ViewStatus status;
  final String? activeConversationId;
  final String? activeConversationTitle;
  final List<ChatMessageModel> messages;
  final List<ConversationThreadModel> history;
  final bool isQueryLoading;
  final bool isHistoryLoading;
  final String? errorMessage;

  const AiAssistantState({
    this.status = ViewStatus.initial,
    this.activeConversationId,
    this.activeConversationTitle,
    this.messages = const [],
    this.history = const [],
    this.isQueryLoading = false,
    this.isHistoryLoading = false,
    this.errorMessage,
  });

  bool get isLoading => isQueryLoading || status == ViewStatus.loading;
  bool get hasMessages => messages.isNotEmpty;

  AiAssistantState copyWith({
    ViewStatus? status,
    String? activeConversationId,
    String? activeConversationTitle,
    List<ChatMessageModel>? messages,
    List<ConversationThreadModel>? history,
    bool? isQueryLoading,
    bool? isHistoryLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearConversation = false,
  }) {
    return AiAssistantState(
      status: status ?? this.status,
      activeConversationId: clearConversation ? null : (activeConversationId ?? this.activeConversationId),
      activeConversationTitle: clearConversation ? null : (activeConversationTitle ?? this.activeConversationTitle),
      messages: messages ?? this.messages,
      history: history ?? this.history,
      isQueryLoading: isQueryLoading ?? this.isQueryLoading,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Provider for AiAssistantNotifier.
final aiAssistantNotifierProvider =
    NotifierProvider<AiAssistantNotifier, AiAssistantState>(AiAssistantNotifier.new);

class AiAssistantNotifier extends Notifier<AiAssistantState> {
  late final AiAssistantRepository _repository;

  @override
  AiAssistantState build() {
    _repository = ref.watch(aiAssistantRepositoryProvider);
    return const AiAssistantState();
  }

  /// Loads conversation history threads.
  Future<void> loadHistory() async {
    state = state.copyWith(isHistoryLoading: true, clearError: true);

    try {
      final history = await _repository.getHistory();
      if (!ref.mounted) return;
      state = state.copyWith(
        history: history,
        isHistoryLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isHistoryLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Selects an existing conversation thread and loads its message history.
  Future<void> selectConversation(String conversationId) async {
    state = state.copyWith(
      isQueryLoading: true,
      activeConversationId: conversationId,
      clearError: true,
    );

    try {
      final thread = await _repository.getConversationById(conversationId);
      if (!ref.mounted) return;
      state = state.copyWith(
        activeConversationId: thread.id,
        activeConversationTitle: thread.title,
        messages: thread.messages,
        isQueryLoading: false,
        status: ViewStatus.success,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isQueryLoading: false,
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Starts a fresh conversational session.
  void startNewConversation() {
    state = state.copyWith(
      messages: const [],
      clearConversation: true,
      status: ViewStatus.initial,
      clearError: true,
    );
  }

  /// Deletes a conversation thread from history.
  Future<bool> deleteConversation(String conversationId) async {
    try {
      await _repository.deleteConversation(conversationId);
      if (!ref.mounted) return true;

      final updatedHistory = state.history.where((t) => t.id != conversationId).toList();
      final isActive = state.activeConversationId == conversationId;

      state = state.copyWith(
        history: updatedHistory,
        clearConversation: isActive,
        messages: isActive ? const [] : state.messages,
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Sends a conversational question to the RAG AI Assistant.
  /// Prevents accidental repeated queries using in-flight state guards.
  Future<bool> sendMessage(String text) async {
    final queryText = text.trim();
    if (queryText.isEmpty) return false;

    // Concurrency guard: reject if a query is already executing
    if (state.isQueryLoading) return false;

    final userMessage = ChatMessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: queryText,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isQueryLoading: true,
      clearError: true,
    );

    try {
      final request = AiAssistantQueryRequest(
        query: queryText,
        conversationId: state.activeConversationId,
      );

      final response = await _repository.query(request);
      if (!ref.mounted) return true;

      final assistantMessage = ChatMessageModel(
        id: 'asst_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: response.answer,
        timestamp: DateTime.now(),
        confidence: response.confidence,
        citations: response.citations,
        evidence: response.evidence,
        calculation: response.calculation,
        insufficientEvidence: response.insufficientEvidence,
      );

      final effectiveConversationId = response.conversationId ?? state.activeConversationId;

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        activeConversationId: effectiveConversationId,
        isQueryLoading: false,
        status: ViewStatus.success,
      );

      // Refresh history silently if active
      _refreshHistorySilently();
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isQueryLoading: false,
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> _refreshHistorySilently() async {
    try {
      final history = await _repository.getHistory();
      if (ref.mounted) {
        state = state.copyWith(history: history);
      }
    } catch (_) {}
  }
}
