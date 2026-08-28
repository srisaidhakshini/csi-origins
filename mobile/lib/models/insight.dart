import 'dart:convert';

class Insight {
  final String id;
  final String userId;
  final String triggerType;
  final double severity;
  final double confidence;
  final double urgency;
  final double gateScore;
  final String status;
  final String explanation;
  final Map<String, dynamic>? graphPath;
  final Map<String, dynamic>? councilDebate;
  final List<ActionItem> actions;
  final String? voiceAudio;
  final DateTime createdAt;

  Insight({
    required this.id,
    required this.userId,
    required this.triggerType,
    required this.severity,
    required this.confidence,
    required this.urgency,
    required this.gateScore,
    required this.status,
    required this.explanation,
    this.graphPath,
    this.councilDebate,
    this.actions = const [],
    this.voiceAudio,
    required this.createdAt,
  });

  factory Insight.fromJson(dynamic jsonRaw) {
    if (jsonRaw == null) {
      return Insight(
        id: '',
        userId: '',
        triggerType: 'cascade',
        severity: 0.0,
        confidence: 0.0,
        urgency: 0.0,
        gateScore: 0.0,
        status: 'surfaced',
        explanation: '',
        createdAt: DateTime.now(),
      );
    }

    Map<String, dynamic> json;
    if (jsonRaw is Map<String, dynamic>) {
      json = jsonRaw;
    } else if (jsonRaw is Map) {
      json = Map<String, dynamic>.from(jsonRaw);
    } else {
      try {
        json = Map<String, dynamic>.from(jsonDecode(jsonRaw.toString()));
      } catch (_) {
        json = {};
      }
    }

    List<ActionItem> parsedActions = [];
    final actionsRaw = json['actions'];
    if (actionsRaw != null) {
      if (actionsRaw is List) {
        for (final a in actionsRaw) {
          if (a is Map) {
            parsedActions.add(ActionItem.fromJson(Map<String, dynamic>.from(a)));
          } else if (a is String) {
            try {
              final decoded = jsonDecode(a);
              if (decoded is Map) {
                parsedActions.add(ActionItem.fromJson(Map<String, dynamic>.from(decoded)));
              }
            } catch (_) {}
          }
        }
      }
    }

    return Insight(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      triggerType: json['triggerType']?.toString() ?? json['trigger_type']?.toString() ?? 'cascade',
      severity: (json['severity'] != null) ? double.tryParse(json['severity'].toString()) ?? 0.0 : 0.0,
      confidence: (json['confidence'] != null) ? double.tryParse(json['confidence'].toString()) ?? 0.0 : 0.0,
      urgency: (json['urgency'] != null) ? double.tryParse(json['urgency'].toString()) ?? 0.0 : 0.0,
      gateScore: (json['gateScore'] != null || json['gate_score'] != null)
          ? double.tryParse((json['gateScore'] ?? json['gate_score']).toString()) ?? 0.0
          : 0.0,
      status: json['status']?.toString() ?? 'surfaced',
      explanation: json['explanation']?.toString() ?? '',
      graphPath: json['graphPath'] is Map ? Map<String, dynamic>.from(json['graphPath']) : null,
      councilDebate: json['councilDebate'] is Map ? Map<String, dynamic>.from(json['councilDebate']) : null,
      actions: parsedActions,
      voiceAudio: json['voiceAudio']?.toString() ?? json['voice_audio']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ActionItem {
  final String id;
  final String title;
  final String description;
  final String actionType; // 'invoice_nudge' | 'sip_pause' | 'budget_shift' | 'emergency_draw'
  String status; // 'pending' | 'executed' | 'dismissed'
  final double? impactAmount;
  final Map<String, dynamic>? payload;

  ActionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.actionType,
    required this.status,
    this.impactAmount,
    this.payload,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      actionType: json['actionType']?.toString() ?? json['action_type']?.toString() ?? 'invoice_nudge',
      status: json['status']?.toString() ?? 'pending',
      impactAmount: json['impactAmount'] != null ? double.tryParse(json['impactAmount'].toString()) : null,
      payload: json['payload'] is Map ? Map<String, dynamic>.from(json['payload']) : null,
    );
  }
}

class CouncilStatement {
  final String agentName;
  final String agentRole;
  final String avatarIcon;
  final String verdict;
  final String statement;
  final Map<String, dynamic>? evidence;

  CouncilStatement({
    required this.agentName,
    required this.agentRole,
    required this.avatarIcon,
    required this.verdict,
    required this.statement,
    this.evidence,
  });

  factory CouncilStatement.fromJson(Map<String, dynamic> json) {
    return CouncilStatement(
      agentName: json['agentName']?.toString() ?? '',
      agentRole: json['agentRole']?.toString() ?? '',
      avatarIcon: json['avatarIcon']?.toString() ?? 'smart_toy_outlined',
      verdict: json['verdict']?.toString() ?? 'stable',
      statement: json['statement']?.toString() ?? '',
      evidence: json['evidence'] is Map ? Map<String, dynamic>.from(json['evidence']) : null,
    );
  }
}

class GraphNode {
  final String id;
  final String label;
  final String type; // 'buffer' | 'income_source' | 'obligation' | 'discretionary'
  final double value;
  final String confidence; // 'confirmed' | 'inferred'
  final Map<String, dynamic>? metadata;

  GraphNode({
    required this.id,
    required this.label,
    required this.type,
    required this.value,
    required this.confidence,
    this.metadata,
  });

  factory GraphNode.fromJson(Map<String, dynamic> json) {
    return GraphNode(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? 'buffer',
      value: (json['value'] != null) ? double.tryParse(json['value'].toString()) ?? 0.0 : 0.0,
      confidence: json['confidence']?.toString() ?? 'confirmed',
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }
}

class GraphEdge {
  final String id;
  final String sourceNodeId;
  final String targetNodeId;
  final String relation;
  final double? weight;
  final double? latencyDays;

  GraphEdge({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
    required this.relation,
    this.weight,
    this.latencyDays,
  });

  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      id: json['id']?.toString() ?? '',
      sourceNodeId: json['sourceNodeId']?.toString() ?? json['source_node_id']?.toString() ?? '',
      targetNodeId: json['targetNodeId']?.toString() ?? json['target_node_id']?.toString() ?? '',
      relation: json['relation']?.toString() ?? 'flows_to',
      weight: (json['weight'] != null) ? double.tryParse(json['weight'].toString()) : null,
      latencyDays: (json['latencyDays'] != null || json['latency_days'] != null)
          ? double.tryParse((json['latencyDays'] ?? json['latency_days']).toString())
          : null,
    );
  }
}

