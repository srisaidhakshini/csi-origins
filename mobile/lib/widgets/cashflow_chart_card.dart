import 'package:flutter/material.dart';

class DailySpendingNode {
  final int day;
  final String dateLabel;
  final double dailySpent; // negative = spent (-), positive = received (+), 0 = no spend
  final String spendingTitle;
  final double balance;
  final Offset normCoord;
  final bool isInflow;

  const DailySpendingNode({
    required this.day,
    required this.dateLabel,
    required this.dailySpent,
    required this.spendingTitle,
    required this.balance,
    required this.normCoord,
    this.isInflow = false,
  });
}

class CashflowChartCard extends StatefulWidget {
  final String userName;
  final String archetype;
  final String netWorth;
  final String topAmount;
  final String startAmount;
  final String startDate;
  final String endDate;
  final String timeRangeLabel;
  final String thisMonthChange;
  final String thisYearChange;
  final VoidCallback? onEditProfile;

  const CashflowChartCard({
    super.key,
    this.userName = 'GOWREESH',
    this.archetype = 'User',
    this.netWorth = '₹1,92,050.78',
    this.topAmount = '₹6,575.42',
    this.startAmount = '₹3,022.22',
    this.startDate = 'Aug 01',
    this.endDate = 'Aug 31',
    this.timeRangeLabel = 'This Month',
    this.thisMonthChange = '-₹599',
    this.thisYearChange = '-₹4,546',
    this.onEditProfile,
  });

  @override
  State<CashflowChartCard> createState() => _CashflowChartCardState();
}

class _CashflowChartCardState extends State<CashflowChartCard> {
  int _selectedIndex = 2; // Default to Aug 05 Rent day

  // Daily nodes for August representing daily spending & balance trajectory
  static const List<DailySpendingNode> _dailyNodes = [
    DailySpendingNode(
      day: 1,
      dateLabel: 'Aug 01',
      dailySpent: 0,
      spendingTitle: 'Month Opening Buffer',
      balance: 196596.78,
      normCoord: Offset(0.00, 0.05),
    ),
    DailySpendingNode(
      day: 3,
      dateLabel: 'Aug 03',
      dailySpent: -450,
      spendingTitle: 'Groceries & Cafe',
      balance: 196146.78,
      normCoord: Offset(0.11, 0.10),
    ),
    DailySpendingNode(
      day: 5,
      dateLabel: 'Aug 05',
      dailySpent: -28000,
      spendingTitle: 'Apartment Rent (Major Outflow)',
      balance: 168146.78,
      normCoord: Offset(0.23, 0.22),
    ),
    DailySpendingNode(
      day: 9,
      dateLabel: 'Aug 09',
      dailySpent: -5000,
      spendingTitle: 'Parag Parikh Mutual Fund SIP',
      balance: 163146.78,
      normCoord: Offset(0.35, 0.48),
    ),
    DailySpendingNode(
      day: 12,
      dateLabel: 'Aug 12',
      dailySpent: 35000,
      spendingTitle: 'TechCorp Design Retainer Received',
      balance: 198146.78,
      normCoord: Offset(0.46, 0.49),
      isInflow: true,
    ),
    DailySpendingNode(
      day: 15,
      dateLabel: 'Aug 15',
      dailySpent: -1200,
      spendingTitle: 'Dining & Weekend Outing',
      balance: 196946.78,
      normCoord: Offset(0.57, 0.50),
    ),
    DailySpendingNode(
      day: 17,
      dateLabel: 'Aug 17',
      dailySpent: -3500,
      spendingTitle: 'BESCOM Electricity & WiFi Bill',
      balance: 193446.78,
      normCoord: Offset(0.68, 0.54),
    ),
    DailySpendingNode(
      day: 21,
      dateLabel: 'Aug 21',
      dailySpent: -470,
      spendingTitle: 'Uber Ride & Snacks',
      balance: 192976.78,
      normCoord: Offset(0.78, 0.75),
    ),
    DailySpendingNode(
      day: 24,
      dateLabel: 'Aug 24',
      dailySpent: 0,
      spendingTitle: 'No Transactions',
      balance: 192976.78,
      normCoord: Offset(0.88, 0.75),
    ),
    DailySpendingNode(
      day: 27,
      dateLabel: 'Aug 27',
      dailySpent: -926,
      spendingTitle: 'Swiggy Food & Dining',
      balance: 192050.78,
      normCoord: Offset(0.94, 0.88),
    ),
    DailySpendingNode(
      day: 31,
      dateLabel: 'Aug 31',
      dailySpent: 0,
      spendingTitle: 'Month-End Reserve',
      balance: 192050.78,
      normCoord: Offset(1.00, 0.92),
    ),
  ];

  void _updateHoverIndex(Offset localPosition, double width) {
    if (width <= 0) return;
    final normalizedX = (localPosition.dx / width).clamp(0.0, 1.0);
    int closest = 0;
    double minDiff = 999.0;
    for (int i = 0; i < _dailyNodes.length; i++) {
      final diff = (_dailyNodes[i].normCoord.dx - normalizedX).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = i;
      }
    }
    if (_selectedIndex != closest) {
      setState(() => _selectedIndex = closest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeNode = _dailyNodes[_selectedIndex.clamp(0, _dailyNodes.length - 1)];
    final displayName = widget.userName.trim().isEmpty ? 'USER' : widget.userName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1548DC).withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEEF2F8), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header: Dynamic User Name & Subtitle + Net Worth Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: widget.onEditProfile,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF1C2434),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (widget.onEditProfile != null) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_outlined,
                              color: const Color(0xFF1548DC).withOpacity(0.6),
                              size: 15,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${displayName} • Net worth',
                        style: const TextStyle(
                          color: Color(0xFF8A99AD),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                widget.netWorth,
                style: const TextStyle(
                  color: Color(0xFF1C2434),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Chart Top Meta & Live Daily Spending Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.topAmount,
                style: const TextStyle(
                  color: Color(0xFF5A6E85),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: Color(0xFF1548DC), size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Balance Trend',
                    style: TextStyle(
                      color: Color(0xFF1C2434),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 3. Interactive Daily Spending Floating Banner (Scrubbing feedback)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1548DC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        activeNode.dateLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activeNode.spendingTitle,
                      style: const TextStyle(
                        color: Color(0xFF1C2434),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Daily: ',
                      style: TextStyle(color: Color(0xFF8A99AD), fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      activeNode.dailySpent == 0
                          ? '₹0'
                          : '${activeNode.isInflow ? '+' : '-'}₹${activeNode.dailySpent.abs().toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: TextStyle(
                        color: activeNode.dailySpent == 0
                            ? const Color(0xFF5A6E85)
                            : (activeNode.isInflow ? const Color(0xFF00A86B) : const Color(0xFFE53935)),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 4. Dashed Grid Mesh & Stepped Line Graph with Area Fill & Interactive Scrubbing
          LayoutBuilder(
            builder: (context, constraints) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onHover: (event) => _updateHoverIndex(event.localPosition, constraints.maxWidth),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _updateHoverIndex(details.localPosition, constraints.maxWidth),
                  onPanUpdate: (details) => _updateHoverIndex(details.localPosition, constraints.maxWidth),
                  onTapDown: (details) => _updateHoverIndex(details.localPosition, constraints.maxWidth),
                  child: SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _DailySpendingChartPainter(
                        nodes: _dailyNodes,
                        selectedIndex: _selectedIndex,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 6),

          // 5. Chart Bottom Labels for Monthly View: "Aug 01 / ₹3,022.22" (left), "This Month" (center), "Aug 31" (right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.startDate,
                    style: const TextStyle(
                      color: Color(0xFF1C2434),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.startAmount,
                    style: const TextStyle(
                      color: Color(0xFF5A6E85),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  widget.timeRangeLabel,
                  style: const TextStyle(
                    color: Color(0xFF8A99AD),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                widget.endDate,
                style: const TextStyle(
                  color: Color(0xFF1C2434),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // 6. Subtle Divider Line
          Container(
            margin: const EdgeInsets.only(top: 14, bottom: 12),
            height: 1,
            color: const Color(0xFFEDF2F7),
          ),

          // 7. Bottom 2-Column Metrics: "-₹599 THIS MONTH" & "-₹4,546 THIS YEAR" (No duplicate balance)
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.thisMonthChange,
                      style: const TextStyle(
                        color: Color(0xFF1C2434),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'THIS MONTH',
                      style: TextStyle(
                        color: Color(0xFF8A99AD),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.thisYearChange,
                      style: const TextStyle(
                        color: Color(0xFF1C2434),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'THIS YEAR',
                      style: TextStyle(
                        color: Color(0xFF8A99AD),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // 8. Bottom Chevron Arrow Indicator
          const Center(
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Color(0xFFA0AEC0),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailySpendingChartPainter extends CustomPainter {
  final List<DailySpendingNode> nodes;
  final int selectedIndex;

  _DailySpendingChartPainter({
    required this.nodes,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final double width = size.width;
    final double height = size.height;

    // Helper to map normalized offset (0..1, 0..1) to pixel coords
    Offset toPixel(Offset norm) {
      return Offset(norm.dx * width, norm.dy * height);
    }

    // 1. Draw Dashed Grid Background (4 Horizontal Lines, 6 Vertical Lines)
    final gridPaint = Paint()
      ..color = const Color(0xFFD6E2F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double dashWidth = 3.5;
    const double dashSpace = 3.5;

    // Horizontal dashed grid lines
    const int hDivisions = 3;
    for (int i = 0; i <= hDivisions; i++) {
      final double y = (i / hDivisions) * height;
      double startX = 0;
      while (startX < width) {
        canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), gridPaint);
        startX += dashWidth + dashSpace;
      }
    }

    // Vertical dashed grid lines
    const int vDivisions = 5;
    for (int i = 0; i <= vDivisions; i++) {
      final double x = (i / vDivisions) * width;
      double startY = 0;
      while (startY < height) {
        canvas.drawLine(Offset(x, startY), Offset(x, startY + dashWidth), gridPaint);
        startY += dashWidth + dashSpace;
      }
    }

    // 2. Build Line Path & Gradient Area Fill
    final path = Path();
    final fillPath = Path();

    final pixelPoints = nodes.map((n) => toPixel(n.normCoord)).toList();

    path.moveTo(pixelPoints[0].dx, pixelPoints[0].dy);
    fillPath.moveTo(pixelPoints[0].dx, pixelPoints[0].dy);

    for (int i = 0; i < pixelPoints.length - 1; i++) {
      final curr = pixelPoints[i];
      final next = pixelPoints[i + 1];

      // Subtle spline curve between nodes
      final cp1 = Offset(curr.dx + (next.dx - curr.dx) * 0.4, curr.dy);
      final cp2 = Offset(curr.dx + (next.dx - curr.dx) * 0.6, next.dy);

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, next.dx, next.dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, next.dx, next.dy);
    }

    // Close gradient area fill path to bottom of chart
    fillPath.lineTo(pixelPoints.last.dx, height);
    fillPath.lineTo(pixelPoints.first.dx, height);
    fillPath.close();

    // 3. Draw Gradient Shader below the line
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF3B82F6).withOpacity(0.24),
        const Color(0xFF93C5FD).withOpacity(0.06),
        const Color(0xFFEFF6FF).withOpacity(0.00),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 4. Draw Line Stroke
    final linePaint = Paint()
      ..color = const Color(0xFF2856A6)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // 5. Draw Selected Scrubber Vertical Guideline & Tooltip Box
    final safeIndex = selectedIndex.clamp(0, pixelPoints.length - 1);
    final selPt = pixelPoints[safeIndex];
    final selectedNode = nodes[safeIndex];

    // Vertical dashed highlight line at selected point
    final selectLinePaint = Paint()
      ..color = const Color(0xFF1548DC).withOpacity(0.4)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(selPt.dx, 0), Offset(selPt.dx, height), selectLinePaint);

    // 6. Draw Circular Dots on each milestone node
    final dotPaint = Paint()
      ..color = const Color(0xFF2856A6)
      ..style = PaintingStyle.fill;

    final haloPaint = Paint()
      ..color = const Color(0xFF1548DC).withOpacity(0.25)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < pixelPoints.length; i++) {
      final pt = pixelPoints[i];
      final isSelected = i == safeIndex;

      if (isSelected) {
        canvas.drawCircle(pt, 8.0, haloPaint);
        canvas.drawCircle(pt, 5.0, Paint()..color = Colors.white);
        canvas.drawCircle(
          pt,
          3.6,
          Paint()
            ..color = selectedNode.dailySpent == 0
                ? const Color(0xFF2856A6)
                : (selectedNode.isInflow ? const Color(0xFF00A86B) : const Color(0xFFE53935)),
        );
      } else {
        canvas.drawCircle(pt, 3.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DailySpendingChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.nodes != nodes;
  }
}
