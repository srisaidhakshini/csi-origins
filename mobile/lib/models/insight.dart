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
    required this.createdAt,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
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
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
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
