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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('// CAUSAL STATE GRAPH (POSTGRESQL)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadGraph,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: Colors.black, height: 2),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadGraph,
        color: Colors.black,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  // State Model Architecture Callout
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161A26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RELATIONAL ADJACENCY CAUSAL GRAPH:',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Stored in PostgreSQL nodes and edges tables. Cascades computed deterministically via Recursive CTE traversal without LLM hallucination.',
                          style: TextStyle(color: Colors.black87, fontSize: 11, height: 1.35, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildCategorySection('INCOME SOURCES', 'income_source'),
                  _buildCategorySection('BUFFERS & ACCOUNTS', 'buffer'),
                  _buildCategorySection('OBLIGATIONS & BILLS', 'obligation'),
                  _buildCategorySection('FINANCIAL GOALS', 'goal'),

                  const SizedBox(height: 12),
                  const Text(
                    'ACTIVE CAUSAL EDGES:',
                    style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 8),

                  if (_edges.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Text('No edges found in database.', style: TextStyle(color: Colors.black54, fontSize: 11)),
                    )
                  else
                    for (final edge in _edges)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${edge.source?.label ?? edge.sourceId} ──[${edge.relation.toUpperCase()}]──> ${edge.target?.label ?? edge.targetId}',
                                style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: Colors.black,
                              child: Text(
                                'W: ${edge.weight}',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategorySection(String title, String type) {
    final filtered = _nodes.where((n) => n.type == type).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: Text('No nodes registered.', style: TextStyle(color: Colors.black38, fontSize: 11)),
          )
        else
          for (final node in filtered)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.label.toUpperCase(),
                        style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                      if (node.value != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '₹${node.value?.toInt()}',
                          style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Text(
                      node.confidence.toUpperCase(),
                      style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 12),
      ],
    );
  }
}
