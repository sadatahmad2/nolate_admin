import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

class MerchantProfileSheet extends StatelessWidget {
  final Map<String, dynamic> shop;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const MerchantProfileSheet({
    super.key,
    required this.shop,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final String shopName = shop['shop_name'] ?? 'Unknown Shop';
    final String ownerName = shop['owner_name'] ?? 'No Owner Info';
    final String phone = shop['phone'] ?? 'No Phone';
    final String category = shop['category'] ?? 'N/A';
    final String address = shop['address'] ?? 'No Address Provided';
    final String status = shop['status'] ?? 'pending';
    final String imageUrl = shop['image_url'] ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Merchant Profile',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.pastelGreen,
                  shape: BoxShape.circle,
                  image: imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                          onError: (e, s) {}) // Handle error gracefully
                      : null,
                ),
                child: imageUrl.isEmpty
                    ? const Icon(Icons.store_rounded, color: AppColors.emeraldGreen, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shopName,
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(category,
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'approved' ? AppColors.pastelGreen : AppColors.coral.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(status.toUpperCase(),
                          style: TextStyle(
                              color: status == 'approved' ? AppColors.emeraldGreen : AppColors.coral,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person_rounded, 'Owner Name', ownerName),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone_rounded, 'Phone Number', phone),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_rounded, 'Address', address),
          const SizedBox(height: 24),
          if (status == 'pending' && (onApprove != null || onReject != null)) ...[
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 16),
            Row(
              children: [
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: AppColors.coral,
                        side: const BorderSide(color: AppColors.coral),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: onReject,
                      child: Text('Reject', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (onReject != null && onApprove != null) const SizedBox(width: 12),
                if (onApprove != null)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.emeraldGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: onApprove,
                      child: Text('Approve Merchant', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11)),
              Text(value, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
