import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/knowledge_base_model.dart';
import '../network/knowledge_base_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for Knowledge Base Vector Indexing & RAG operations.
abstract class KnowledgeBaseRepository {
  Future<KnowledgeBaseListResponse> getKnowledgeBase(KnowledgeBaseFilter filter);
  Future<IndexDocumentResponse> indexDocument(String documentId);
  Future<KnowledgeBaseDetailModel> getDocumentChunks(String documentId);
  Future<bool> deleteDocumentIndex(String documentId);
  Future<KnowledgeBaseSearchResponse> search(
    String query, {
    int topK = 5,
    Map<String, dynamic>? filters,
  });
  Future<IndexDocumentResponse> ragIndexDocument(String documentId);
  Future<List<KnowledgeBaseSearchResult>> ragSearch(String query, {int topK = 5});
}

/// Concrete implementation delegating to live API or Mock repository.
class KnowledgeBaseRepositoryImpl extends BaseRepository implements KnowledgeBaseRepository {
  final KnowledgeBaseRemoteDataSource _remoteDataSource;
  final KnowledgeBaseRepository? mockRepository;

  KnowledgeBaseRepositoryImpl({
    KnowledgeBaseRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? KnowledgeBaseRemoteDataSource();

  @override
  Future<KnowledgeBaseListResponse> getKnowledgeBase(KnowledgeBaseFilter filter) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getKnowledgeBase(filter);
    }
    return execute(() => _remoteDataSource.getKnowledgeBase(filter));
  }

  @override
  Future<IndexDocumentResponse> indexDocument(String documentId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.indexDocument(documentId);
    }
    return execute(() => _remoteDataSource.indexDocument(documentId));
  }

  @override
  Future<KnowledgeBaseDetailModel> getDocumentChunks(String documentId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getDocumentChunks(documentId);
    }
    return execute(() => _remoteDataSource.getDocumentChunks(documentId));
  }

  @override
  Future<bool> deleteDocumentIndex(String documentId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.deleteDocumentIndex(documentId);
    }
    return execute(() => _remoteDataSource.deleteDocumentIndex(documentId));
  }

  @override
  Future<KnowledgeBaseSearchResponse> search(
    String query, {
    int topK = 5,
    Map<String, dynamic>? filters,
  }) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.search(query, topK: topK, filters: filters);
    }
    return execute(() => _remoteDataSource.search(query, topK: topK, filters: filters));
  }

  @override
  Future<IndexDocumentResponse> ragIndexDocument(String documentId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.ragIndexDocument(documentId);
    }
    return execute(() => _remoteDataSource.ragIndexDocument(documentId));
  }

  @override
  Future<List<KnowledgeBaseSearchResult>> ragSearch(String query, {int topK = 5}) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.ragSearch(query, topK: topK);
    }
    return execute(() => _remoteDataSource.ragSearch(query, topK: topK));
  }
}

/// High-fidelity offline mock repository matching exact Knowledge Base schemas.
class MockKnowledgeBaseRepository implements KnowledgeBaseRepository {
  final Duration delay;
  final List<KnowledgeBaseDocumentModel> _docs = [];
  final Map<String, List<VectorChunkModel>> _chunksByDoc = {};

  MockKnowledgeBaseRepository({this.delay = Duration.zero}) {
    _seedDefaultData();
  }

  void _seedDefaultData() {
    _docs.addAll([
      const KnowledgeBaseDocumentModel(
        id: 'doc_001',
        originalName: 'ECL_Production_August2026.pdf',
        isIndexed: true,
        chunksCount: 18,
        lastIndexedAt: '2026-09-06T10:05:00.000Z',
        category: 'production',
        classification: 'confidential',
        mimeType: 'application/pdf',
        size: 3450120,
      ),
      const KnowledgeBaseDocumentModel(
        id: 'doc_002',
        originalName: 'DGMS_Ventilation_Survey_Q2.pdf',
        isIndexed: true,
        chunksCount: 24,
        lastIndexedAt: '2026-09-06T11:20:00.000Z',
        category: 'safety',
        classification: 'restricted',
        mimeType: 'application/pdf',
        size: 5120400,
      ),
      const KnowledgeBaseDocumentModel(
        id: 'doc_003',
        originalName: 'Environmental_Safeguards_Audit.pdf',
        isIndexed: true,
        chunksCount: 32,
        lastIndexedAt: '2026-09-07T04:30:00.000Z',
        category: 'compliance',
        classification: 'internal',
        mimeType: 'application/pdf',
        size: 8910240,
      ),
      const KnowledgeBaseDocumentModel(
        id: 'doc_004',
        originalName: 'Jharia_Mine_Expansion_Draft.docx',
        isIndexed: false,
        chunksCount: 0,
        lastIndexedAt: null,
        category: 'planning',
        classification: 'restricted',
        mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        size: 1420900,
      ),
    ]);

    _chunksByDoc['doc_001'] = [
      const VectorChunkModel(
        id: 'chunk_001_1',
        chunkIndex: 0,
        pageNumber: 1,
        content:
            'Eastern Coalfields Limited (ECL) August 2026 Production Report. Total raw coal extraction reached 1,420.5 Thousand Tonnes across opencast and underground divisions.',
        createdAt: '2026-09-06T10:05:00.000Z',
      ),
      const VectorChunkModel(
        id: 'chunk_001_2',
        chunkIndex: 1,
        pageNumber: 1,
        content:
            'Overburden excavation reached 3,820.0 Cu.m in Block 4 against a plan target of 3,900.0 Cu.m, requiring dragline deployment optimization.',
        createdAt: '2026-09-06T10:05:00.000Z',
      ),
      const VectorChunkModel(
        id: 'chunk_001_3',
        chunkIndex: 2,
        pageNumber: 2,
        content:
            'Return airway continuous methane monitoring sensor averaged 0.08% CH4, safely below the 0.50% critical safety ceiling.',
        createdAt: '2026-09-06T10:05:00.000Z',
      ),
    ];

    _chunksByDoc['doc_002'] = [
      const VectorChunkModel(
        id: 'chunk_002_1',
        chunkIndex: 0,
        pageNumber: 1,
        content:
            'DGMS Quarterly Underground Mine Ventilation Survey. Main intake fan delivery was clocked at 4,800 m3/min in Pit 4 shaft.',
        createdAt: '2026-09-06T11:20:00.000Z',
      ),
      const VectorChunkModel(
        id: 'chunk_002_2',
        chunkIndex: 1,
        pageNumber: 2,
        content:
            'Respirable dust PM10 concentration sampled at working face averaged 2.4 mg/m3, adhering to permissible environmental thresholds.',
        createdAt: '2026-09-06T11:20:00.000Z',
      ),
    ];

    _chunksByDoc['doc_003'] = [
      const VectorChunkModel(
        id: 'chunk_003_1',
        chunkIndex: 0,
        pageNumber: 1,
        content:
            'Statutory Environmental Compliance Audit. Afforestation target of 12.5 hectares was achieved on reclaimed overburden dumps with 88% survival rate.',
        createdAt: '2026-09-07T04:30:00.000Z',
      ),
    ];
  }

  @override
  Future<KnowledgeBaseListResponse> getKnowledgeBase(KnowledgeBaseFilter filter) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    var list = List<KnowledgeBaseDocumentModel>.from(_docs);

    if (filter.search != null && filter.search!.isNotEmpty) {
      final q = filter.search!.toLowerCase();
      list = list.where((d) => d.originalName.toLowerCase().contains(q)).toList();
    }
    if (filter.category != null && filter.category!.isNotEmpty) {
      list = list.where((d) => d.category?.toLowerCase() == filter.category!.toLowerCase()).toList();
    }
    if (filter.classification != null && filter.classification!.isNotEmpty) {
      list = list.where((d) => d.classification?.toLowerCase() == filter.classification!.toLowerCase()).toList();
    }

    final totalIndexed = _docs.where((d) => d.isIndexed).length;
    final totalChunks = _docs.fold<int>(0, (sum, d) => sum + d.chunksCount);

    final total = list.length;
    final totalPages = (total / filter.limit).ceil().clamp(1, 99999);
    final startIndex = ((filter.page - 1) * filter.limit).clamp(0, total);
    final endIndex = (startIndex + filter.limit).clamp(0, total);
    final paginated = list.sublist(startIndex, endIndex);

    return KnowledgeBaseListResponse(
      documents: paginated,
      meta: KnowledgeBaseMeta(
        total: total,
        page: filter.page,
        limit: filter.limit,
        pages: totalPages,
        totalIndexedDocuments: totalIndexed,
        totalVectorChunks: totalChunks,
      ),
    );
  }

  @override
  Future<IndexDocumentResponse> indexDocument(String documentId) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final index = _docs.indexWhere((d) => d.id == documentId);
    if (index != -1) {
      final updated = _docs[index].copyWith(
        isIndexed: true,
        chunksCount: _docs[index].chunksCount > 0 ? _docs[index].chunksCount : 15,
        lastIndexedAt: DateTime.now().toUtc().toIso8601String(),
      );
      _docs[index] = updated;

      if (!_chunksByDoc.containsKey(documentId) || _chunksByDoc[documentId]!.isEmpty) {
        _chunksByDoc[documentId] = [
          VectorChunkModel(
            id: 'chunk_${documentId}_gen',
            chunkIndex: 0,
            pageNumber: 1,
            content: 'Indexed vector embedding content for document ${updated.originalName}.',
            createdAt: DateTime.now().toUtc().toIso8601String(),
          ),
        ];
      }

      return IndexDocumentResponse(
        documentId: documentId,
        documentName: updated.originalName,
        chunksIndexed: updated.chunksCount,
        indexedAt: updated.lastIndexedAt,
      );
    }

    return IndexDocumentResponse(
      documentId: documentId,
      documentName: 'Document',
      chunksIndexed: 12,
      indexedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<KnowledgeBaseDetailModel> getDocumentChunks(String documentId) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final doc = _docs.firstWhere(
      (d) => d.id == documentId,
      orElse: () => KnowledgeBaseDocumentModel(
        id: documentId,
        originalName: 'Document $documentId',
        isIndexed: true,
        chunksCount: 0,
      ),
    );

    final chunks = _chunksByDoc[documentId] ?? [];

    return KnowledgeBaseDetailModel(
      documentId: documentId,
      documentName: doc.originalName,
      chunksCount: chunks.length,
      chunks: chunks,
    );
  }

  @override
  Future<bool> deleteDocumentIndex(String documentId) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final index = _docs.indexWhere((d) => d.id == documentId);
    if (index != -1) {
      _docs[index] = _docs[index].copyWith(
        isIndexed: false,
        chunksCount: 0,
        lastIndexedAt: null,
      );
    }
    _chunksByDoc.remove(documentId);
    return true;
  }

  @override
  Future<KnowledgeBaseSearchResponse> search(
    String query, {
    int topK = 5,
    Map<String, dynamic>? filters,
  }) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final q = query.toLowerCase();
    final results = <KnowledgeBaseSearchResult>[];

    _chunksByDoc.forEach((docId, chunks) {
      final doc = _docs.firstWhere(
        (d) => d.id == docId,
        orElse: () => KnowledgeBaseDocumentModel(
          id: docId,
          originalName: 'Mining Archive',
          isIndexed: true,
        ),
      );

      for (final chunk in chunks) {
        final contentLower = chunk.content.toLowerCase();
        double similarity = 0.65;
        if (contentLower.contains(q)) {
          similarity = 0.94;
        } else {
          final words = q.split(RegExp(r'\s+'));
          int matches = words.where((w) => w.isNotEmpty && contentLower.contains(w)).length;
          if (matches > 0) {
            similarity = (0.70 + (matches * 0.08)).clamp(0.0, 0.98);
          }
        }

        results.add(
          KnowledgeBaseSearchResult(
            chunkId: chunk.id,
            documentId: docId,
            documentName: doc.originalName,
            pageNumber: chunk.pageNumber,
            text: chunk.content,
            similarity: similarity,
          ),
        );
      }
    });

    // Sort descending by similarity
    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    final capped = results.take(topK).toList();

    return KnowledgeBaseSearchResponse(
      query: query,
      topK: topK,
      filters: filters,
      totalResults: capped.length,
      results: capped,
    );
  }

  @override
  Future<IndexDocumentResponse> ragIndexDocument(String documentId) {
    return indexDocument(documentId);
  }

  @override
  Future<List<KnowledgeBaseSearchResult>> ragSearch(String query, {int topK = 5}) async {
    final resp = await search(query, topK: topK);
    return resp.results;
  }
}

/// Provider for KnowledgeBaseRepository.
final knowledgeBaseRepositoryProvider = Provider<KnowledgeBaseRepository>((ref) {
  return KnowledgeBaseRepositoryImpl(
    mockRepository: MockKnowledgeBaseRepository(),
  );
});
