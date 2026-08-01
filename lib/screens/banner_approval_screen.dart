import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import 'create_banner_screen.dart';

class BannerApprovalScreen extends StatefulWidget {
  const BannerApprovalScreen({super.key});

  @override
  State<BannerApprovalScreen> createState() => _BannerApprovalScreenState();
}

class _BannerApprovalScreenState extends State<BannerApprovalScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _banners = [];

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('banners')
          .select()
          .neq('status', 'Deleted')
          .order('created_at', ascending: false);
      
      setState(() {
        _banners = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching banners: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBannerStatus(String id, String status) async {
    try {
      await Supabase.instance.client
          .from('banners')
          .update({'status': status})
          .eq('id', id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banner marked as $status')),
        );
        _fetchBanners();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _deleteBanner(String id) async {
    try {
      // Using soft delete by changing status to 'Deleted' to avoid RLS DELETE policy restrictions
      await Supabase.instance.client
          .from('banners')
          .update({'status': 'Deleted'})
          .eq('id', id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner permanently deleted')),
        );
        _fetchBanners();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateBannerScreen()),
          ).then((_) => _fetchBanners());
        },
        backgroundColor: AppColors.electricBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Create Banner', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.electricBlue),
      );
    }

    if (_banners.isEmpty) {
      return Center(
        child: Text('No banners found', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBanners,
      color: AppColors.electricBlue,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), // bottom padding for FAB
        itemCount: _banners.length,
        itemBuilder: (context, index) {
          final banner = _banners[index];
          final isPending = banner['status'] == 'Pending';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    banner['image_url'] ?? '',
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: AppColors.background,
                      child: const Icon(Icons.image_not_supported, color: AppColors.textMuted, size: 40),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              banner['title'] ?? 'No Title',
                              style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(banner['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              banner['status'] ?? 'Unknown',
                              style: GoogleFonts.outfit(
                                color: _getStatusColor(banner['status']),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (banner['subtitle'] != null && banner['subtitle'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            banner['subtitle'],
                            style: GoogleFonts.outfit(color: AppColors.textSecondary),
                          ),
                        ),
                      const SizedBox(height: 12),
                      
                      _buildInfoRow('Type', banner['banner_type'] ?? 'Custom'),
                      _buildInfoRow('Action', banner['action_type'] ?? 'Unknown'),
                      _buildInfoRow('Target City', banner['city'] ?? 'All Cities'),
                      
                      const SizedBox(height: 16),
                      if (isPending)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateBannerStatus(banner['id'], 'Rejected'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.1),
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateBannerStatus(banner['id'], 'Approved'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.electricBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        )
                      else if (banner['status'] == 'Approved')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _updateBannerStatus(banner['id'], 'Rejected'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              foregroundColor: Colors.red,
                              elevation: 0,
                            ),
                            child: const Text('Revoke Approval'),
                          ),
                        )
                      else if (banner['status'] == 'Rejected')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showDeleteDialog(banner['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: const Text('Permanently Delete'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner?'),
        content: const Text('This banner will be permanently deleted and cannot be recovered.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBanner(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Approved': return Colors.green;
      case 'Rejected': return Colors.red;
      default: return Colors.grey;
    }
  }
}
