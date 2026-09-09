/// Models for Analytics & Production Variance module (Module 16).
/// Conforms strictly to OpenAPI 3.0.3 specification & API_DOCUMENTATION.md.
library;

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) {
    final cleaned = val.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
  return 0.0;
}

int _parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toInt();
  if (val is String) {
    final cleaned = val.replaceAll(RegExp(r'[^0-9-]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
  return 0;
}

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

class PeriodSummaryModel {
  final String period;
  final double production;
  final double dispatch;
  final double target;
  final double gap;
  final String unit;
  final int recordsCount;

  const PeriodSummaryModel({
    required this.period,
    required this.production,
    required this.dispatch,
    this.target = 0.0,
    this.gap = 0.0,
    this.unit = 'MT',
    this.recordsCount = 0,
  });

  factory PeriodSummaryModel.fromJson(Map<String, dynamic> json) {
    final prod = _parseDouble(json['production'] ?? json['prod']);
    final disp = _parseDouble(json['dispatch'] ?? json['disp']);
    final tgt = _parseDouble(json['target'] ?? json['targetProduction']);
    final g = json['gap'] != null
        ? _parseDouble(json['gap'])
        : (json['productionDispatchGap'] != null
            ? _parseDouble(json['productionDispatchGap'])
            : (prod - disp));

    return PeriodSummaryModel(
      period: (json['period'] ?? json['date'] ?? json['label'] ?? '') as String,
      production: prod,
      dispatch: disp,
      target: tgt,
      gap: g,
      unit: json['unit'] as String? ?? 'MT',
      recordsCount: _parseInt(json['recordsCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'production': production,
        'dispatch': dispatch,
        'target': target,
        'gap': gap,
        'unit': unit,
        'recordsCount': recordsCount,
      };
}

class AnalyticsOverviewModel {
  final double totalProduction;
  final double totalDispatch;
  final double netGap;
  final double productionTargetAchievement;
  final List<MineProductionModel> topProducingMines;
  final List<PeriodSummaryModel> periods;

  const AnalyticsOverviewModel({
    this.totalProduction = 0.0,
    this.totalDispatch = 0.0,
    this.netGap = 0.0,
    this.productionTargetAchievement = 0.0,
    this.topProducingMines = const [],
    this.periods = const [],
  });

  factory AnalyticsOverviewModel.fromJson(Map<String, dynamic> json) {
    final prod = _parseDouble(
      json['totalProduction'] ?? json['production'],
    );
    final disp = _parseDouble(
      json['totalDispatch'] ?? json['dispatch'],
    );
    final gap = json['netGap'] != null
        ? _parseDouble(json['netGap'])
        : (json['productionDispatchGap'] != null
            ? _parseDouble(json['productionDispatchGap'])
            : (prod - disp));
    final targetAch = _parseDouble(
      json['productionTargetAchievement'] ??
          json['achievementRate'] ??
          json['targetAchievementPct'],
    );
    final minesRaw =
        (json['topProducingMines'] ?? json['mines'] ?? json['topMines'])
            as List<dynamic>?;
    final periodsRaw = json['periods'] as List<dynamic>?;

    return AnalyticsOverviewModel(
      totalProduction: prod,
      totalDispatch: disp,
      netGap: gap,
      productionTargetAchievement: targetAch,
      topProducingMines: minesRaw
              ?.whereType<Map>()
              .map((e) => MineProductionModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      periods: periodsRaw
              ?.whereType<Map>()
              .map((e) => PeriodSummaryModel.fromJson(Map<String, dynamic>.from(e)))
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
        'periods': periods.map((e) => e.toJson()).toList(),
      };
}

class AnalyticsKpisModel {
  final int totalRecords;
  final double averageConfidence;
  final int verifiedRecords;
  final double targetAchievementPct;
  final int totalDocuments;
  final int openIssues;
  final String averageValidationScore;

  const AnalyticsKpisModel({
    this.totalRecords = 0,
    this.averageConfidence = 0.0,
    this.verifiedRecords = 0,
    this.targetAchievementPct = 0.0,
    this.totalDocuments = 0,
    this.openIssues = 0,
    this.averageValidationScore = '',
  });

  factory AnalyticsKpisModel.fromJson(Map<String, dynamic> json) {
    final totalRec = _parseInt(json['totalRecords'] ?? json['records']);
    final openIss = _parseInt(json['openIssues']);
    final verified = json['verifiedRecords'] != null
        ? _parseInt(json['verifiedRecords'])
        : (json['verified'] != null
            ? _parseInt(json['verified'])
            : (openIss > 0 && totalRec >= openIss ? totalRec - openIss : totalRec));

    final rawScore = json['averageValidationScore']?.toString() ?? '';
    final avgConf = json['averageConfidence'] != null
        ? _parseDouble(json['averageConfidence'])
        : (json['avgConfidence'] != null
            ? _parseDouble(json['avgConfidence'])
            : (rawScore.isNotEmpty
                ? _parseDouble(rawScore) / (rawScore.contains('%') ? 100 : 1)
                : 0.0));

    final tgtAch = _parseDouble(
      json['targetAchievementPct'] ??
          json['achievementRate'] ??
          json['targetAchievement'],
    );

    return AnalyticsKpisModel(
      totalRecords: totalRec,
      averageConfidence: avgConf,
      verifiedRecords: verified,
      targetAchievementPct: tgtAch,
      totalDocuments: _parseInt(json['totalDocuments'] ?? json['documents']),
      openIssues: openIss,
      averageValidationScore: rawScore.isNotEmpty
          ? rawScore
          : (avgConf > 0 ? '${(avgConf * 100).toStringAsFixed(0)}%' : ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalRecords': totalRecords,
        'averageConfidence': averageConfidence,
        'verifiedRecords': verifiedRecords,
        'targetAchievementPct': targetAchievementPct,
        'totalDocuments': totalDocuments,
        'openIssues': openIssues,
        'averageValidationScore': averageValidationScore,
      };
}

class MineProductionModel {
  final String mine;
  final double production;
  final int recordsCount;
  final String unit;

  const MineProductionModel({
    required this.mine,
    required this.production,
    this.recordsCount = 0,
    this.unit = 'MT',
  });

  factory MineProductionModel.fromJson(Map<String, dynamic> json) {
    return MineProductionModel(
      mine: json['mine'] as String? ?? 'Unknown Mine',
      production: _parseDouble(json['production']),
      recordsCount: _parseInt(json['recordsCount']),
      unit: json['unit'] as String? ?? 'MT',
    );
  }

  Map<String, dynamic> toJson() => {
        'mine': mine,
        'production': production,
        'recordsCount': recordsCount,
        'unit': unit,
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
      production: _parseDouble(json['production']),
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
      production: _parseDouble(json['production']),
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
              ?.whereType<Map>()
              .map((e) => MineProductionModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      bySubsidiary: (json['bySubsidiary'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) =>
                  SubsidiaryProductionModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      byPeriod: (json['byPeriod'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) =>
                  PeriodProductionModel.fromJson(Map<String, dynamic>.from(e)))
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
  final int recordsCount;
  final String unit;

  const MineDispatchModel({
    required this.mine,
    required this.dispatch,
    this.recordsCount = 0,
    this.unit = 'MT',
  });

  factory MineDispatchModel.fromJson(Map<String, dynamic> json) {
    return MineDispatchModel(
      mine: json['mine'] as String? ?? 'Unknown Mine',
      dispatch: _parseDouble(json['dispatch']),
      recordsCount: _parseInt(json['recordsCount']),
      unit: json['unit'] as String? ?? 'MT',
    );
  }

  Map<String, dynamic> toJson() => {
        'mine': mine,
        'dispatch': dispatch,
        'recordsCount': recordsCount,
        'unit': unit,
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
      dispatch: _parseDouble(json['dispatch']),
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
      dispatch: _parseDouble(json['dispatch']),
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
              ?.whereType<Map>()
              .map((e) => MineDispatchModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      bySubsidiary: (json['bySubsidiary'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) =>
                  SubsidiaryDispatchModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      byPeriod: (json['byPeriod'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => PeriodDispatchModel.fromJson(Map<String, dynamic>.from(e)))
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
  final String? parameter;
  final String? mineName;
  final String? subsidiary;
  final String? unit;

  const TrendItemModel({
    required this.period,
    required this.production,
    required this.dispatch,
    this.parameter,
    this.mineName,
    this.subsidiary,
    this.unit,
  });

  factory TrendItemModel.fromJson(Map<String, dynamic> json) {
    final periodStr = (json['period'] ?? json['date'] ?? json['label'] ?? json['month'])
            ?.toString() ??
        '';
    final param = json['parameter']?.toString();
    final val = _parseDouble(json['value']);
    double prod = _parseDouble(json['production'] ?? json['prod']);
    double disp = _parseDouble(json['dispatch'] ?? json['disp'] ?? json['target']);

    // If individual extraction record from /analytics/trends
    if (prod == 0.0 && disp == 0.0 && val > 0) {
      if (param != null && param.toLowerCase().contains('dispatch')) {
        disp = val;
      } else {
        prod = val;
      }
    }

    return TrendItemModel(
      period: periodStr,
      production: prod,
      dispatch: disp,
      parameter: param,
      mineName: json['mineName']?.toString() ?? json['mine']?.toString(),
      subsidiary: json['subsidiary']?.toString(),
      unit: json['unit']?.toString() ?? 'MT',
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'production': production,
        'dispatch': dispatch,
        if (parameter != null) 'parameter': parameter,
        if (mineName != null) 'mineName': mineName,
        if (subsidiary != null) 'subsidiary': subsidiary,
        if (unit != null) 'unit': unit,
      };
}

class VarianceItemModel {
  final String mine;
  final String parameter;
  final String period;
  final double target;
  final double actual;
  final double variance;
  final double variancePct;
  final String status;
  final String unit;
  final double dispatch;

  const VarianceItemModel({
    required this.mine,
    required this.parameter,
    this.period = '',
    required this.target,
    required this.actual,
    required this.variance,
    required this.variancePct,
    this.status = '',
    this.unit = 'MT',
    this.dispatch = 0.0,
  });

  bool get isPositive => variance >= 0;

  factory VarianceItemModel.fromJson(Map<String, dynamic> json) {
    final act = _parseDouble(
      json['actualProduction'] ?? json['actual'] ?? json['value'],
    );
    final tgt = _parseDouble(
      json['targetProduction'] ?? json['target'],
    );
    final v = json['variance'] != null
        ? _parseDouble(json['variance'])
        : (act - tgt);

    final vPct = json['achievementRate'] != null
        ? _parseDouble(json['achievementRate'])
        : (json['variancePct'] != null
            ? _parseDouble(json['variancePct'])
            : (json['percentage'] != null
                ? _parseDouble(json['percentage'])
                : (tgt > 0 ? (v / tgt) * 100 : 0.0)));

    final periodStr = json['period']?.toString() ?? '';
    final unitStr = json['unit']?.toString() ?? 'MT';
    final statusStr = json['status']?.toString() ??
        (v >= 0 ? 'TARGET_EXCEEDED' : 'SHORTFALL');

    final mineStr = (json['mine'] ?? json['name'] ?? json['site'])?.toString() ??
        (periodStr.isNotEmpty ? periodStr : 'Production Area');

    final paramStr = (json['parameter'] ?? json['metric'] ?? json['item'])?.toString() ??
        'Raw Coal Extraction ($unitStr)';

    return VarianceItemModel(
      mine: mineStr,
      parameter: paramStr,
      period: periodStr,
      target: tgt,
      actual: act,
      variance: v,
      variancePct: vPct,
      status: statusStr,
      unit: unitStr,
      dispatch: _parseDouble(json['dispatch']),
    );
  }

  Map<String, dynamic> toJson() => {
        'mine': mine,
        'parameter': parameter,
        'period': period,
        'target': target,
        'actual': actual,
        'variance': variance,
        'variancePct': variancePct,
        'status': status,
        'unit': unit,
        'dispatch': dispatch,
      };
}

class AnomalyItemModel {
  final String type;
  final String mine;
  final String details;
  final String severity; // 'critical' | 'warning' | 'info'
  final String? parameter;
  final String? period;
  final double? value;
  final String? unit;
  final double? zScore;
  final double? percentageChange;
  final String? documentName;

  const AnomalyItemModel({
    required this.type,
    required this.mine,
    required this.details,
    required this.severity,
    this.parameter,
    this.period,
    this.value,
    this.unit,
    this.zScore,
    this.percentageChange,
    this.documentName,
  });

  bool get isCritical => severity.toLowerCase() == 'critical';
  bool get isWarning => severity.toLowerCase() == 'warning';
  bool get isInfo => severity.toLowerCase() == 'info';

  factory AnomalyItemModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'ANOMALY';
    final z = (json['zScore'] as num?)?.toDouble();
    final pctChange = (json['percentageChange'] as num?)?.toDouble();

    String sev = json['severity'] as String? ?? '';
    if (sev.isEmpty) {
      if ((z != null && z.abs() >= 3.0) ||
          (pctChange != null && pctChange.abs() >= 50.0) ||
          typeStr.contains('OUTLIER')) {
        sev = 'critical';
      } else {
        sev = 'warning';
      }
    }

    final reasonStr = (json['reason'] ?? json['details'] ?? 'Statistical deviation flagged')
        .toString();
    final mineStr = (json['mine'] ??
            json['documentName'] ??
            json['period'] ??
            'Active Mining Operations')
        .toString();

    return AnomalyItemModel(
      type: typeStr,
      mine: mineStr,
      details: reasonStr,
      severity: sev,
      parameter: json['parameter']?.toString(),
      period: json['period']?.toString(),
      value: (json['value'] as num?)?.toDouble(),
      unit: json['unit']?.toString(),
      zScore: z,
      percentageChange: pctChange,
      documentName: json['documentName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'mine': mine,
        'details': details,
        'severity': severity,
        if (parameter != null) 'parameter': parameter,
        if (period != null) 'period': period,
        if (value != null) 'value': value,
        if (unit != null) 'unit': unit,
        if (zScore != null) 'zScore': zScore,
        if (percentageChange != null) 'percentageChange': percentageChange,
        if (documentName != null) 'documentName': documentName,
      };
}
