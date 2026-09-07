import 'package:flutter/foundation.dart';

/// Request body for POST /api/v1/ai-assistant/query.
@immutable
class AiAssistantQueryRequest {
  final String query;
  final String? conversationId;
  final int topK;
  final Map<String, dynamic>? filters;

  const AiAssistantQueryRequest({
    required this.query,
    this.conversationId,
    this.topK = 5,
    this.filters,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'query': query,
      'topK': topK,
    };
    if (conversationId != null && conversationId!.isNotEmpty) {
      map['conversationId'] = conversationId;
    }
    if (filters != null && filters!.isNotEmpty) {
      map['filters'] = filters;
    }
    return map;
  }
}

/// Document citation linked in AI responses.
@immutable
class AiCitationModel {
  final String documentName;
  final int pageNumber;
  final int? chunkIndex;

  const AiCitationModel({
    required this.documentName,
    required this.pageNumber,
    this.chunkIndex,
  });

  factory AiCitationModel.fromJson(Map<String, dynamic> json) {
    return AiCitationModel(
      documentName: json['documentName'] as String? ?? 'Document',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      chunkIndex: (json['chunkIndex'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'documentName': documentName,
        'pageNumber': pageNumber,
        if (chunkIndex != null) 'chunkIndex': chunkIndex,
      };
}

/// Verifiable excerpt from indexed mining documents.
@immutable
class AiEvidenceModel {
  final String text;
  final String source;
  final int? pageNumber;

  const AiEvidenceModel({
    required this.text,
    required this.source,
    this.pageNumber,
  });

  factory AiEvidenceModel.fromJson(Map<String, dynamic> json) {
    return AiEvidenceModel(
      text: json['text'] as String? ?? '',
      source: json['source'] as String? ?? 'Repository',
      pageNumber: (json['pageNumber'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'source': source,
        if (pageNumber != null) 'pageNumber': pageNumber,
      };
}

/// Structured calculation or variance verification details.
@immutable
class AiCalculationModel {
  final String? variance;
  final String? target;
  final String? formula;
  final Map<String, dynamic>? details;

  const AiCalculationModel({
    this.variance,
    this.target,
    this.formula,
    this.details,
  });

  factory AiCalculationModel.fromJson(Map<String, dynamic> json) {
    return AiCalculationModel(
      variance: json['variance']?.toString(),
      target: json['target']?.toString(),
      formula: json['formula']?.toString(),
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (variance != null) map['variance'] = variance;
    if (target != null) map['target'] = target;
    if (formula != null) map['formula'] = formula;
    if (details != null) map['details'] = details;
    return map;
  }
}

/// Structured response payload from POST /api/v1/ai-assistant/query.
@immutable
class AiAssistantResponse {
  final String answer;
  final double confidence;
  final List<AiCitationModel> citations;
  final List<AiEvidenceModel> evidence;
  final AiCalculationModel? calculation;
  final bool insufficientEvidence;
  final String? conversationId;

  const AiAssistantResponse({
    required this.answer,
    required this.confidence,
    this.citations = const [],
    this.evidence = const [],
    this.calculation,
    this.insufficientEvidence = false,
    this.conversationId,
  });

  factory AiAssistantResponse.fromJson(Map<String, dynamic> json) {
    // Top-level payload or wrapped inside "data"
    final data = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final citationsRaw = data['citations'] as List<dynamic>? ?? [];
    final evidenceRaw = data['evidence'] as List<dynamic>? ?? [];

    return AiAssistantResponse(
      answer: data['answer'] as String? ?? data['response'] as String? ?? '',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.85,
      citations: citationsRaw
          .whereType<Map<String, dynamic>>()
          .map(AiCitationModel.fromJson)
          .toList(),
      evidence: evidenceRaw
          .whereType<Map<String, dynamic>>()
          .map(AiEvidenceModel.fromJson)
          .toList(),
      calculation: data['calculation'] is Map<String, dynamic>
          ? AiCalculationModel.fromJson(data['calculation'] as Map<String, dynamic>)
          : null,
      insufficientEvidence: data['insufficientEvidence'] as bool? ?? false,
      conversationId: data['conversationId']?.toString() ?? data['id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'answer': answer,
        'confidence': confidence,
        'citations': citations.map((c) => c.toJson()).toList(),
        'evidence': evidence.map((e) => e.toJson()).toList(),
        if (calculation != null) 'calculation': calculation!.toJson(),
        'insufficientEvidence': insufficientEvidence,
        if (conversationId != null) 'conversationId': conversationId,
      };
}

/// Message entity representing a chat bubble in the conversational UI.
@immutable
class ChatMessageModel {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final double? confidence;
  final List<AiCitationModel> citations;
  final List<AiEvidenceModel> evidence;
  final AiCalculationModel? calculation;
  final bool insufficientEvidence;

  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.confidence,
    this.citations = const [],
    this.evidence = const [],
    this.calculation,
    this.insufficientEvidence = false,
  });

  bool get isUser => role.toLowerCase() == 'user';
  bool get isAssistant => role.toLowerCase() == 'assistant';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final citationsRaw = json['citations'] as List<dynamic>? ?? [];
    final evidenceRaw = json['evidence'] as List<dynamic>? ?? [];

    DateTime time;
    if (json['timestamp'] != null) {
      time = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
    } else {
      time = DateTime.now();
    }

    return ChatMessageModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? UniqueKey().toString(),
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? json['text'] as String? ?? '',
      timestamp: time,
      confidence: (json['confidence'] as num?)?.toDouble(),
      citations: citationsRaw
          .whereType<Map<String, dynamic>>()
          .map(AiCitationModel.fromJson)
          .toList(),
      evidence: evidenceRaw
          .whereType<Map<String, dynamic>>()
          .map(AiEvidenceModel.fromJson)
          .toList(),
      calculation: json['calculation'] is Map<String, dynamic>
          ? AiCalculationModel.fromJson(json['calculation'] as Map<String, dynamic>)
          : null,
      insufficientEvidence: json['insufficientEvidence'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        if (confidence != null) 'confidence': confidence,
        'citations': citations.map((c) => c.toJson()).toList(),
        'evidence': evidence.map((e) => e.toJson()).toList(),
        if (calculation != null) 'calculation': calculation!.toJson(),
        'insufficientEvidence': insufficientEvidence,
      };
}

/// Past conversational session thread metadata from GET /api/v1/ai-assistant/history.
@immutable
class ConversationThreadModel {
  final String id;
  final String title;
  final int messageCount;
  final String? createdAt;
  final String? updatedAt;
  final List<ChatMessageModel> messages;

  const ConversationThreadModel({
    required this.id,
    required this.title,
    this.messageCount = 0,
    this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  factory ConversationThreadModel.fromJson(Map<String, dynamic> json) {
    final messagesRaw = json['messages'] as List<dynamic>? ?? [];

    return ConversationThreadModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Mining Intelligence Session',
      messageCount: (json['messageCount'] as num?)?.toInt() ?? messagesRaw.length,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      messages: messagesRaw
          .whereType<Map<String, dynamic>>()
          .map(ChatMessageModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messageCount': messageCount,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
        'messages': messages.map((m) => m.toJson()).toList(),
      };
}
