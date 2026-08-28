import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/insight.dart';

class ApiService {
  static const String demoUserId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

  // Automatically adjust localhost for Android Emulator vs iOS / Desktop / Web
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    } catch (_) {}
    return 'http://localhost:3000/api';
  }

  /// Fetch surfaced insights feed
  static Future<List<Insight>> asyncFetchSurfacedInsights({String userId = demoUserId}) async {
    final uri = Uri.parse('$baseUrl/insights?userId=$userId&status=surfaced');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List insightsRaw = data['insights'] ?? [];
        return insightsRaw.map((e) => Insight.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching surfaced insights: $e');
    }
    return <Insight>[];
  }

  /// Fetch suppressed insights for transparency log
  static Future<List<Insight>> asyncFetchSuppressedInsights({String userId = demoUserId}) async {
    final uri = Uri.parse('$baseUrl/insights/suppressed?userId=$userId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List insightsRaw = data['insights'] ?? [];
        return insightsRaw.map((e) => Insight.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching suppressed insights: $e');
    }
    return <Insight>[];
  }

  /// Fetch all causal graph nodes
  static Future<List<GraphNode>> fetchGraphNodes({String userId = demoUserId}) async {
    final uri = Uri.parse('$baseUrl/graph/nodes?userId=$userId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List nodesRaw = data['nodes'] ?? [];
        return nodesRaw.map((e) => GraphNode.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching graph nodes: $e');
    }
    return [];
  }

  /// Fetch all causal graph edges
  static Future<List<GraphEdge>> fetchGraphEdges({String userId = demoUserId}) async {
    final uri = Uri.parse('$baseUrl/graph/edges?userId=$userId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List edgesRaw = data['edges'] ?? [];
        return edgesRaw.map((e) => GraphEdge.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching graph edges: $e');
    }
    return [];
  }

  /// Update risk tolerance setting
  static Future<bool> updateRiskTolerance(String tolerance, {String userId = demoUserId}) async {
    final uri = Uri.parse('$baseUrl/users/$userId/risk-tolerance');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'riskTolerance': tolerance.toLowerCase()}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating risk tolerance: $e');
      return false;
    }
  }

  /// Fetch Google OAuth authorization URL
  static Future<String?> getGoogleAuthUrl({String userId = demoUserId}) async {
    final uri = Uri.parse('$baseUrl/auth/google/url?userId=$userId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['authUrl'];
      }
    } catch (e) {
      debugPrint('Error getting Google Auth URL: $e');
    }
    return null;
  }

  /// Execute a proposed 1-click counter action from the Multi-Agent Council
  static Future<Map<String, dynamic>?> executeAction({
    required String insightId,
    required String actionId,
    required String actionType,
    Map<String, dynamic>? payload,
    String userId = demoUserId,
  }) async {
    final uri = Uri.parse('$baseUrl/actions/execute');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'insightId': insightId,
          'actionId': actionId,
          'actionType': actionType,
          'payload': payload,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error executing counter-action: $e');
    }
    return null;
  }

  /// Fetch ElevenLabs Voice Briefing for an Insight
  static Future<Map<String, dynamic>?> fetchVoiceBriefing(String insightId) async {
    final uri = Uri.parse('$baseUrl/voice/briefing/$insightId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching voice briefing: $e');
    }
    return null;
  }

  /// Trigger emergency voice call simulation
  static Future<Map<String, dynamic>?> triggerEmergencyCall({
    String? insightId,
    String userId = demoUserId,
  }) async {
    final uri = Uri.parse('$baseUrl/voice/trigger-call');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'insightId': insightId,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error triggering emergency call: $e');
    }
    return null;
  }

  /// Live Simulator: Trigger delayed income cascade
  static Future<Map<String, dynamic>?> triggerDelayedIncome({
    String userId = demoUserId,
    int delayDays = 5,
  }) async {
    final uri = Uri.parse('$baseUrl/events/trigger-delay');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'delayDays': delayDays,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error triggering delayed income: $e');
    }
    return null;
  }

  /// Live Simulator: Ingest simulated SMS alert
  static Future<Map<String, dynamic>?> ingestSimulatedSMS({
    required String sender,
    required String body,
    String userId = demoUserId,
  }) async {
    final uri = Uri.parse('$baseUrl/events/ingest');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'source': 'sms',
          'sms': {
            'sender': sender,
            'body': body,
          },
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error ingesting simulated SMS: $e');
    }
    return null;
  }

  /// Ingest custom manual financial transaction
  static Future<Map<String, dynamic>?> ingestManualTransaction({
    required double amount,
    required String merchant,
    required String type,
    String category = 'general',
    String? note,
    String userId = demoUserId,
  }) async {
    final uri = Uri.parse('$baseUrl/events/ingest');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'amount': amount,
          'merchant': merchant,
          'type': type,
          'category': category,
          'note': note,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error ingesting manual transaction: $e');
    }
    return null;
  }

  /// Ingest OCR Scanned Bill / Invoice into Causal State & Deduplication Engine
  static Future<Map<String, dynamic>?> processOcrScan({
    required String merchant,
    required double amount,
    String category = 'utilities',
    String? dueDate,
    String? invoiceNumber,
    double? taxAmount,
    String? rawOcrText,
    bool isRecurringObligation = true,
    String userId = demoUserId,
  }) async {
    final uri = Uri.parse('$baseUrl/events/ocr-scan');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'merchant': merchant,
          'amount': amount,
          'category': category,
          'dueDate': dueDate,
          'invoiceNumber': invoiceNumber,
          'taxAmount': taxAmount,
          'rawOcrText': rawOcrText,
          'isRecurringObligation': isRecurringObligation,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error processing OCR scan: $e');
    }
    return null;
  }

  /// Send natural language question to AI Copilot Chatbot
  static Future<Map<String, dynamic>?> sendChatMessage(String message, {String userId = demoUserId}) async {
    final uri = Uri.parse('$baseUrl/chat');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'message': message,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error in chat API: $e');
    }
    return null;
  }

  /// Trigger Gmail Transaction Ingestion Sync
  static Future<Map<String, dynamic>?> syncGmail({String userId = demoUserId}) async {
    final uri = Uri.parse('$baseUrl/auth/google/sync');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error triggering Gmail sync: $e');
    }
    return null;
  }
}
