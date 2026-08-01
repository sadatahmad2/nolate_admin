import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/glass_container.dart';
import '../services/admin_supabase_service.dart';
import '../utils/receipt_generator.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final _service = AdminSupabaseService();
  late TabController _tabController;
  Timer? _autoRefreshTimer;

  List<Map<String, dynamic>> _readyOrders = [];
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _historyOrders = [];
  List<Map<String, dynamic>> _riders = [];

  bool _isLoadingReady = true;
  bool _isLoadingActive = false;
  bool _isLoadingHistory = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchReady();
    _fetchRiders();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _silentRefresh(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1 && _activeOrders.isEmpty) {
      _fetchActive();
    }
    if (_tabController.index == 2 && _historyOrders.isEmpty) {
      _fetchHistory();
    }
  }

  Future<void> _fetchRiders() async {
    final riders = await _service.getDeliveryPartners();
    if (mounted) setState(() => _riders = riders);
  }

  Future<void> _fetchReady() async {
    if (!mounted) return;
    setState(() => _isLoadingReady = true);
    try {
      final orders = await _service.getNewOrders();
      if (mounted) setState(() => _readyOrders = orders);
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoadingReady = false);
    }
  }

  Future<void> _fetchActive() async {
    if (!mounted) return;
    setState(() => _isLoadingActive = true);
    try {
      final orders = await _service.getOrdersByStatus('out_for_delivery');
      if (mounted) setState(() => _activeOrders = orders);
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoadingActive = false);
    }
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);
    try {
      final delivered = await _service.getOrdersByStatus('delivered');
      final cancelled = await _service.getOrdersByStatus('cancelled');
      final all = [...delivered, ...cancelled];
      all.sort((a, b) {
        final aT =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
        final bT =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
        return bT.compareTo(aT);
      });
      if (mounted) setState(() => _historyOrders = all);
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final orders = await _service.getNewOrders();
      if (mounted) setState(() => _readyOrders = orders);
      if (_tabController.index == 1) {
        final active = await _service.getOrdersByStatus('out_for_delivery');
        if (mounted) setState(() => _activeOrders = active);
      }
    } catch (_) {}
  }

  Future<void> _manualRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _fetchReady();
    await _fetchRiders();
    if (_tabController.index == 1) await _fetchActive();
    if (_tabController.index == 2) await _fetchHistory();
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.coral,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Assign Delivery Boy Dialog ────────────────────────
  void _showAssignDialog(Map<String, dynamic> order) {
    String? selectedRiderId;
    List<Map<String, dynamic>> orderRiders = [];
    bool isFetchingRiders = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            if (isFetchingRiders) {
              final double? shopLat = (order['shops']?['latitude'] as num?)?.toDouble();
              final double? shopLng = (order['shops']?['longitude'] as num?)?.toDouble();
              
              _service.getDeliveryPartners(shopLat: shopLat, shopLng: shopLng).then((fetched) {
                if (ctx.mounted) {
                  setSheet(() {
                    orderRiders = fetched;
                    isFetchingRiders = false;
                  });
                }
              });
            }

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                    top: BorderSide(color: AppColors.glassBorder, width: 1.5)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Assign Delivery Partner',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #${order['id'].toString().substring(0, 6).toUpperCase()} · ₹${order['total_amount']}',
                    style: GoogleFonts.outfit(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  if (isFetchingRiders)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.electricBlue),
                      ),
                    )
                  else if (orderRiders.isEmpty)
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.sports_motorsports_rounded,
                              color: AppColors.textMuted, size: 36),
                          const SizedBox(height: 10),
                          Text('No online riders available',
                              style: GoogleFonts.outfit(
                                  color: AppColors.textSecondary,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                              'Ensure riders are online in the Rider App.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                  color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    )
                  else ...[
                    Text('Select Rider (Nearest First)',
                        style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    ...List.generate(orderRiders.length, (i) {
                      final rider = orderRiders[i];
                      final riderId = rider['id'].toString();
                      final isSelected = selectedRiderId == riderId;
                      final name = rider['name'] ?? rider['full_name'] ?? 'Rider ${i + 1}';
                      final phone = rider['phone'] ?? '';
                      final distance = rider['distance_km'] as double?;
                      final available = rider['is_available'] ?? rider['available'] ?? true;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => setSheet(
                              () => selectedRiderId = isSelected ? null : riderId),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.electricBlue.withValues(alpha: 0.15)
                                  : AppColors.glassWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.electricBlue
                                    : AppColors.glassBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: available
                                        ? AppColors.emeraldGreen
                                            .withValues(alpha: 0.15)
                                        : AppColors.coral
                                            .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.sports_motorsports_rounded,
                                    color: available
                                        ? AppColors.emeraldGreen
                                        : AppColors.coral,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      if (phone.isNotEmpty)
                                        Text(phone,
                                            style: GoogleFonts.outfit(
                                                color: AppColors.textSecondary,
                                                fontSize: 12)),
                                      if (distance != null)
                                        Text('${distance.toStringAsFixed(1)} km away',
                                            style: GoogleFonts.outfit(
                                                color: AppColors.electricBlue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (available
                                            ? AppColors.emeraldGreen
                                            : AppColors.coral)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    available ? 'Available' : 'Busy',
                                    style: GoogleFonts.outfit(
                                        color: available
                                            ? AppColors.emeraldGreen
                                            : AppColors.coral,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppColors.electricBlue, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: selectedRiderId == null
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _assignRider(
                                  order['id'].toString(), selectedRiderId!);
                            },
                      icon: const Icon(Icons.delivery_dining_rounded, size: 18),
                      label: Text(
                          selectedRiderId == null
                              ? 'Select a rider first'
                              : 'Assign & Dispatch',
                          style: GoogleFonts.outfit(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedRiderId == null
                            ? AppColors.glassWhite
                            : AppColors.electricBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _assignRider(String orderId, String riderId) async {
    try {
      await _service.assignDeliveryBoy(orderId, riderId);
      await _fetchReady();
      await _fetchActive();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Rider assigned & order dispatched!'),
            ],
          ),
          backgroundColor: AppColors.emeraldGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      _showError('Failed to assign: $e');
    }
  }

  // ── Order Detail Sheet ────────────────────────────────
  void _showOrderDetail(Map<String, dynamic> order, {bool canAssign = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        List<Map<String, dynamic>> items = [];
        Map<String, dynamic>? customer;
        bool loading = true;
        bool started = false;

        return StatefulBuilder(builder: (ctx, set) {
          if (!started) {
            started = true;
            Future.wait([
              _service.getCustomerProfile(order['customer_id'].toString()),
              _service.getOrderItems(order['id'].toString()),
            ]).then((res) {
              if (ctx.mounted) {
                set(() {
                  customer = res[0] as Map<String, dynamic>?;
                  items = res[1] as List<Map<String, dynamic>>;
                  loading = false;
                });
              }
            }).catchError((_) {
              if (ctx.mounted) set(() => loading = false);
            });
          }

          final shortId = order['id'].toString().substring(0, 6).toUpperCase();
          final status = order['status']?.toString() ?? '';

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, scroll) => Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                    top: BorderSide(
                        color: AppColors.glassBorder, width: 1.5)),
              ),
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                children: [
                  Center(
                    child: Container(
                      width: 48, height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order #$shortId',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      _statusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.electricBlue, strokeWidth: 2)),
                    )
                  else ...[
                    // Customer
                    _sectionLabel('CUSTOMER'),
                    const SizedBox(height: 8),
                    GlassContainer(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.person_rounded,
                                color: AppColors.electricBlue, size: 18),
                            const SizedBox(width: 10),
                            Text(customer?['name'] ?? 'Unknown',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ]),
                          if (customer?['phone'] != null) ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.phone_rounded,
                                  color: AppColors.electricBlue, size: 16),
                              const SizedBox(width: 10),
                              Text(customer!['phone'],
                                  style: GoogleFonts.outfit(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items
                    _sectionLabel('ORDER ITEMS'),
                    const SizedBox(height: 8),
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 14),
                      child: Column(
                        children: items.isEmpty
                            ? [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Text('No items found',
                                      style: GoogleFonts.outfit(
                                          color: AppColors.textMuted,
                                          fontSize: 13)),
                                )
                              ]
                            : List.generate(items.length, (i) {
                                final item = items[i];
                                final prod = item['products']
                                    as Map<String, dynamic>?;
                                final name = prod?['name'] ?? 'Item';
                                final qty = item['quantity'] ?? 1;
                                final price =
                                    (item['price'] as num?)?.toDouble() ?? 0.0;
                                final imgUrl =
                                    prod?['image_url'] as String?;
                                final isLast = i == items.length - 1;
                                return Column(children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Row(children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: AppColors.glassWhite,
                                        ),
                                        child: imgUrl != null &&
                                                imgUrl.isNotEmpty
                                            ? Image.network(imgUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, err, stack) =>
                                                    const Icon(
                                                        Icons.fastfood_rounded,
                                                        color: AppColors
                                                            .textMuted,
                                                        size: 24))
                                            : const Icon(
                                                Icons.fastfood_rounded,
                                                color: AppColors.textMuted,
                                                size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          Text(
                                              '₹${price.toStringAsFixed(0)} × $qty',
                                              style: GoogleFonts.outfit(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12)),
                                        ],
                                      )),
                                      Text(
                                          '₹${(price * qty).toStringAsFixed(0)}',
                                          style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700)),
                                    ]),
                                  ),
                                  if (!isLast)
                                    const Divider(
                                        color: Colors.white10, height: 1),
                                ]);
                              }),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bill
                    _sectionLabel('BILL DETAILS'),
                    const SizedBox(height: 8),
                    GlassContainer(
                      padding: const EdgeInsets.all(14),
                      child: Column(children: [
                        _billRow('Delivery Fee',
                            '₹${(order['delivery_fee'] as num?)?.toDouble() ?? 0}'),
                        const SizedBox(height: 6),
                        _billRow('Tax',
                            '₹${(order['tax'] as num?)?.toDouble() ?? 0}'),
                        const Divider(color: Colors.white12, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            Text('₹${order['total_amount']}',
                                style: GoogleFonts.outfit(
                                    color: AppColors.premiumGold,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    if (canAssign)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAssignDialog(order);
                        },
                        icon: const Icon(
                            Icons.sports_motorsports_rounded,
                            size: 18),
                        label: Text('Assign Delivery Partner',
                            style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricBlue,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    
                    if (status.toLowerCase() == 'delivered')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final custLoc = order['customer_location'] as Map<String, dynamic>? ?? {};
                            final total = (order['total_amount'] as num?)?.toDouble() ?? 0;
                            final tax = (order['tax'] as num?)?.toDouble() ?? 0;
                            final fee = (order['delivery_fee'] as num?)?.toDouble() ?? 0;
                            final subtotal = total - tax - fee;
                            await ReceiptGenerator.generateAndDownloadReceipt(
                              orderId: order['id'].toString(),
                              customerName: customer?['name'] ?? 'Unknown',
                              customerPhone: customer?['phone'] ?? '',
                              customerAddress: custLoc['address'] ?? '',
                              shopName: 'Nolate Store',
                              items: items,
                              subtotal: subtotal,
                              tax: tax,
                              deliveryFee: fee,
                              total: total,
                              date: DateTime.tryParse(order['created_at']?.toString() ?? '') ?? DateTime.now(),
                              riderName: custLoc['rider_name'] as String?,
                            );
                          },
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text('Download Receipt',
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Orders',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      Text('Auto-refreshing every 30s',
                          style: GoogleFonts.outfit(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _manualRefresh,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.electricBlue.withValues(alpha: 0.3)),
                    ),
                    child: _isRefreshing
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                color: AppColors.electricBlue, strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded,
                            color: AppColors.electricBlue, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.electricBlue.withValues(alpha: 0.4)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(3),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.w700),
                tabs: [
                  Tab(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.new_releases_rounded, size: 14),
                          const SizedBox(width: 4),
                          const Text('New Orders'),
                          if (_readyOrders.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.premiumGold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('${_readyOrders.length}',
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delivery_dining_rounded, size: 14),
                        SizedBox(width: 4),
                        Text('Active'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 14),
                        SizedBox(width: 4),
                        Text('History'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoadingReady
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.electricBlue, strokeWidth: 2))
                    : _buildReadyList(),
                _isLoadingActive
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.electricBlue, strokeWidth: 2))
                    : _buildActiveList(),
                _isLoadingHistory
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.electricBlue, strokeWidth: 2))
                    : _buildHistoryList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyList() {
    if (_readyOrders.isEmpty) {
      return _emptyState(
          icon: Icons.new_releases_rounded,
          title: 'No new orders',
          subtitle: 'Incoming and preparing orders will appear here');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: _readyOrders.length,
      itemBuilder: (_, i) => _orderCard(
        _readyOrders[i],
        onTap: () => _showOrderDetail(_readyOrders[i], canAssign: true),
        action: ElevatedButton.icon(
          onPressed: () => _showAssignDialog(_readyOrders[i]),
          icon: const Icon(Icons.sports_motorsports_rounded, size: 16),
          label: const Text('Assign Rider'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricBlue,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            textStyle: GoogleFonts.outfit(
                fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveList() {
    if (_activeOrders.isEmpty) {
      return _emptyState(
          icon: Icons.delivery_dining_rounded,
          title: 'No active deliveries',
          subtitle: 'Assigned orders out for delivery will appear here');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: _activeOrders.length,
      itemBuilder: (_, i) => _orderCard(
        _activeOrders[i],
        onTap: () => _showOrderDetail(_activeOrders[i]),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_historyOrders.isEmpty) {
      return _emptyState(
          icon: Icons.history_rounded,
          title: 'No history yet',
          subtitle: 'Completed and cancelled orders appear here',
          tapLabel: 'Load History',
          onTap: _fetchHistory);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: _historyOrders.length,
      itemBuilder: (_, i) => _orderCard(
        _historyOrders[i],
        onTap: () => _showOrderDetail(_historyOrders[i]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────
  Widget _orderCard(
    Map<String, dynamic> order, {
    required VoidCallback onTap,
    Widget? action,
  }) {
    final shortId = order['id'].toString().substring(0, 6).toUpperCase();
    final status = order['status']?.toString() ?? '';
    final createdAt = DateTime.tryParse(
            order['created_at']?.toString() ?? '')
        ?.toLocal();
    final dateStr = createdAt != null
        ? '${createdAt.day}/${createdAt.month}  ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '';
        
    String? riderName;
    if (order['customer_location'] is Map) {
      riderName = order['customer_location']['rider_name'];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppColors.electricBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #$shortId',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        Row(children: [
                          const Icon(Icons.access_time_rounded,
                              color: AppColors.textMuted, size: 12),
                          const SizedBox(width: 4),
                          Text(dateStr,
                              style: GoogleFonts.outfit(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ]),
                        if (riderName != null) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.sports_motorsports_rounded, color: AppColors.electricBlue, size: 12),
                            const SizedBox(width: 4),
                            Text(riderName, style: GoogleFonts.outfit(color: AppColors.electricBlue, fontSize: 11, fontWeight: FontWeight.w600)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    _statusBadge(status),
                    const SizedBox(height: 4),
                    Text('₹${order['total_amount']}',
                        style: GoogleFonts.outfit(
                            color: AppColors.premiumGold,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                  ]),
                ],
              ),
              if (action != null) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tap for details',
                        style: GoogleFonts.outfit(
                            color: AppColors.textMuted, fontSize: 12)),
                    action,
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? tapLabel,
    VoidCallback? onTap,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: AppColors.textMuted, size: 36),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: AppColors.textMuted, fontSize: 12)),
          ),
          if (tapLabel != null && onTap != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onTap,
              child: Text(tapLabel,
                  style: GoogleFonts.outfit(
                      color: AppColors.electricBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5));
  }

  Widget _billRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                color: AppColors.textSecondary, fontSize: 13)),
        Text(value,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'ready':
        color = AppColors.emeraldGreen;
        label = 'READY';
        break;
      case 'preparing':
        color = AppColors.coral;
        label = 'PREPARING';
        break;
      case 'out_for_delivery':
        color = AppColors.electricBlue;
        label = 'DELIVERING';
        break;
      case 'delivered':
        color = AppColors.premiumGold;
        label = 'DELIVERED';
        break;
      case 'cancelled':
        color = AppColors.coral;
        label = 'CANCELLED';
        break;
      default:
        color = AppColors.textSecondary;
        label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}
