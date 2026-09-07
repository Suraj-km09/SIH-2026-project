import 'dart:convert';
import '../models/report_model.dart';
import '../network/report_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for Statutory Mining Reports operations.
abstract class ReportRepository {
  Future<ReportModel> generateReport(ReportGenerateRequest request);
  Future<ReportsResponse> getReports(ReportFilter filter);
  Future<ReportModel> getReportById(String id);
  Future<ReportModel> updateReport(String id, ReportUpdateRequest request);
  Future<bool> deleteReport(String id);
  Future<ReportModel> submitForReview(String id);
  Future<ReportModel> approveReport(String id);
  Future<ReportModel> rejectReport(String id, String reason);
  Future<List<CitedEvidenceModel>> getReportEvidence(String id);
  Future<List<ReportVersionModel>> getReportVersionHistory(String id);
  Future<List<ReportChangeModel>> getReportChanges(String id);
  Future<dynamic> exportReport(String id, String format);
}

/// Concrete implementation delegating to ReportRemoteDataSource or Mock.
class ReportRepositoryImpl extends BaseRepository implements ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;
  final ReportRepository? mockRepository;

  ReportRepositoryImpl({
    ReportRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? ReportRemoteDataSource();

  @override
  Future<ReportModel> generateReport(ReportGenerateRequest request) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.generateReport(request);
    }
    return execute(() => _remoteDataSource.generateReport(request));
  }

  @override
  Future<ReportsResponse> getReports(ReportFilter filter) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getReports(filter);
    }
    return execute(() => _remoteDataSource.getReports(filter));
  }

  @override
  Future<ReportModel> getReportById(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getReportById(id);
    }
    return execute(() => _remoteDataSource.getReportById(id));
  }

  @override
  Future<ReportModel> updateReport(String id, ReportUpdateRequest request) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.updateReport(id, request);
    }
    return execute(() => _remoteDataSource.updateReport(id, request));
  }

  @override
  Future<bool> deleteReport(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.deleteReport(id);
    }
    return execute(() => _remoteDataSource.deleteReport(id));
  }

  @override
  Future<ReportModel> submitForReview(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.submitForReview(id);
    }
    return execute(() => _remoteDataSource.submitForReview(id));
  }

  @override
  Future<ReportModel> approveReport(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.approveReport(id);
    }
    return execute(() => _remoteDataSource.approveReport(id));
  }

  @override
  Future<ReportModel> rejectReport(String id, String reason) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.rejectReport(id, reason);
    }
    return execute(() => _remoteDataSource.rejectReport(id, reason));
  }

  @override
  Future<List<CitedEvidenceModel>> getReportEvidence(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getReportEvidence(id);
    }
    return execute(() => _remoteDataSource.getReportEvidence(id));
  }

  @override
  Future<List<ReportVersionModel>> getReportVersionHistory(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getReportVersionHistory(id);
    }
    return execute(() => _remoteDataSource.getReportVersionHistory(id));
  }

  @override
  Future<List<ReportChangeModel>> getReportChanges(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getReportChanges(id);
    }
    return execute(() => _remoteDataSource.getReportChanges(id));
  }

  @override
  Future<dynamic> exportReport(String id, String format) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.exportReport(id, format);
    }
    return execute(() => _remoteDataSource.exportReport(id, format));
  }
}

/// Standalone mock repository providing realistic statutory mining reports.
class MockReportRepository implements ReportRepository {
  final List<ReportModel> _reports = [];
  final Map<String, List<CitedEvidenceModel>> _evidence = {};
  final Map<String, List<ReportVersionModel>> _versions = {};
  final Map<String, List<ReportChangeModel>> _changes = {};

  MockReportRepository() {
    _seedData();
  }

  void _seedData() {
    _reports.addAll([
      const ReportModel(
        id: 'rep_001',
        title: 'Monthly Statutory Production Summary - Gevra OCP (May 2024)',
        type: 'production_summary',
        status: 'approved',
        content: '''# Monthly Statutory Production Summary: Gevra OCP
**Reporting Period:** May 2024  
**Mine Authority:** South Eastern Coalfields Limited (SECL)  
**Classification:** Confidential - Statutory DGMS & Ministry of Coal  

## 1. Executive Summary
During the operational month of May 2024, Gevra Open Cast Project maintained sustained mineral extraction and composite overburden removal in strict alignment with annual target baselines.

### Key Mining Parameters
- **Run-of-Mine (ROM) Coal Production:** 124,500 Metric Tonnes (Target: 120,000 MT, Variance: +3.75%)
- **Overburden (OB) Removal:** 452,000 Cubic Meters (Target: 450,000 m3, Variance: +0.44%)
- **Actual Stripping Ratio:** 3.63 m3/t (Approved Baseline: 3.75 m3/t)
- **Heavy Earth Moving Machinery (HEMM) Availability:** 88.4%
- **Weighbridge Dispatch Efficiency:** 99.2%

## 2. Dispatch & Logistics
Coal evacuation was executed through multi-modal dispatch channels:
1. **Rail Logistics (Merry-Go-Round & IR Rakes):** 84,200 MT (67.6%)
2. **Road Transport via Automated Loading Chutes:** 28,100 MT (22.6%)
3. **Belt Conveyor to Pithead Thermal Power Plant:** 12,200 MT (9.8%)

## 3. Statutory Environmental & Safety Compliance
- Continuous Ambient Air Quality Monitoring (CAAQM) recorded PM10 averages of 78.4 µg/m3, well within NAAQS statutory thresholds (100 µg/m3).
- Zero reportable loss-time injuries (LTI) were recorded across all 3 operating shifts.
- Water spraying suppression coverage reached 98.6% of active haul roads.

## 4. Certification & Sign-off
This statutory production summary has been reviewed against electronic weighbridge logs and validated by the General Manager (Mining), SECL Gevra Area.''',
        fileUrl: 'https://cdn.mineintel.ai/reports/rep_001.pdf',
        generatedBy: 'analyst_sharma',
        reviewerId: 'reviewer_patel',
        reviewerComments: 'All production metrics and safety logs verified against Annexure 4.',
        reviewedAt: '2024-06-02T14:30:00.000Z',
        approvedBy: 'admin',
        approvedAt: '2024-06-03T09:15:00.000Z',
        version: 2,
        confidenceScore: 0.98,
        language: 'en',
        createdAt: '2024-06-01T11:00:00.000Z',
        documentIds: ['doc_001'],
      ),
      const ReportModel(
        id: 'rep_002',
        title: 'Quarterly Overburden & Stripping Ratio Variance - Rajmahal OCP (Q1 2026)',
        type: 'variance_analysis',
        status: 'review',
        content: '''# Quarterly Overburden & Stripping Ratio Variance Analysis
**Project:** Rajmahal Open Cast Project (Eastern Coalfields Limited)  
**Period:** Q1 2026 (January - March 2026)  
**Status:** Pending Maker-Checker Governance Review  

## 1. Operational Overview
Composite excavation across Seams II, III, and IV was subject to seasonal monsoon preparation and overburden bench advancement.

| Parameter | Plan Target | Actual Achieved | Variance (%) |
| :--- | :--- | :--- | :--- |
| ROM Coal Extraction (MT) | 420,000 | 415,200 | -1.14% |
| Composite Overburden (m3) | 1,470,000 | 1,536,240 | +4.51% |
| Operational Stripping Ratio | 3.50 m3/t | 3.70 m3/t | +5.71% |
| Specific Fuel Consumption (L/m3) | 0.82 | 0.79 | -3.66% |

## 2. Variance Justification
The 5.71% increase in stripping ratio is attributed to geological fault zone stabilization in Pit 2 (West Flank), requiring 66,240 m3 of unplanned bench setback to safeguard highwall slope stability.

## 3. Reviewer Instructions
Reviewers must verify survey cross-section volumetric drawings submitted under Annexure C prior to final administrative sign-off.''',
        generatedBy: 'operator_roy',
        version: 1,
        confidenceScore: 0.92,
        language: 'en',
        createdAt: '2026-04-05T08:20:00.000Z',
        documentIds: ['doc_002'],
      ),
      const ReportModel(
        id: 'rep_003',
        title: 'Environmental Safeguards & Water Quality Audit - Dhanbad Region',
        type: 'environmental_safeguards',
        status: 'draft',
        content: '''# Environmental Safeguards & Effluent Discharge Audit
**Region:** Dhanbad Mining Cluster (BCCL)  
**Audit Scope:** Statutory Water Management & Dust Suppression Systems  

## 1. Scope & Methodology
Field inspection of 4 active mine sedimentation sumps, 2 acid mine drainage (AMD) neutralization plants, and 12 peripheral ambient monitoring stations.

## 2. Preliminary Observations (Draft)
- Sump #3 discharge water pH remained stable between 7.2 and 7.6.
- Total Suspended Solids (TSS) at final discharge point: 42 mg/L (Limit: 100 mg/L).
- Solar-powered air quality sensor at North Perimeter requires sensor recalibration.

## 3. Pending Sections
- [ ] Chemical biological oxygen demand (BOD) laboratory results
- [ ] Afforestation and topsoil preservation hectare logs''',
        generatedBy: 'analyst_verma',
        version: 1,
        confidenceScore: 0.89,
        language: 'en',
        createdAt: '2026-07-12T16:45:00.000Z',
        documentIds: ['doc_003'],
      ),
      const ReportModel(
        id: 'rep_004',
        title: 'Statutory Coal Dispatch & Transportation Compliance (April 2026)',
        type: 'compliance_audit',
        status: 'rejected',
        content: '''# Statutory Coal Dispatch & Transportation Compliance Audit
**Status:** Rejected by Reviewer  
**Audit Entity:** Central Coalfields Limited (CCL)  

## 1. Dispatch Summary
Total recorded dispatch of 98,200 MT was processed across 4 in-motion road weighbridges.

## 2. Issues Encountered
Discrepancy observed between electronic Weighbridge Gross-Tare-Net tickets and commercial sales invoices for 14 rakes dispatched to Maithon Power Station.''',
        generatedBy: 'operator_singh',
        reviewerId: 'reviewer_patel',
        reviewerComments: 'Reconciliation required for 14 rakes (approx. 4,200 MT variance) between weighbridge and railway receipt.',
        reviewedAt: '2026-05-04T11:10:00.000Z',
        version: 1,
        confidenceScore: 0.84,
        language: 'en',
        createdAt: '2026-05-01T10:00:00.000Z',
        documentIds: ['doc_001', 'doc_002'],
      ),
    ]);

    _evidence['rep_001'] = [
      const CitedEvidenceModel(
        documentId: 'doc_001',
        documentName: 'Gevra_Monthly_Production_May2024.pdf',
        pageNumber: 2,
        snippet: 'Total raw coal production for Gevra OCP stood at 124,500 MT during May 2024.',
        similarity: 0.98,
      ),
      const CitedEvidenceModel(
        documentId: 'doc_001',
        documentName: 'Gevra_Monthly_Production_May2024.pdf',
        pageNumber: 4,
        snippet: 'Overburden excavation achieved 452,000 cubic meters with stripping ratio of 3.63 m3/t.',
        similarity: 0.95,
      ),
      const CitedEvidenceModel(
        documentId: 'doc_001',
        documentName: 'Gevra_Monthly_Production_May2024.pdf',
        pageNumber: 7,
        snippet: 'Zero reportable injuries were recorded; CAAQM PM10 average was 78.4 µg/m3.',
        similarity: 0.94,
      ),
    ];

    _evidence['rep_002'] = [
      const CitedEvidenceModel(
        documentId: 'doc_002',
        documentName: 'Rajmahal_Q1_2026_Excavation.pdf',
        pageNumber: 3,
        snippet: 'Stripping ratio escalated to 3.70 m3/t due to fault zone bench setback in Pit 2.',
        similarity: 0.92,
      ),
    ];

    _versions['rep_001'] = [
      const ReportVersionModel(
        version: 1,
        title: 'Draft Monthly Statutory Production Summary - Gevra OCP',
        content: '# Draft Production Summary...',
        updatedBy: 'analyst_sharma',
        updatedAt: '2024-06-01T11:00:00.000Z',
        changeSummary: 'Initial RAG generation from verified documents',
      ),
      const ReportVersionModel(
        version: 2,
        title: 'Monthly Statutory Production Summary - Gevra OCP (May 2024)',
        content: '# Final Production Summary...',
        updatedBy: 'analyst_sharma',
        updatedAt: '2024-06-02T10:15:00.000Z',
        changeSummary: 'Added CAAQM ambient air monitoring statistics and HEMM availability',
      ),
    ];

    _changes['rep_001'] = [
      const ReportChangeModel(
        field: 'title',
        oldValue: 'Draft Monthly Statutory Production Summary - Gevra OCP',
        newValue: 'Monthly Statutory Production Summary - Gevra OCP (May 2024)',
        timestamp: '2024-06-02T10:15:00.000Z',
        author: 'analyst_sharma',
      ),
      const ReportChangeModel(
        field: 'status',
        oldValue: 'draft',
        newValue: 'review',
        timestamp: '2024-06-02T10:30:00.000Z',
        author: 'analyst_sharma',
      ),
      const ReportChangeModel(
        field: 'status',
        oldValue: 'review',
        newValue: 'approved',
        timestamp: '2024-06-03T09:15:00.000Z',
        author: 'admin',
      ),
    ];
  }

  @override
  Future<ReportModel> generateReport(ReportGenerateRequest request) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newId = 'rep_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final report = ReportModel(
      id: newId,
      title: request.title,
      type: request.type,
      status: 'draft',
      content: '''# ${request.title}
**Type:** ${request.type.replaceAll('_', ' ').toUpperCase()}  
**Language:** ${request.language.toUpperCase()}  
**Generated:** ${DateTime.now().toIso8601String()}  
**Source Documents:** ${request.documentIds.join(', ')}  

## 1. Overview
Automated synthesis generated from extracted parameters and verified OCR evidence.

### Extracted Highlights
- ROM Mineral Extraction: Verified against linked weighbridge documents.
- Overburden & Excavation: Synthesized from mining survey attachments.
- Safety & Environmental: Within statutory compliance parameters.

## 2. Detailed Findings
Review and verify all parameters prior to submitting for formal administrative review.''',
      generatedBy: 'current_user',
      version: 1,
      confidenceScore: 0.94,
      language: request.language,
      createdAt: DateTime.now().toIso8601String(),
      documentIds: request.documentIds,
    );

    _reports.insert(0, report);
    _evidence[newId] = [
      CitedEvidenceModel(
        documentId: request.documentIds.isNotEmpty ? request.documentIds.first : 'doc_001',
        documentName: 'SourceDocument_Extracted.pdf',
        pageNumber: 1,
        snippet: 'Automated synthesis citation supporting parameters for ${request.title}',
        similarity: 0.95,
      ),
    ];
    _versions[newId] = [
      ReportVersionModel(
        version: 1,
        title: report.title,
        content: report.contentAsString,
        updatedBy: 'current_user',
        updatedAt: DateTime.now().toIso8601String(),
        changeSummary: 'Initial automated generation',
      ),
    ];
    return report;
  }

  @override
  Future<ReportsResponse> getReports(ReportFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var list = List<ReportModel>.from(_reports);

    if (filter.type != null && filter.type!.isNotEmpty && filter.type != 'all') {
      list = list.where((r) => r.type.toLowerCase() == filter.type!.toLowerCase()).toList();
    }
    if (filter.status != null && filter.status!.isNotEmpty && filter.status != 'all') {
      list = list.where((r) => r.status.toLowerCase() == filter.status!.toLowerCase()).toList();
    }

    final total = list.length;
    final pages = (total / filter.limit).ceil().clamp(1, 999);
    final startIndex = ((filter.page - 1) * filter.limit).clamp(0, total);
    final endIndex = (startIndex + filter.limit).clamp(0, total);
    final paginated = list.sublist(startIndex, endIndex);

    return ReportsResponse(
      reports: paginated,
      meta: ReportPaginationMeta(
        total: total,
        page: filter.page,
        limit: filter.limit,
        pages: pages,
      ),
    );
  }

  @override
  Future<ReportModel> getReportById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _reports.indexWhere((r) => r.id == id);
    if (index >= 0) {
      return _reports[index];
    }
    throw Exception('Report with ID $id not found.');
  }

  @override
  Future<ReportModel> updateReport(String id, ReportUpdateRequest request) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _reports.indexWhere((r) => r.id == id);
    if (index < 0) throw Exception('Report $id not found');

    final existing = _reports[index];
    final updated = existing.copyWith(
      title: request.title ?? existing.title,
      content: request.content ?? existing.content,
      type: request.type ?? existing.type,
      version: existing.version + 1,
    );

    _reports[index] = updated;

    final historyList = _versions[id] ?? [];
    historyList.insert(
      0,
      ReportVersionModel(
        version: updated.version,
        title: updated.title,
        content: updated.contentAsString,
        updatedBy: 'current_user',
        updatedAt: DateTime.now().toIso8601String(),
        changeSummary: 'Manual content edit via report editor',
      ),
    );
    _versions[id] = historyList;

    return updated;
  }

  @override
  Future<bool> deleteReport(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final count = _reports.length;
    _reports.removeWhere((r) => r.id == id);
    _evidence.remove(id);
    _versions.remove(id);
    _changes.remove(id);
    return _reports.length < count;
  }

  @override
  Future<ReportModel> submitForReview(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _reports.indexWhere((r) => r.id == id);
    if (index < 0) throw Exception('Report $id not found');

    final updated = _reports[index].copyWith(status: 'review');
    _reports[index] = updated;

    final changeList = _changes[id] ?? [];
    changeList.add(
      ReportChangeModel(
        field: 'status',
        oldValue: 'draft',
        newValue: 'review',
        timestamp: DateTime.now().toIso8601String(),
        author: 'current_user',
      ),
    );
    _changes[id] = changeList;

    return updated;
  }

  @override
  Future<ReportModel> approveReport(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _reports.indexWhere((r) => r.id == id);
    if (index < 0) throw Exception('Report $id not found');

    final now = DateTime.now().toIso8601String();
    final updated = _reports[index].copyWith(
      status: 'approved',
      approvedBy: 'admin',
      approvedAt: now,
    );
    _reports[index] = updated;

    final changeList = _changes[id] ?? [];
    changeList.add(
      ReportChangeModel(
        field: 'status',
        oldValue: 'review',
        newValue: 'approved',
        timestamp: now,
        author: 'admin',
      ),
    );
    _changes[id] = changeList;

    return updated;
  }

  @override
  Future<ReportModel> rejectReport(String id, String reason) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _reports.indexWhere((r) => r.id == id);
    if (index < 0) throw Exception('Report $id not found');

    final now = DateTime.now().toIso8601String();
    final updated = _reports[index].copyWith(
      status: 'rejected',
      reviewerId: 'reviewer',
      reviewerComments: reason,
      reviewedAt: now,
    );
    _reports[index] = updated;

    final changeList = _changes[id] ?? [];
    changeList.add(
      ReportChangeModel(
        field: 'status',
        oldValue: 'review',
        newValue: 'rejected',
        timestamp: now,
        author: 'reviewer',
      ),
    );
    _changes[id] = changeList;

    return updated;
  }

  @override
  Future<List<CitedEvidenceModel>> getReportEvidence(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _evidence[id] ?? [];
  }

  @override
  Future<List<ReportVersionModel>> getReportVersionHistory(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _versions[id] ?? [];
  }

  @override
  Future<List<ReportChangeModel>> getReportChanges(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _changes[id] ?? [];
  }

  @override
  Future<dynamic> exportReport(String id, String format) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final report = await getReportById(id);
    final fmt = format.toLowerCase().replaceAll('.', '');

    switch (fmt) {
      case 'json':
        return jsonEncode(report.toJson());
      case 'csv':
        return 'Field,Value\nID,${report.id}\nTitle,"${report.title}"\nStatus,${report.status}\nVersion,${report.version}\nType,${report.type}\nGeneratedBy,${report.generatedBy ?? ''}\nApprovedBy,${report.approvedBy ?? ''}\nConfidence,${report.confidenceScore ?? 0.0}\n';
      case 'docx':
      case 'pdf':
      default:
        // Mock binary simulated byte stream
        final dummyString = '%PDF-1.4 Mock Export for Report ${report.id} - ${report.title}\nContent:\n${report.contentAsString}';
        return utf8.encode(dummyString);
    }
  }
}
