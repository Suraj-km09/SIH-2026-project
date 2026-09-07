/// Models for Analytics & Production Variance module (Module 16).
/// Conforms strictly to OpenAPI 3.0.3 specification & API_DOCUMENTATION.md.
library;

class AnalyticsFilter {
  final String? document;
  final String? mine;
  final String? subsidiary;
  final String? period;
  final String? subject;

  const AnalyticsFilter({
    this.document,
    this.mine,
    this.subsidiary,
    this.period,
    this.subject,
  });

  bool get isEmpty =>
      document == null &&
      mine == null &&
      subsidiary == null &&
      period == null &&
      subject == null;

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (document != null && document!.isNotEmpty) params['document'] = document;
    if (mine != null && mine!.isNotEmpty) params['mine'] = mine;
    if (subsidiary != null && subsidiary!.isNotEmpty) params['subsidiary'] = subsidiary;
    if (period != null && period!.isNotEmpty) params['period'] = period;
    if (subject != null && subject!.isNotEmpty) params['subject'] = subject;
    return params;
  }

  AnalyticsFilter copyWith({
    String? document,
    String? mine,
    String? subsidiary,
    String? period,
    String? subject,
    bool clearMine = false,
    bool clearSubsidiary = false,
    bool clearPeriod = false,
  }) {
    return AnalyticsFilter(
      document: document ?? this.document,
      mine: clearMine ? null : (mine ?? this.mine),
      subsidiary: clearSubsidiary ? null : (subsidiary ?? this.subsidiary),
      period: clearPeriod ? null : (period ?? this.period),
      subject: subject ?? this.subject,
    );
  }
}

class AnalyticsOverviewModel {
  final double totalProduction;
  final double totalDispatch;
  final double netGap;
  final double productionTargetAchievement;
  final List<MineProductionModel> topProducingMines;

  const AnalyticsOverviewModel({
    this.totalProduction = 0.0,
    this.totalDispatch = 0.0,
    this.netGap = 0.0,
    this.productionTargetAchievement = 0.0,
    this.topProducingMines = const [],
  });

  factory AnalyticsOverviewModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverviewModel(
      totalProduction: (json['totalProduction'] as num?)?.toDouble() ?? 0.0,
      totalDispatch: (json['totalDispatch'] as num?)?.toDouble() ?? 0.0,
      netGap: (json['netGap'] as num?)?.toDouble() ?? 0.0,
      productionTargetAchievement:
          (json['productionTargetAchievement'] as num?)?.toDouble() ?? 0.0,
      topProducingMines: (json['topProducingMines'] as List<dynamic>?)
              ?.map((e) => MineProductionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'totalProduction': totalProduction,
        'totalDispatch': totalDispatch,
        'netGap': netGap,
        'productionTargetAchievement': productionTargetAchievement,
        'topProducingMines': topProducingMines.map((e) => e.toJson()).toList(),
      };
}

class AnalyticsKpisModel {
  final int totalRecords;
  final double averageConfidence;
  final int verifiedRecords;
  final double targetAchievementPct;

  const AnalyticsKpisModel({
    this.totalRecords = 0,
    this.averageConfidence = 0.0,
    this.verifiedRecords = 0,
    this.targetAchievementPct = 0.0,
  });

  factory AnalyticsKpisModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsKpisModel(
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      averageConfidence: (json['averageConfidence'] as num?)?.toDouble() ?? 0.0,
      verifiedRecords: (json['verifiedRecords'] as num?)?.toInt() ?? 0,
      targetAchievementPct:
          (json['targetAchievementPct'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalRecords': totalRecords,
        'averageConfidence': averageConfidence,
        'verifiedRecords': verifiedRecords,
        'targetAchievementPct': targetAchievementPct,
      };
}

class MineProductionModel {
  final String mine;
  final double production;

  const MineProductionModel({
    required this.mine,
    required this.production,
  });

  factory MineProductionModel.fromJson(Map<String, dynamic> json) {
    return MineProductionModel(
      mine: json['mine'] as String? ?? 'Unknown Mine',
      production: (json['production'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'mine': mine,
        'production': production,
      };
}

class SubsidiaryProductionModel {
  final String subsidiary;
  final double production;

  const SubsidiaryProductionModel({
    required this.subsidiary,
    required this.production,
  });

  factory SubsidiaryProductionModel.fromJson(Map<String, dynamic> json) {
    return SubsidiaryProductionModel(
      subsidiary: json['subsidiary'] as String? ?? 'Unknown Subsidiary',
      production: (json['production'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'subsidiary': subsidiary,
        'production': production,
      };
}

class PeriodProductionModel {
  final String period;
  final double production;

  const PeriodProductionModel({
    required this.period,
    required this.production,
  });

  factory PeriodProductionModel.fromJson(Map<String, dynamic> json) {
    return PeriodProductionModel(
      period: json['period'] as String? ?? '',
      production: (json['production'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'production': production,
      };
}

class ProductionAnalyticsModel {
  final List<MineProductionModel> byMine;
  final List<SubsidiaryProductionModel> bySubsidiary;
  final List<PeriodProductionModel> byPeriod;

  const ProductionAnalyticsModel({
    this.byMine = const [],
    this.bySubsidiary = const [],
    this.byPeriod = const [],
  });

  factory ProductionAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return ProductionAnalyticsModel(
      byMine: (json['byMine'] as List<dynamic>?)
              ?.map((e) => MineProductionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      bySubsidiary: (json['bySubsidiary'] as List<dynamic>?)
              ?.map((e) =>
                  SubsidiaryProductionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      byPeriod: (json['byPeriod'] as List<dynamic>?)
              ?.map((e) =>
                  PeriodProductionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'byMine': byMine.map((e) => e.toJson()).toList(),
        'bySubsidiary': bySubsidiary.map((e) => e.toJson()).toList(),
        'byPeriod': byPeriod.map((e) => e.toJson()).toList(),
      };
}

class MineDispatchModel {
  final String mine;
  final double dispatch;

  const MineDispatchModel({
    required this.mine,
    required this.dispatch,
  });

  factory MineDispatchModel.fromJson(Map<String, dynamic> json) {
    return MineDispatchModel(
      mine: json['mine'] as String? ?? 'Unknown Mine',
      dispatch: (json['dispatch'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'mine': mine,
        'dispatch': dispatch,
      };
}

class SubsidiaryDispatchModel {
  final String subsidiary;
  final double dispatch;

  const SubsidiaryDispatchModel({
    required this.subsidiary,
    required this.dispatch,
  });

  factory SubsidiaryDispatchModel.fromJson(Map<String, dynamic> json) {
    return SubsidiaryDispatchModel(
      subsidiary: json['subsidiary'] as String? ?? 'Unknown Subsidiary',
      dispatch: (json['dispatch'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'subsidiary': subsidiary,
        'dispatch': dispatch,
      };
}

class PeriodDispatchModel {
  final String period;
  final double dispatch;

  const PeriodDispatchModel({
    required this.period,
    required this.dispatch,
  });

  factory PeriodDispatchModel.fromJson(Map<String, dynamic> json) {
    return PeriodDispatchModel(
      period: json['period'] as String? ?? '',
      dispatch: (json['dispatch'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'dispatch': dispatch,
      };
}

class DispatchAnalyticsModel {
  final List<MineDispatchModel> byMine;
  final List<SubsidiaryDispatchModel> bySubsidiary;
  final List<PeriodDispatchModel> byPeriod;

  const DispatchAnalyticsModel({
    this.byMine = const [],
    this.bySubsidiary = const [],
    this.byPeriod = const [],
  });

  factory DispatchAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return DispatchAnalyticsModel(
      byMine: (json['byMine'] as List<dynamic>?)
              ?.map((e) => MineDispatchModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      bySubsidiary: (json['bySubsidiary'] as List<dynamic>?)
              ?.map((e) =>
                  SubsidiaryDispatchModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      byPeriod: (json['byPeriod'] as List<dynamic>?)
              ?.map((e) => PeriodDispatchModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'byMine': byMine.map((e) => e.toJson()).toList(),
        'bySubsidiary': bySubsidiary.map((e) => e.toJson()).toList(),
        'byPeriod': byPeriod.map((e) => e.toJson()).toList(),
      };
}

class TrendItemModel {
  final String period;
  final double production;
  final double dispatch;

  const TrendItemModel({
    required this.period,
    required this.production,
    required this.dispatch,
  });

  factory TrendItemModel.fromJson(Map<String, dynamic> json) {
    return TrendItemModel(
      period: json['period'] as String? ?? '',
      production: (json['production'] as num?)?.toDouble() ?? 0.0,
      dispatch: (json['dispatch'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'production': production,
        'dispatch': dispatch,
      };
}

class VarianceItemModel {
  final String mine;
  final String parameter;
  final double target;
  final double actual;
  final double variance;
  final double variancePct;

  const VarianceItemModel({
    required this.mine,
    required this.parameter,
    required this.target,
    required this.actual,
    required this.variance,
    required this.variancePct,
  });

  bool get isPositive => variance >= 0;

  factory VarianceItemModel.fromJson(Map<String, dynamic> json) {
    return VarianceItemModel(
      mine: json['mine'] as String? ?? 'Unknown Mine',
      parameter: json['parameter'] as String? ?? 'Production',
      target: (json['target'] as num?)?.toDouble() ?? 0.0,
      actual: (json['actual'] as num?)?.toDouble() ?? 0.0,
      variance: (json['variance'] as num?)?.toDouble() ?? 0.0,
      variancePct: (json['variancePct'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'mine': mine,
        'parameter': parameter,
        'target': target,
        'actual': actual,
        'variance': variance,
        'variancePct': variancePct,
      };
}

class AnomalyItemModel {
  final String type;
  final String mine;
  final String details;
  final String severity; // 'critical' | 'warning' | 'info'

  const AnomalyItemModel({
    required this.type,
    required this.mine,
    required this.details,
    required this.severity,
  });

  bool get isCritical => severity.toLowerCase() == 'critical';
  bool get isWarning => severity.toLowerCase() == 'warning';
  bool get isInfo => severity.toLowerCase() == 'info';

  factory AnomalyItemModel.fromJson(Map<String, dynamic> json) {
    return AnomalyItemModel(
      type: json['type'] as String? ?? 'ANOMALY',
      mine: json['mine'] as String? ?? 'Unknown Mine',
      details: json['details'] as String? ?? '',
      severity: json['severity'] as String? ?? 'warning',
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'mine': mine,
        'details': details,
        'severity': severity,
      };
}
