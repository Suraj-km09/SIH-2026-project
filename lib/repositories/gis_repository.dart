import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document_model.dart';
import '../models/gis_model.dart';
import '../network/gis_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for GIS and Spatial Mapping Integration.
abstract class GisRepository {
  Future<List<GisDocumentRecord>> getGisRecords();
}

/// Concrete implementation delegating to live API or fallback Mock.
class GisRepositoryImpl extends BaseRepository implements GisRepository {
  final GisRemoteDataSource _remoteDataSource;
  final GisRepository? mockRepository;

  GisRepositoryImpl({
    GisRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? GisRemoteDataSource();

  @override
  Future<List<GisDocumentRecord>> getGisRecords() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getGisRecords();
    }
    return execute(() => _remoteDataSource.getGisRecords());
  }
}

/// High-fidelity offline Mock GIS Repository containing actual Indian coalfield coordinates.
class MockGisRepository implements GisRepository {
  final Duration delay;

  MockGisRepository({this.delay = const Duration(milliseconds: 150)});

  @override
  Future<List<GisDocumentRecord>> getGisRecords() async {
    await Future.delayed(delay);
    return const [
      GisDocumentRecord(
        id: 'doc-001',
        originalName: 'ECL_Rajmahal_Production_Report_Aug_2026.pdf',
        category: 'Production Report',
        status: 'completed',
        gisMetadata: GisMetadata(
          latitude: 25.0450,
          longitude: 87.2512,
          elevation: 112.5,
          mineCode: 'ECL-04',
          region: 'Jharkhand',
        ),
      ),
      GisDocumentRecord(
        id: 'doc-002',
        originalName: 'BCCL_Dhanbad_Safety_Audit_Q2_2026.docx',
        category: 'Safety & DGMS Directive',
        status: 'completed',
        gisMetadata: GisMetadata(
          latitude: 23.7957,
          longitude: 86.4304,
          elevation: 220.0,
          mineCode: 'BCCL-09',
          region: 'Dhanbad',
        ),
      ),
      GisDocumentRecord(
        id: 'doc-003',
        originalName: 'SECL_Korba_Dispatch_Weighbridge_Logs.xlsx',
        category: 'Weighbridge Dispatch',
        status: 'processing',
        gisMetadata: GisMetadata(
          latitude: 22.3595,
          longitude: 82.7501,
          elevation: 304.0,
          mineCode: 'SECL-12',
          region: 'Chhattisgarh',
        ),
      ),
      GisDocumentRecord(
        id: 'doc-004',
        originalName: 'CMPDI_Exploration_DrillCore_Lithology.csv',
        category: 'Geological Log',
        status: 'completed',
        gisMetadata: GisMetadata(
          latitude: 23.6345,
          longitude: 85.3789,
          elevation: 650.0,
          mineCode: 'CMPDI-01',
          region: 'Ranchi',
        ),
      ),
      GisDocumentRecord(
        id: 'doc-005',
        originalName: 'WCL_Nagpur_Air_Quality_Compliance_July.pdf',
        category: 'Environmental Audit',
        status: 'completed',
        gisMetadata: GisMetadata(
          latitude: 21.1458,
          longitude: 79.0882,
          elevation: 310.0,
          mineCode: 'WCL-03',
          region: 'Maharashtra',
        ),
      ),
    ];
  }
}

/// Global provider for GisRepository.
final gisRepositoryProvider = Provider<GisRepository>((ref) {
  return GisRepositoryImpl(
    mockRepository: MockGisRepository(),
  );
});
