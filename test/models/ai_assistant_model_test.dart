import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/ai_assistant_model.dart';

void main() {
  group('Phase 9 AI Assistant Models Tests', () {
    test('AiAssistantQueryRequest serializes correctly with optional fields', () {
      const req = AiAssistantQueryRequest(
        query: 'What is the overburden volume?',
        conversationId: 'conv_123',
        topK: 10,
        filters: {'mine': 'Rajmahal'},
      );

      final json = req.toJson();
      expect(json['query'], 'What is the overburden volume?');
      expect(json['conversationId'], 'conv_123');
      expect(json['topK'], 10);
      expect(json['filters'], {'mine': 'Rajmahal'});
    });

    test('AiAssistantResponse parses full response with citations, evidence and calculations', () {
      final json = {
        'success': true,
        'data': {
          'answer': 'Production reached 1,420.5 kt.',
          'confidence': 0.95,
          'citations': [
            {'documentName': 'ECL_Production.pdf', 'pageNumber': 2, 'chunkIndex': 1},
          ],
          'evidence': [
            {'text': 'Verified raw coal extraction', 'source': 'ECL_Production.pdf', 'pageNumber': 2},
          ],
          'calculation': {
            'variance': '+2.4%',
            'target': '1387.0 kt',
            'formula': '((1420.5 - 1387) / 1387) * 100',
          },
          'insufficientEvidence': false,
          'conversationId': 'conv_999',
        },
      };

      final resp = AiAssistantResponse.fromJson(json);
      expect(resp.answer, 'Production reached 1,420.5 kt.');
      expect(resp.confidence, 0.95);
      expect(resp.citations.length, 1);
      expect(resp.citations.first.documentName, 'ECL_Production.pdf');
      expect(resp.citations.first.pageNumber, 2);
      expect(resp.evidence.length, 1);
      expect(resp.evidence.first.source, 'ECL_Production.pdf');
      expect(resp.calculation?.variance, '+2.4%');
      expect(resp.insufficientEvidence, isFalse);
      expect(resp.conversationId, 'conv_999');
    });

    test('AiAssistantResponse parses insufficientEvidence flag correctly', () {
      final json = {
        'data': {
          'answer': 'Insufficient Evidence in Knowledge Base',
          'confidence': 0.20,
          'citations': [],
          'evidence': [],
          'insufficientEvidence': true,
          'conversationId': 'conv_empty',
        },
      };

      final resp = AiAssistantResponse.fromJson(json);
      expect(resp.insufficientEvidence, isTrue);
      expect(resp.confidence, 0.20);
      expect(resp.citations.isEmpty, isTrue);
    });

    test('ConversationThreadModel and ChatMessageModel serialize correctly', () {
      final thread = ConversationThreadModel(
        id: 'conv_001',
        title: 'Mining Production Thread',
        messageCount: 2,
        createdAt: '2026-09-07T10:00:00.000Z',
        messages: [
          ChatMessageModel(
            id: 'm1',
            role: 'user',
            content: 'Hello AI',
            timestamp: DateTime.parse('2026-09-07T10:00:00.000Z'),
          ),
          ChatMessageModel(
            id: 'm2',
            role: 'assistant',
            content: 'Hello Operator',
            timestamp: DateTime.parse('2026-09-07T10:00:02.000Z'),
            confidence: 0.98,
          ),
        ],
      );

      final json = thread.toJson();
      expect(json['id'], 'conv_001');
      expect(json['messageCount'], 2);
      expect(thread.messages.first.isUser, isTrue);
      expect(thread.messages.last.isAssistant, isTrue);

      final parsed = ConversationThreadModel.fromJson(json);
      expect(parsed.title, 'Mining Production Thread');
      expect(parsed.messages.length, 2);
      expect(parsed.messages.last.confidence, 0.98);
    });
  });
}
