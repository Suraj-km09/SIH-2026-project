import 'document_model.dart';

/// Represents a geospatial document record returned by `GET /integration/gis`.
/// Contains strictly real coordinate metadata (latitude, longitude, elevation, mineCode, region).
class GisDocumentRecord {
  final String id;
  final String originalName;
  final String category;
  final String status;
  final GisMetadata? gisMetadata;

  const GisDocumentRecord({
    required this.id,
    required this.originalName,
    required this.category,
    required this.status,
    this.gisMetadata,
  });

  factory GisDocumentRecord.fromJson(Map<String, dynamic> json) {
    return GisDocumentRecord(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      originalName: json['originalName'] as String? ?? 'Untitled Document',
      category: json['category'] as String? ?? 'Operational',
      status: json['status'] as String? ?? 'completed',
      gisMetadata: json['gisMetadata'] != null
          ? GisMetadata.fromJson(json['gisMetadata'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalName': originalName,
        'category': category,
        'status': status,
        if (gisMetadata != null) 'gisMetadata': gisMetadata!.toJson(),
      };

  /// Helper getters
  double? get latitude => gisMetadata?.latitude;
  double? get longitude => gisMetadata?.longitude;
  double? get elevation => gisMetadata?.elevation;
  String? get mineCode => gisMetadata?.mineCode;
  String? get region => gisMetadata?.region;

  bool get hasValidCoordinates => latitude != null && longitude != null;
}
