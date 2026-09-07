/// Feature Modules Directory for MineIntel AI.
/// Each feature module will incrementally house its presentation, logic, and views
/// in subsequent development phases:
///
/// - auth/ (Login, Register, Profile, Role Routing)
/// - dashboard/ (Executive Dashboard & KPIs)
/// - command_centre/ (Ingestion pipeline & status)
/// - documents/ (Upload, Ingestion Telemetry, Viewer)
/// - extraction/ (Tabular extraction & HITL Review)
/// - validation/ (Rule engine & Quality scoring)
/// - reports/ (Statutory summaries & Multi-format export)
/// - reviews/ (Maker-Checker approval queue)
/// - ai_assistant/ (RAG conversational intelligence)
/// - knowledge_base/ (Vector indexing & Semantic search)
/// - analytics/ (Variance, stripping ratio, anomalies)
/// - topics/ (Taxonomy discovery & co-occurrence graphs)
/// - agents/ (Multi-agent compliance orchestrator)
/// - gis/ (Geospatial interactive mining map)
/// - audit/ (Immutable provenance & CSV export)
/// - notifications/ (In-app alerts)
/// - settings/ (Language, theme, base URL overrides)
/// - admin/ (User governance & platform health)
/// - help/ (Documentation FAQs & search)
class FeatureManifest {
  FeatureManifest._();

  static const List<String> allFeatures = [
    'auth',
    'dashboard',
    'command_centre',
    'documents',
    'extraction',
    'validation',
    'reports',
    'reviews',
    'ai_assistant',
    'knowledge_base',
    'analytics',
    'topics',
    'agents',
    'gis',
    'audit',
    'notifications',
    'settings',
    'admin',
    'help',
  ];
}
