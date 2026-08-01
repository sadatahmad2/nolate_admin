import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_colors.dart';
import '../services/admin_supabase_service.dart';
import '../widgets/merchant_profile_sheet.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const DashboardScreen({super.key, this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = AdminSupabaseService();
  Map<String, dynamic> _metrics = {};
  List<Map<String, dynamic>> _recentShops = [];
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _activeBanners = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final futures = await Future.wait([
        _service.getDashboardMetrics(),
        _service.getRecentShops(limit: 3),
        _service.getRecentActivity(limit: 4),
        _service.getActiveBanners(),
      ]);
      if (mounted) {
        setState(() {
          _metrics = futures[0] as Map<String, dynamic>;
          _recentShops = futures[1] as List<Map<String, dynamic>>;
          _recentActivity = futures[2] as List<Map<String, dynamic>>;
          _activeBanners = futures[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.emeraldGreen, strokeWidth: 3))
          : RefreshIndicator(
              color: AppColors.emeraldGreen,
              backgroundColor: Colors.white,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildGreeting(),
                  const SizedBox(height: 20),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Quick Actions'),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildChartsSection(),
                  const SizedBox(height: 24),
                  _buildListsSection(),
                  const SizedBox(height: 24),
                  _buildTopBanners(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 16,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
        onPressed: () {},
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Text(
            'NOLATE',
            style: GoogleFonts.outfit(
              color: AppColors.emeraldGreen,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'ADMIN',
            style: GoogleFonts.outfit(
              color: AppColors.emeraldGreen,
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
              onPressed: () {},
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '3',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
        Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'), // Dummy Super Admin avatar
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Super Admin',
                  style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
                Text(
                  'Administrator',
                  style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 10),
                ),
              ],
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 16),
          ],
        )
      ],
    );
  }

  Widget _buildGreeting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Good Morning, Super Admin',
                      style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('👋', style: TextStyle(fontSize: 20)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Here's what's happening with NoLate today.",
                style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: AppColors.emeraldGreen, size: 14),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd MMM').format(DateTime.now()),
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.shopping_bag_rounded,
                color: AppColors.emeraldGreen,
                bgColor: AppColors.pastelGreen,
                value: _metrics['totalOrders']?.toString() ?? '0',
                label: 'Total Orders',
                trend: '+ 12.5%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.currency_rupee_rounded,
                color: AppColors.purpleAccent,
                bgColor: AppColors.pastelPurple,
                value: '₹${_metrics['totalRevenue']?.toInt() ?? 0}',
                label: 'Total Revenue',
                trend: '+ 18.7%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.storefront_rounded,
                color: AppColors.orange,
                bgColor: AppColors.pastelOrange,
                value: _metrics['totalShops']?.toString() ?? '0',
                label: 'Active Merchants',
                trend: '+ 8.3%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.delivery_dining_rounded,
                color: AppColors.electricBlue,
                bgColor: AppColors.pastelBlue,
                value: _metrics['totalRiders']?.toString() ?? '0',
                label: 'Active Riders',
                trend: '+ 5.6%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String value,
    required String label,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.arrow_upward_rounded, color: AppColors.emeraldGreen, size: 12),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  '$trend vs yesterday',
                  style: GoogleFonts.outfit(
                      color: AppColors.emeraldGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showViewAll = false, VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800),
        ),
        if (showViewAll)
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              'View All',
              style: GoogleFonts.outfit(
                  color: AppColors.emeraldGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.0,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildActionBtn(Icons.image_rounded, 'Add Banner', onTap: () {
          if (widget.onTabChange != null) widget.onTabChange!(3);
        }),
        _buildActionBtn(Icons.store_rounded, 'Approve Merchant', onTap: () {
          if (widget.onTabChange != null) widget.onTabChange!(2);
        }),
        _buildActionBtn(Icons.moped_rounded, 'Assign Rider', onTap: () {
          if (widget.onTabChange != null) widget.onTabChange!(1);
        }),
        _buildActionBtn(Icons.local_offer_rounded, 'Add Offer', onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offers feature coming soon!')));
        }),
        _buildActionBtn(Icons.receipt_long_rounded, 'View Orders', onTap: () {
          if (widget.onTabChange != null) widget.onTabChange!(1);
        }),
        _buildActionBtn(Icons.campaign_rounded, 'Send Notification', onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications feature coming soon!')));
        }),
        _buildActionBtn(Icons.grid_view_rounded, 'Manage Categories', onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category management coming soon!')));
        }),
        _buildActionBtn(Icons.location_on_rounded, 'Service Areas', onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service Areas coming soon!')));
        }),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.emeraldGreen, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                maxLines: 2,
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    int totalOrders = _metrics['totalOrders'] ?? 0;
    int pending = _metrics['chartPending'] ?? 0;
    int preparing = _metrics['chartPreparing'] ?? 0;
    int pickedUp = _metrics['chartPickedUp'] ?? 0;
    int delivered = _metrics['chartDelivered'] ?? 0;
    int cancelled = _metrics['chartCancelled'] ?? 0;
    double revenue = (_metrics['totalRevenue'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Orders Overview',
                  style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 40,
                            sections: [
                              if (delivered > 0) PieChartSectionData(color: AppColors.emeraldGreen, value: delivered.toDouble(), title: '', radius: 15),
                              if (cancelled > 0) PieChartSectionData(color: AppColors.coral, value: cancelled.toDouble(), title: '', radius: 15),
                              if (preparing > 0) PieChartSectionData(color: AppColors.orange, value: preparing.toDouble(), title: '', radius: 15),
                              if (pickedUp > 0) PieChartSectionData(color: AppColors.purpleAccent, value: pickedUp.toDouble(), title: '', radius: 15),
                              if (pending > 0) PieChartSectionData(color: AppColors.electricBlue, value: pending.toDouble(), title: '', radius: 15),
                              if (totalOrders == 0) PieChartSectionData(color: AppColors.borderLight, value: 1, title: '', radius: 15),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$totalOrders', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Total', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 10)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildLegendItem(AppColors.electricBlue, 'Pending', '$pending'),
                        _buildLegendItem(AppColors.orange, 'Preparing', '$preparing'),
                        _buildLegendItem(AppColors.purpleAccent, 'Picked Up', '$pickedUp'),
                        _buildLegendItem(AppColors.emeraldGreen, 'Delivered', '$delivered'),
                        _buildLegendItem(AppColors.coral, 'Cancelled', '$cancelled'),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  if (widget.onTabChange != null) widget.onTabChange!(1);
                },
                child: _buildCardFooterButton('View All Orders'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Revenue Overview',
                      style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text('This Week', style: GoogleFonts.outfit(fontSize: 11)),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${revenue.toInt()}',
                          style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                      Text('Total Revenue',
                          style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 12)),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, color: AppColors.emeraldGreen, size: 14),
                          Text(' 18.7%',
                              style: GoogleFonts.outfit(
                                  color: AppColors.emeraldGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text('vs last week',
                          style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 11)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 50,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.borderLight,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}K',
                            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 9),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ['19 May', '20 May', '21 May', '22 May', '23 May', '24 May', '25 May'];
                            if (value.toInt() >= 0 && value.toInt() < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(days[value.toInt()], style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 9)),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 50),
                          FlSpot(1, 70),
                          FlSpot(2, 90),
                          FlSpot(3, 50),
                          FlSpot(4, 110),
                          FlSpot(5, 80),
                          FlSpot(6, 170),
                        ],
                        isCurved: true,
                        color: AppColors.emeraldGreen,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildCardFooterButton('View Detailed Analytics'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(value, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildListsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Pending Approvals',
                          style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      if (_recentShops.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${_recentShops.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      if (widget.onTabChange != null) widget.onTabChange!(2);
                    },
                    child: Text('View All', style: GoogleFonts.outfit(color: AppColors.emeraldGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_recentShops.isEmpty)
                Text('No pending approvals at this time.', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
              ..._recentShops.map((shop) {
                return Column(
                  children: [
                    _buildApprovalItem(shop),
                    const Divider(color: AppColors.borderLight),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Activity',
                      style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () {
                      if (widget.onTabChange != null) widget.onTabChange!(1);
                    },
                    child: Text('View All', style: GoogleFonts.outfit(color: AppColors.emeraldGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_recentActivity.isEmpty)
                Text('No recent activity.', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
              ..._recentActivity.map((activity) {
                // If it's an order
                final shopName = activity['shops']?['shop_name'] ?? 'Unknown Shop';
                final status = activity['status'] ?? 'unknown';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildActivityItem(
                      Icons.receipt_long_rounded,
                      AppColors.electricBlue,
                      AppColors.pastelBlue,
                      'Order ${status.toString().toUpperCase()}',
                      'Order #${activity['id'].toString().substring(0, 8)} at $shopName',
                      'Recently'),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalItem(Map<String, dynamic> shop) {
    final String name = shop['shop_name'] ?? 'Unknown';
    final String type = shop['category'] ?? 'Shop';
    final String imageUrl = shop['image_url'] ?? '';
    final String shopId = shop['id']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => MerchantProfileSheet(
              shop: shop,
              onApprove: () async {
                Navigator.pop(ctx);
                await _service.updateShopStatus(shopId, 'approved');
                _load(); // Reload dashboard
              },
              onReject: () async {
                Navigator.pop(ctx);
                await _service.updateShopStatus(shopId, 'rejected');
                _load();
              },
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.pastelGreen,
                shape: BoxShape.circle,
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        onError: (e, s) {})
                    : null,
              ),
              child: imageUrl.isEmpty ? const Icon(Icons.store_rounded, color: AppColors.emeraldGreen, size: 20) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(type, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11)),
                  Text('Registered Recently', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                await _service.updateShopStatus(shopId, 'approved');
                _load();
              },
              child: _buildCircleBtn(Icons.check_rounded, AppColors.emeraldGreen, AppColors.pastelGreen),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await _service.updateShopStatus(shopId, 'rejected');
                _load();
              },
              child: _buildCircleBtn(Icons.close_rounded, AppColors.coral, AppColors.coral.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildActivityItem(IconData icon, Color color, Color bgColor, String title, String subtitle, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
              Text(subtitle, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Text(time, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildTopBanners() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Top Banner Performance', showViewAll: true, onViewAll: () {
          if (widget.onTabChange != null) widget.onTabChange!(3);
        }),
        const SizedBox(height: 12),
        if (_activeBanners.isEmpty)
          Text('No active banners.', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
        ..._activeBanners.map((banner) {
          final title = banner['title'] ?? 'Banner';
          final sub = banner['target_route'] ?? 'No link';
          final img = banner['image_url'] ?? 'https://via.placeholder.com/400x200';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBannerPerfItem(title, sub, '0', '0', '0%', img),
          );
        }),
      ],
    );
  }

  Widget _buildBannerPerfItem(String title, String subtitle, String views, String clicks, String ctr, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl, width: 80, height: 60, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: GoogleFonts.outfit(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.pastelGreen,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text('Active',
                              style: TextStyle(
                                  color: AppColors.emeraldGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: GoogleFonts.outfit(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBannerStat(Icons.visibility_outlined, views, 'Views'),
              _buildBannerStat(Icons.ads_click_rounded, clicks, 'Clicks'),
              _buildBannerStat(Icons.percent_rounded, ctr, 'CTR'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 9)),
      ],
    );
  }

  Widget _buildCardFooterButton(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pastelGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, style: GoogleFonts.outfit(color: AppColors.emeraldGreen, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_rounded, color: AppColors.emeraldGreen, size: 14),
        ],
      ),
    );
  }
}
