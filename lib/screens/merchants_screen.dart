import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../services/admin_supabase_service.dart';
import '../widgets/merchant_profile_sheet.dart';

class MerchantsScreen extends StatefulWidget {
  const MerchantsScreen({super.key});

  @override
  State<MerchantsScreen> createState() => _MerchantsScreenState();
}

class _MerchantsScreenState extends State<MerchantsScreen> {
  final AdminSupabaseService _service = AdminSupabaseService();
  List<Map<String, dynamic>> _allShops = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // All, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() => _isLoading = true);
    final shops = await _service.getShops();
    setState(() {
      _allShops = shops;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredShops {
    if (_selectedFilter == 'All') return _allShops;
    return _allShops.where((s) => s['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.emeraldGreen))
              : _filteredShops.isEmpty
                  ? Center(
                      child: Text(
                        'No merchants found',
                        style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 15),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadShops,
                      color: AppColors.emeraldGreen,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _filteredShops.length,
                        itemBuilder: (context, index) {
                          final shop = _filteredShops[index];
                          return _buildMerchantCard(shop);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Merchants',
              style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.pastelGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.store_rounded, color: AppColors.emeraldGreen, size: 16),
                const SizedBox(width: 4),
                Text('${_allShops.length}',
                    style: GoogleFonts.outfit(
                        color: AppColors.emeraldGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'pending', 'approved', 'rejected'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 24, bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.electricBlue : Colors.white,
                  border: Border.all(
                      color: isSelected ? AppColors.electricBlue : AppColors.borderLight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filter.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMerchantCard(Map<String, dynamic> shop) {
    final String name = shop['shop_name'] ?? 'Unknown';
    final String type = shop['category'] ?? 'Shop';
    final String imageUrl = shop['image_url'] ?? '';
    final String status = shop['status'] ?? 'pending';
    final String shopId = shop['id']?.toString() ?? '';

    Color statusColor;
    Color statusBg;
    if (status == 'approved') {
      statusColor = AppColors.emeraldGreen;
      statusBg = AppColors.pastelGreen;
    } else if (status == 'pending') {
      statusColor = AppColors.coral;
      statusBg = AppColors.coral.withValues(alpha: 0.1);
    } else {
      statusColor = AppColors.textSecondary;
      statusBg = AppColors.borderLight;
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (ctx) => MerchantProfileSheet(
            shop: shop,
            onApprove: status != 'approved'
                ? () async {
                    Navigator.pop(ctx);
                    await _service.updateShopStatus(shopId, 'approved');
                    _loadShops();
                  }
                : null,
            onReject: status != 'rejected'
                ? () async {
                    Navigator.pop(ctx);
                    await _service.updateShopStatus(shopId, 'rejected');
                    _loadShops();
                  }
                : null,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
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
              child: imageUrl.isEmpty ? const Icon(Icons.store_rounded, color: AppColors.emeraldGreen) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(type, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
