/// Ingestion Job Telemetry model matching backend ProcessingJob schema.
class ProcessingJobModel {
  final String id;
  final String documentId;
  final String status;
  final int progress; // 0 to 100
  final String? currentStep;
  final List<JobStep> steps;
  final String? startedAt;
  final String? completedAt;
  final String? error;

  const ProcessingJobModel({
    required this.id,
    required this.documentId,
    required this.status,
    required this.progress,
    this.currentStep,
    this.steps = const [],
    this.startedAt,
    this.completedAt,
    this.error,
  });

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing' || status == 'queued';

  factory ProcessingJobModel.fromJson(Map<String, dynamic> json) {
    return ProcessingJobModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      documentId: json['documentId'] as String? ?? '',
      status: json['status'] as String? ?? 'queued',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      currentStep: json['currentStep'] as String?,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => JobStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      startedAt: json['startedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'documentId': documentId,
        'status': status,
        'progress': progress,
        'currentStep': currentStep,
        'steps': steps.map((s) => s.toJson()).toList(),
        'startedAt': startedAt,
        'completedAt': completedAt,
        'error': error,
      };
}

/// Individual step in the 4-stage ingestion pipeline.
class JobStep {
  final String name;
  final String status; // pending, processing, completed, failed

  const JobStep({
    required this.name,
    required this.status,
  });

  bool get isCompleted => status == 'completed';

  factory JobStep.fromJson(Map<String, dynamic> json) {
    return JobStep(
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'status': status,
      };
}
