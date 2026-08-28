import 'package:flutter/material.dart';
import '../models/insight.dart';
import '../services/api_service.dart';

class GraphStateScreen extends StatefulWidget {
  const GraphStateScreen({super.key});

  @override
  State<GraphStateScreen> createState() => _GraphStateScreenState();
}

class _GraphStateScreenState extends State<GraphStateScreen> {
  List<GraphNode> _nodes = [];
  List<GraphEdge> _edges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGraph();
  }

  Future<void> _loadGraph() async {
    setState(() => _isLoading = true);
    final nodes = await ApiService.fetchGraphNodes();
    final edges = await ApiService.fetchGraphEdges();
    setState(() {
      _nodes = nodes;
      _edges = edges;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121622),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.hub_outlined, color: Colors.indigoAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Causal State Model (Postgres)',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadGraph,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadGraph,
        color: Colors.indigoAccent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
            : ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  // State Model Architecture Callout
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161A26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigoAccent.withOpacity(0.3)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.storage_rounded, color: Colors.indigoAccent, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Adjacency List Graph in PostgreSQL',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Graph modeled relational in nodes & edges tables. Cascades computed deterministically via Recursive CTE traversal.',
                          style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildCategorySection('INCOME SOURCES', 'income_source', Colors.greenAccent),
                  _buildCategorySection('BUFFERS & ACCOUNTS', 'buffer', Colors.blueAccent),
                  _buildCategorySection('OBLIGATIONS & BILLS', 'obligation', Colors.amberAccent),
                  _buildCategorySection('FINANCIAL GOALS', 'goal', Colors.purpleAccent),

                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Text(
                      'CAUSAL RELATIONSHIPS (EDGES)',
                      style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                  ),
                  for (final edge in _edges) _buildEdgeCard(edge),
                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }

  Widget _buildCategorySection(String title, String type, Color color) {
    final filtered = _nodes.where((n) => n.type == type).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                '$title (${filtered.length})',
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ],
          ),
        ),
        for (final n in filtered) _buildNodeCard(n, color),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildNodeCard(GraphNode node, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF161A26),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Conf: ${node.confidence.toUpperCase()}',
                    style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (node.value != null)
              Text(
                '₹${node.value!.toInt().toString()}',
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEdgeCard(GraphEdge edge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161A26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                edge.source?.label ?? 'Node',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '── ${edge.relation} ──>',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                edge.target?.label ?? 'Target',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            'w=${edge.weight}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
