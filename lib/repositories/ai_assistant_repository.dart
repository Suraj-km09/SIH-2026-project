import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_assistant_model.dart';
import '../network/ai_assistant_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for Conversational RAG AI Assistant.
abstract class AiAssistantRepository {
  Future<AiAssistantResponse> query(AiAssistantQueryRequest request);
  Future<List<ConversationThreadModel>> getHistory();
  Future<ConversationThreadModel> getConversationById(String id);
  Future<bool> deleteConversation(String id);
}

/// Concrete implementation delegating to live API or Mock repository.
class AiAssistantRepositoryImpl extends BaseRepository implements AiAssistantRepository {
  final AiAssistantRemoteDataSource _remoteDataSource;
  final AiAssistantRepository? mockRepository;

  AiAssistantRepositoryImpl({
    AiAssistantRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? AiAssistantRemoteDataSource();

  @override
  Future<AiAssistantResponse> query(AiAssistantQueryRequest request) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.query(request);
    }
    return execute(() => _remoteDataSource.query(request));
  }

  @override
  Future<List<ConversationThreadModel>> getHistory() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getHistory();
    }
    return execute(() => _remoteDataSource.getHistory());
  }

  @override
  Future<ConversationThreadModel> getConversationById(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getConversationById(id);
    }
    return execute(() => _remoteDataSource.getConversationById(id));
  }

  @override
  Future<bool> deleteConversation(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.deleteConversation(id);
    }
    return execute(() => _remoteDataSource.deleteConversation(id));
  }
}

/// High-fidelity offline mock repository matching exact conversational RAG schemas.
class MockAiAssistantRepository implements AiAssistantRepository {
  final Duration delay;
  final List<ConversationThreadModel> _threads = [];

  MockAiAssistantRepository({this.delay = Duration.zero}) {
    _seedDefaultThreads();
  }

  void _seedDefaultThreads() {
    _threads.addAll([
      ConversationThreadModel(
        id: 'conv_001',
        title: 'ECL Raw Coal Production Audit',
        messageCount: 2,
        createdAt: '2026-09-06T14:30:00.000Z',
        updatedAt: '2026-09-06T14:35:00.000Z',
        messages: [
          ChatMessageModel(
            id: 'msg_001_1',
            role: 'user',
            content: 'What was the raw coal production recorded for Rajmahal OCP in August 2026?',
            timestamp: DateTime.parse('2026-09-06T14:30:00.000Z'),
          ),
          ChatMessageModel(
            id: 'msg_001_2',
            role: 'assistant',
            content:
                'According to the verified production records, **Rajmahal OCP (ECL)** recorded **1,420.5 Thousand Tonnes** of raw coal production in August 2026 against a target of 1,387.0 Thousand Tonnes. This represents an operational variance of **+2.4%**.',
            timestamp: DateTime.parse('2026-09-06T14:30:04.000Z'),
            confidence: 0.96,
            citations: const [
              AiCitationModel(
                documentName: 'ECL_Production_August2026.pdf',
                pageNumber: 1,
                chunkIndex: 0,
              ),
              AiCitationModel(
                documentName: 'Rajmahal_Statutory_Monthly.pdf',
                pageNumber: 3,
                chunkIndex: 4,
              ),
            ],
            evidence: const [
              AiEvidenceModel(
                text: 'Total raw coal production for August recorded at 1,420.5 Tonnes across Block 2 and 4.',
                source: 'ECL_Production_August2026.pdf',
                pageNumber: 1,
              ),
            ],
            calculation: const AiCalculationModel(
              variance: '+2.4%',
              target: '1387.0 kt',
              formula: '((1420.5 - 1387.0) / 1387.0) * 100%',
            ),
            insufficientEvidence: false,
          ),
        ],
      ),
      ConversationThreadModel(
        id: 'conv_002',
        title: 'Ventilation & Environmental Compliance',
        messageCount: 2,
        createdAt: '2026-09-07T08:15:00.000Z',
        updatedAt: '2026-09-07T08:18:00.000Z',
        messages: [
          ChatMessageModel(
            id: 'msg_002_1',
            role: 'user',
            content: 'Are underground shaft ventilation levels within statutory DGMS limits?',
            timestamp: DateTime.parse('2026-09-07T08:15:00.000Z'),
          ),
          ChatMessageModel(
            id: 'msg_002_2',
            role: 'assistant',
            content:
                'Yes. Statutory telemetry indicates shaft air quantity reached **4,800 m³/min** at Dhanbad Underground Pit 4, safely above the prescribed DGMS minimum of 4,000 m³/min. Methane sensor readings averaged **0.08% CH4**, well within the 0.50% critical safety ceiling.',
            timestamp: DateTime.parse('2026-09-07T08:15:05.000Z'),
            confidence: 0.94,
            citations: const [
              AiCitationModel(
                documentName: 'DGMS_Ventilation_Survey_Q2.pdf',
                pageNumber: 4,
                chunkIndex: 12,
              ),
            ],
            evidence: const [
              AiEvidenceModel(
                text: 'Shaft ventilation volume: 4,800 m3/min. Return airway methane monitoring sensor averaged 0.08% CH4.',
                source: 'DGMS_Ventilation_Survey_Q2.pdf',
                pageNumber: 4,
              ),
            ],
            calculation: const AiCalculationModel(
              variance: '+20.0%',
              target: '4000 m3/min',
              formula: 'Shaft volume headroom over DGMS statutory lower bound',
            ),
            insufficientEvidence: false,
          ),
        ],
      ),
    ]);
  }

  @override
  Future<AiAssistantResponse> query(AiAssistantQueryRequest request) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final q = request.query.toLowerCase();

    // Check for queries where evidence does not exist
    final isUnrelated = q.contains('copper') ||
        q.contains('gold') ||
        q.contains('lithium') ||
        q.contains('weather') ||
        q.contains('unknown');

    if (isUnrelated) {
      return AiAssistantResponse(
        answer:
            'Insufficient Evidence in Knowledge Base: The ingested mining documents do not contain authoritative telemetry or statutory filings regarding the requested topic. Please verify that the relevant document has been uploaded and indexed in the Knowledge Base.',
        confidence: 0.25,
        citations: const [],
        evidence: const [],
        insufficientEvidence: true,
        conversationId: request.conversationId ?? 'conv_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    // Contextual mining responses
    if (q.contains('overburden') || q.contains('removal')) {
      return AiAssistantResponse(
        answer:
            'In August 2026, **Overburden Removal** reached **3,820.0 Cu.m** at Rajmahal OCP (ECL) against a target baseline of 3,900.0 Cu.m, reflecting an initial deficit of -2.05% before excavation reallocation.',
        confidence: 0.92,
        citations: const [
          AiCitationModel(
            documentName: 'ECL_Production_August2026.pdf',
            pageNumber: 1,
            chunkIndex: 1,
          ),
        ],
        evidence: const [
          AiEvidenceModel(
            text: 'Overburden excavation reached 3,820 Cu.m in Block 4.',
            source: 'ECL_Production_August2026.pdf',
            pageNumber: 1,
          ),
        ],
        calculation: const AiCalculationModel(
          variance: '-2.05%',
          target: '3900.0 Cu.m',
          formula: '((3820 - 3900) / 3900) * 100%',
        ),
        insufficientEvidence: false,
        conversationId: request.conversationId ?? 'conv_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    if (q.contains('methane') || q.contains('gas') || q.contains('safety')) {
      return AiAssistantResponse(
        answer:
            'Return airway continuous telemetry sensor averaged **0.08% CH4**, remaining in full compliance with the 0.50% statutory threshold governed by DGMS Circular 4.',
        confidence: 0.98,
        citations: const [
          AiCitationModel(
            documentName: 'ECL_Production_August2026.pdf',
            pageNumber: 2,
            chunkIndex: 4,
          ),
        ],
        evidence: const [
          AiEvidenceModel(
            text: 'Return airway methane monitoring sensor averaged 0.08% CH4.',
            source: 'ECL_Production_August2026.pdf',
            pageNumber: 2,
          ),
        ],
        insufficientEvidence: false,
        conversationId: request.conversationId ?? 'conv_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    // Default synthesized RAG answer
    return AiAssistantResponse(
      answer:
          'Based on cross-document synthesis of verified Coal India filings, Eastern Coalfields Limited (ECL) maintained statutory production velocity of 1,420.5 kt in Q3 2026 with an average confidence rating of 94.2%.',
      confidence: 0.91,
      citations: const [
        AiCitationModel(
          documentName: 'ECL_Production_August2026.pdf',
          pageNumber: 1,
          chunkIndex: 0,
        ),
      ],
      evidence: const [
        AiEvidenceModel(
          text: 'Total raw coal production for August recorded at 1,420.5 Tonnes.',
          source: 'ECL_Production_August2026.pdf',
          pageNumber: 1,
        ),
      ],
      calculation: const AiCalculationModel(
        variance: '+2.4%',
        target: '1387.0 kt',
      ),
      insufficientEvidence: false,
      conversationId: request.conversationId ?? 'conv_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<List<ConversationThreadModel>> getHistory() async {
    if (delay > Duration.zero) await Future.delayed(delay);
    return List.unmodifiable(_threads);
  }

  @override
  Future<ConversationThreadModel> getConversationById(String id) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    final index = _threads.indexWhere((t) => t.id == id);
    if (index != -1) {
      return _threads[index];
    }
    // Return empty fallback thread
    return ConversationThreadModel(
      id: id,
      title: 'New Session',
      messageCount: 0,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      messages: const [],
    );
  }

  @override
  Future<bool> deleteConversation(String id) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    _threads.removeWhere((t) => t.id == id);
    return true;
  }
}

/// Provider for AiAssistantRepository.
final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  return AiAssistantRepositoryImpl(
    mockRepository: MockAiAssistantRepository(),
  );
});
