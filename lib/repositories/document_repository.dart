import 'dart:io';
import '../core/errors/failures.dart';
import '../models/document_model.dart';
import '../network/document_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for Document Lifecycle operations.
abstract class DocumentRepository {
  Future<DocumentModel> uploadDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
  });

  Future<DocumentListResponse> getDocuments(DocumentFilter filter);

  Future<DocumentDetailModel> getDocumentDetail(String id);

  Future<DocumentMetadataModel> getDocumentMetadata(String id);

  Future<DocumentModel> updateDocumentMetadata(
    String id,
    DocumentMetadataUpdateRequest request,
  );

  Future<DocumentStatusModel> getDocumentStatus(String id);

  Future<DocumentModel> reprocessDocument(String id);

  Future<DocumentModel> retryDocument(String id);

  Future<String> deleteDocument(String id);

  Future<String> downloadDocument(String id, String savePath);
}

/// Concrete implementation delegating to DocumentRemoteDataSource or Mock.
class DocumentRepositoryImpl extends BaseRepository implements DocumentRepository {
  final DocumentRemoteDataSource _remoteDataSource;
  final DocumentRepository? mockRepository;

  DocumentRepositoryImpl({
    DocumentRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? DocumentRemoteDataSourceImpl();

  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50 MB limit

  @override
  Future<DocumentModel> uploadDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final size = await file.length();
    if (size > maxFileSizeBytes) {
      throw const ValidationFailure('File size exceeds the 50 MB limit.');
    }

    if (isMockMode && mockRepository != null) {
      return mockRepository!.uploadDocument(file, onSendProgress: onSendProgress);
    }
    return execute(() => _remoteDataSource.uploadDocument(
          file,
          onSendProgress: onSendProgress,
        ));
  }

  @override
  Future<DocumentListResponse> getDocuments(DocumentFilter filter) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getDocuments(filter);
    }
    return execute(() => _remoteDataSource.getDocuments(filter));
  }

  @override
  Future<DocumentDetailModel> getDocumentDetail(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getDocumentDetail(id);
    }
    return execute(() => _remoteDataSource.getDocumentDetail(id));
  }

  @override
  Future<DocumentMetadataModel> getDocumentMetadata(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getDocumentMetadata(id);
    }
    return execute(() => _remoteDataSource.getDocumentMetadata(id));
  }

  @override
  Future<DocumentModel> updateDocumentMetadata(
    String id,
    DocumentMetadataUpdateRequest request,
  ) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.updateDocumentMetadata(id, request);
    }
    return execute(() => _remoteDataSource.updateDocumentMetadata(id, request));
  }

  @override
  Future<DocumentStatusModel> getDocumentStatus(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getDocumentStatus(id);
    }
    return execute(() => _remoteDataSource.getDocumentStatus(id));
  }

  @override
  Future<DocumentModel> reprocessDocument(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.reprocessDocument(id);
    }
    return execute(() => _remoteDataSource.reprocessDocument(id));
  }

  @override
  Future<DocumentModel> retryDocument(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.retryDocument(id);
    }
    return execute(() => _remoteDataSource.retryDocument(id));
  }

  @override
  Future<String> deleteDocument(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.deleteDocument(id);
    }
    return execute(() => _remoteDataSource.deleteDocument(id));
  }

  @override
  Future<String> downloadDocument(String id, String savePath) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.downloadDocument(id, savePath);
    }
    return execute(() => _remoteDataSource.downloadDocument(id, savePath));
  }
}

/// High-fidelity offline mock repository matching exact API schema responses.
class MockDocumentRepository implements DocumentRepository {
  final Duration delay;
  final List<DocumentModel> _documents;
  final Map<String, List<DocumentPageModel>> _pagesMap = {};
  final Map<String, DocumentStatusModel> _statusMap = {};

  MockDocumentRepository({
    this.delay = Duration.zero,
    List<DocumentModel>? initialDocuments,
  }) : _documents = initialDocuments ?? _seedDocuments() {
    _seedPagesAndStatus();
  }

  void _seedPagesAndStatus() {
    for (final doc in _documents) {
      _pagesMap[doc.id] = [
        DocumentPageModel(
          id: 'page-${doc.id}-1',
          documentId: doc.id,
          pageNumber: 1,
          text: 'MINISTRY OF COAL - GOVERNMENT OF INDIA\n'
              '${doc.originalName.toUpperCase()}\n'
              'Category: ${doc.category} | Classification: ${doc.classification.toUpperCase()}\n\n'
              '1. OPERATIONAL SUMMARY:\n'
              'Extraction activities for Block 04 recorded nominal output. Compliance indices '
              'remain compliant under DGMS circular guidelines 2026/04.\n\n'
              '2. GEOLOGICAL DISPATCH DATA:\n'
              'Coordinates: 23.7957 N, 86.4304 E (Jharia Coalfield Pit 3).\n'
              'Net output tonnage: 45,280 MT at 14.2% ash moisture content.',
        ),
        if (doc.totalPages > 1)
          DocumentPageModel(
            id: 'page-${doc.id}-2',
            documentId: doc.id,
            pageNumber: 2,
            text: '3. STATUTORY SAFETY & AIR MONITORING:\n'
                'Particulate sensors PM10 registered average 64 ug/m3. Ventilation speed: 4.8 m/s.\n'
                'Methane sensor array status: NOMINAL (<0.1% CH4).\n\n'
                '4. SIGN-OFF AUTHORIZATION:\n'
                'Mines Manager: Dr. S. K. Mukherjee | First Class Mine Manager Reg #5421.',
          ),
      ];

      _statusMap[doc.id] = DocumentStatusModel(
        id: 'job-${doc.id}',
        documentId: doc.id,
        status: doc.status,
        progress: doc.status == 'completed' ? 100 : (doc.status == 'processing' ? 65 : 0),
        error: doc.status == 'failed' ? 'OCR extraction engine timed out on corrupt stream' : null,
        createdAt: doc.uploadedAt ?? '2026-09-06T10:00:00.000Z',
        updatedAt: '2026-09-06T10:01:15.000Z',
      );
    }
  }

  static List<DocumentModel> _seedDocuments() {
    return [
      const DocumentModel(
        id: 'doc-001',
        originalName: 'ECL_Rajmahal_Monthly_Production_August.pdf',
        filename: '1725619200000-ECL_Rajmahal.pdf',
        mimeType: 'application/pdf',
        fileSize: 2457600,
        fileType: 'pdf',
        hash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        category: 'Production Report',
        classification: 'internal',
        status: 'completed',
        totalPages: 14,
        gisMetadata: GisMetadata(
          latitude: 25.0450,
          longitude: 87.2512,
          elevation: 112.5,
          mineCode: 'ECL-04',
          region: 'Jharkhand',
        ),
        uploadedAt: '2026-09-06T10:00:00.000Z',
        userId: 'usr-admin-01',
        entities: [
          DocumentEntity(name: 'Rajmahal OCP', type: 'LOCATION'),
          DocumentEntity(name: 'Eastern Coalfields Limited', type: 'ORGANIZATION'),
          DocumentEntity(name: 'Seam VII', type: 'STRATUM'),
        ],
        topicIds: ['top-production', 'top-ecl'],
      ),
      const DocumentModel(
        id: 'doc-002',
        originalName: 'BCCL_Dhanbad_Safety_Audit_Q2_2026.docx',
        filename: '1725619300000-BCCL_Safety.docx',
        mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        fileSize: 1843200,
        fileType: 'docx',
        hash: 'b1946ac92492d2347c6235b4d2611184',
        category: 'Safety & DGMS Directive',
        classification: 'confidential',
        status: 'completed',
        totalPages: 8,
        gisMetadata: GisMetadata(
          latitude: 23.7957,
          longitude: 86.4304,
          elevation: 220.0,
          mineCode: 'BCCL-09',
          region: 'Dhanbad',
        ),
        uploadedAt: '2026-09-06T11:30:00.000Z',
        userId: 'usr-admin-01',
        entities: [
          DocumentEntity(name: 'DGMS Central Zone', type: 'REGULATOR'),
          DocumentEntity(name: 'Dhanbad Underground Pit 4', type: 'LOCATION'),
        ],
        topicIds: ['top-safety', 'top-dgms'],
      ),
      const DocumentModel(
        id: 'doc-003',
        originalName: 'SECL_Korba_Dispatch_Weighbridge_Logs.xlsx',
        filename: '1725619400000-SECL_Weighbridge.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        fileSize: 4194304,
        fileType: 'xlsx',
        hash: 'c2837f3984a923847c293847c9238472',
        category: 'Weighbridge Dispatch',
        classification: 'restricted',
        status: 'processing',
        totalPages: 24,
        gisMetadata: GisMetadata(
          latitude: 22.3595,
          longitude: 82.7501,
          elevation: 304.0,
          mineCode: 'SECL-12',
          region: 'Chhattisgarh',
        ),
        uploadedAt: '2026-09-07T08:15:00.000Z',
        userId: 'usr-admin-01',
      ),
      const DocumentModel(
        id: 'doc-004',
        originalName: 'CMPDI_Exploration_DrillCore_Lithology.csv',
        filename: '1725619500000-CMPDI_Lithology.csv',
        mimeType: 'text/csv',
        fileSize: 524288,
        fileType: 'csv',
        hash: 'd3948c29384c29384c29384c29384c29',
        category: 'Geological Log',
        classification: 'public',
        status: 'queued',
        totalPages: 1,
        gisMetadata: GisMetadata(
          latitude: 23.6345,
          longitude: 85.3789,
          elevation: 650.0,
          mineCode: 'CMPDI-01',
          region: 'Ranchi',
        ),
        uploadedAt: '2026-09-07T09:45:00.000Z',
        userId: 'usr-admin-01',
      ),
      const DocumentModel(
        id: 'doc-005',
        originalName: 'WCL_Nagpur_Air_Quality_Compliance_July.pdf',
        filename: '1725619600000-WCL_AirQuality.pdf',
        mimeType: 'application/pdf',
        fileSize: 3145728,
        fileType: 'pdf',
        hash: 'e4958d3948c29384c29384c29384c294',
        category: 'Environmental Audit',
        classification: 'internal',
        status: 'failed',
        totalPages: 6,
        gisMetadata: GisMetadata(
          latitude: 21.1458,
          longitude: 79.0882,
          elevation: 310.0,
          mineCode: 'WCL-03',
          region: 'Maharashtra',
        ),
        uploadedAt: '2026-09-07T10:00:00.000Z',
        userId: 'usr-admin-01',
      ),
    ];
  }

  @override
  Future<DocumentModel> uploadDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final fileSize = await file.length();
    if (fileSize > 50 * 1024 * 1024) {
      throw const ValidationFailure('File size exceeds the 50 MB limit.');
    }

    final pathLower = file.path.toLowerCase();

    // Check for simulated duplicate test cases
    if (pathLower.contains('duplicate') ||
        _documents.any((d) => d.originalName.toLowerCase() == pathLower.split(RegExp(r'[/\\]')).last.toLowerCase())) {
      throw const ConflictFailure(
        'Duplicate document checksum matched an existing file.',
        isDuplicateDocument: true,
      );
    }

    // Simulate progress callback
    if (onSendProgress != null) {
      onSendProgress((fileSize * 0.5).toInt(), fileSize);
      onSendProgress(fileSize, fileSize);
    }

    final fileName = file.path.split(RegExp(r'[/\\]')).last;
    final extension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'pdf';

    final newDoc = DocumentModel(
      id: 'doc-mock-${DateTime.now().millisecondsSinceEpoch}',
      originalName: fileName,
      filename: '${DateTime.now().millisecondsSinceEpoch}-$fileName',
      mimeType: _inferMimeType(extension),
      fileSize: fileSize,
      fileType: extension,
      hash: 'sha256-${DateTime.now().millisecondsSinceEpoch}',
      category: 'General Operations',
      classification: 'internal',
      status: 'queued',
      totalPages: 1,
      uploadedAt: DateTime.now().toUtc().toIso8601String(),
      userId: 'usr-current',
    );

    _documents.insert(0, newDoc);

    _pagesMap[newDoc.id] = [
      DocumentPageModel(
        id: 'page-${newDoc.id}-1',
        documentId: newDoc.id,
        pageNumber: 1,
        text: 'Document Ingestion Queued.\nFile: $fileName\nSize: $fileSize bytes.',
      ),
    ];

    _statusMap[newDoc.id] = DocumentStatusModel(
      id: 'job-${newDoc.id}',
      documentId: newDoc.id,
      status: 'queued',
      progress: 0,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );

    return newDoc;
  }

  String _inferMimeType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'csv':
        return 'text/csv';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'tiff':
        return 'image/tiff';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Future<DocumentListResponse> getDocuments(DocumentFilter filter) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    var list = List<DocumentModel>.from(_documents);

    // Apply Search
    if (filter.search != null && filter.search!.trim().isNotEmpty) {
      final q = filter.search!.trim().toLowerCase();
      list = list.where((d) => d.originalName.toLowerCase().contains(q)).toList();
    }

    // Apply Type
    if (filter.type != null && filter.type!.isNotEmpty) {
      list = list.where((d) => d.fileType.toLowerCase() == filter.type!.toLowerCase()).toList();
    }

    // Apply Status
    if (filter.status != null && filter.status!.isNotEmpty) {
      list = list.where((d) => d.status.toLowerCase() == filter.status!.toLowerCase()).toList();
    }

    // Apply Category
    if (filter.category != null && filter.category!.isNotEmpty) {
      list = list.where((d) => d.category.toLowerCase() == filter.category!.toLowerCase()).toList();
    }

    // Apply Classification
    if (filter.classification != null && filter.classification!.isNotEmpty) {
      list = list
          .where((d) => d.classification.toLowerCase() == filter.classification!.toLowerCase())
          .toList();
    }

    final total = list.length;
    final totalPages = (total / filter.limit).ceil().clamp(1, 99999);
    final startIndex = ((filter.page - 1) * filter.limit).clamp(0, total);
    final endIndex = (startIndex + filter.limit).clamp(0, total);
    final paginated = list.sublist(startIndex, endIndex);

    return DocumentListResponse(
      documents: paginated,
      meta: DocumentPaginationMeta(
        total: total,
        page: filter.page,
        limit: filter.limit,
        pages: totalPages,
      ),
    );
  }

  @override
  Future<DocumentDetailModel> getDocumentDetail(String id) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final doc = _documents.firstWhere(
      (d) => d.id == id,
      orElse: () => throw NotFoundFailure('Document with id $id not found.'),
    );

    final pages = _pagesMap[id] ??
        [
          DocumentPageModel(
            id: 'page-$id-1',
            documentId: id,
            pageNumber: 1,
            text: 'Extracted content for ${doc.originalName}',
          ),
        ];

    return DocumentDetailModel(document: doc, pages: pages);
  }

  @override
  Future<DocumentMetadataModel> getDocumentMetadata(String id) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final doc = _documents.firstWhere(
      (d) => d.id == id,
      orElse: () => throw NotFoundFailure('Document with id $id not found.'),
    );

    return DocumentMetadataModel(
      id: doc.id,
      originalName: doc.originalName,
      filename: doc.filename,
      mimeType: doc.mimeType,
      fileType: doc.fileType,
      fileSize: doc.fileSize,
      hash: doc.hash,
      status: doc.status,
      category: doc.category,
      classification: doc.classification,
      totalPages: doc.totalPages,
      entities: doc.entities ?? [],
      topicIds: doc.topicIds ?? [],
      similarDocuments: const [],
      gisMetadata: doc.gisMetadata,
      retentionDate: '2031-09-07T00:00:00.000Z',
      uploadedAt: doc.uploadedAt,
      processedAt: '2026-09-06T10:01:15.000Z',
    );
  }

  @override
  Future<DocumentModel> updateDocumentMetadata(
    String id,
    DocumentMetadataUpdateRequest request,
  ) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final index = _documents.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw NotFoundFailure('Document with id $id not found.');
    }

    final old = _documents[index];
    final updated = old.copyWith(
      category: request.category ?? old.category,
      classification: request.classification ?? old.classification,
      gisMetadata: request.gisMetadata ?? old.gisMetadata,
    );

    _documents[index] = updated;
    return updated;
  }

  @override
  Future<DocumentStatusModel> getDocumentStatus(String id) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final status = _statusMap[id];
    if (status != null) return status;

    final doc = _documents.firstWhere(
      (d) => d.id == id,
      orElse: () => throw NotFoundFailure('Job status for $id not found.'),
    );

    return DocumentStatusModel(
      id: 'job-$id',
      documentId: id,
      status: doc.status,
      progress: doc.status == 'completed' ? 100 : 50,
      createdAt: doc.uploadedAt,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<DocumentModel> reprocessDocument(String id) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final index = _documents.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw NotFoundFailure('Document with id $id not found.');
    }

    final old = _documents[index];
    final updated = old.copyWith(status: 'processing');
    _documents[index] = updated;

    _statusMap[id] = DocumentStatusModel(
      id: 'job-$id',
      documentId: id,
      status: 'processing',
      progress: 30,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );

    return updated;
  }

  @override
  Future<DocumentModel> retryDocument(String id) async {
    return reprocessDocument(id);
  }

  @override
  Future<String> deleteDocument(String id) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final index = _documents.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw NotFoundFailure('Document with id $id not found.');
    }

    _documents.removeAt(index);
    _pagesMap.remove(id);
    _statusMap.remove(id);
    return id;
  }

  @override
  Future<String> downloadDocument(String id, String savePath) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final file = File(savePath);
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('Dummy binary content for document $id');
    }
    return savePath;
  }
}
