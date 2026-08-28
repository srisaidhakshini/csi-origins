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

  factory Insight.fromJson(Map<String, dynamic> json) {
    List<ActionItem> parsedActions = [];
    if (json['actions'] != null && json['actions'] is List) {
      parsedActions = (json['actions'] as List).map((a) => ActionItem.fromJson(a)).toList();
    }

    return Insight(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      triggerType: json['triggerType'] ?? json['trigger_type'] ?? 'cascade',
      severity: (json['severity'] != null) ? double.tryParse(json['severity'].toString()) ?? 0.0 : 0.0,
      confidence: (json['confidence'] != null) ? double.tryParse(json['confidence'].toString()) ?? 0.0 : 0.0,
      urgency: (json['urgency'] != null) ? double.tryParse(json['urgency'].toString()) ?? 0.0 : 0.0,
      gateScore: (json['gateScore'] != null || json['gate_score'] != null)
          ? double.tryParse((json['gateScore'] ?? json['gate_score']).toString()) ?? 0.0
          : 0.0,
      status: json['status'] ?? 'surfaced',
      explanation: json['explanation'] ?? '',
      graphPath: json['graphPath'] ?? json['graph_path'],
      councilDebate: json['councilDebate'] ?? json['council_debate'],
      actions: parsedActions,
      voiceAudio: json['voiceAudio'] ?? json['voice_audio'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
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
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      actionType: json['actionType'] ?? json['action_type'] ?? 'invoice_nudge',
      status: json['status'] ?? 'pending',
      impactAmount: json['impactAmount'] != null ? double.tryParse(json['impactAmount'].toString()) : null,
      payload: json['payload'],
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
      agentName: json['agentName'] ?? json['agent_name'] ?? 'Agent',
      agentRole: json['agentRole'] ?? json['agent_role'] ?? 'Specialist',
      avatarIcon: json['avatarIcon'] ?? json['avatar_icon'] ?? 'shield_rounded',
      verdict: json['verdict'] ?? 'warning',
      statement: json['statement'] ?? '',
      evidence: json['evidence'],
    );
  }
}

class GraphNode {
  final String id;
  final String label;
  final String type;
  final double? value;
  final String confidence;
  final Map<String, dynamic>? metadata;

  GraphNode({
    required this.id,
    required this.label,
    required this.type,
    this.value,
    required this.confidence,
    this.metadata,
  });

  factory GraphNode.fromJson(Map<String, dynamic> json) {
    return GraphNode(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? 'buffer',
      value: json['value'] != null ? double.tryParse(json['value'].toString()) : null,
      confidence: json['confidence'] ?? 'confirmed',
      metadata: json['metadata'],
    );
  }
}

class GraphEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final String relation;
  final double weight;
  final GraphNode? source;
  final GraphNode? target;

  GraphEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.relation,
    required this.weight,
    this.source,
    this.target,
  });

  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      id: json['id'] ?? '',
      sourceId: json['sourceId'] ?? json['source_id'] ?? '',
      targetId: json['targetId'] ?? json['target_id'] ?? '',
      relation: json['relation'] ?? 'funds',
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) ?? 1.0 : 1.0,
      source: json['source'] != null ? GraphNode.fromJson(json['source']) : null,
      target: json['target'] != null ? GraphNode.fromJson(json['target']) : null,
    );
  }
}
