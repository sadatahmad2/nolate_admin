import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────
  Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Orders ────────────────────────────────────────────

  /// Fetch orders by one or multiple statuses
  Future<List<Map<String, dynamic>>> getOrdersByStatus(String status) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, shops(*)')
          .eq('status', status)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Fetch new/incoming orders (both 'pending' and 'placed')
  Future<List<Map<String, dynamic>>> getNewOrders() async {
    try {
      final pending = await getOrdersByStatus('pending');
      final placed = await getOrdersByStatus('placed');
      final preparing = await getOrdersByStatus('preparing');
      final ready = await getOrdersByStatus('ready');
      final all = [...pending, ...placed, ...preparing, ...ready];
      all.sort((a, b) {
        final aT = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
        final bT = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
        return bT.compareTo(aT);
      });
      return all;
    } catch (e) {
      return [];
    }
  }

  /// Fetch ALL orders for dashboard metrics
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final response = await _client
        .from('orders')
        .select('*')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update order status + optionally assign delivery partner
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? deliveryPartnerId,
  }) async {
    final Map<String, dynamic> updateData = {'status': newStatus};
    if (deliveryPartnerId != null) {
      updateData['delivery_partner_id'] = deliveryPartnerId;
    }
    await _client.from('orders').update(updateData).eq('id', orderId);
  }

  /// Assign delivery boy to order
  Future<void> assignDeliveryBoy(String orderId, String riderId) async {
    // 1. Fetch rider details
    final riderRes = await _client.from('riders').select('*').eq('id', riderId).maybeSingle();
    
    // 2. Fetch current order to get existing customer_location
    final orderRes = await _client.from('orders').select('customer_location').eq('id', orderId).maybeSingle();
    
    Map<String, dynamic> custLoc = {};
    if (orderRes != null && orderRes['customer_location'] != null) {
      custLoc = Map<String, dynamic>.from(orderRes['customer_location'] as Map);
    }
    
    // 3. Inject rider info for the Customer App
    if (riderRes != null) {
      custLoc['rider_name'] = riderRes['name'] ?? 'Nolate Rider';
      custLoc['rider_phone'] = riderRes['phone'] ?? '+91 9999999999';
      if (riderRes['latitude'] != null) custLoc['rider_lat'] = riderRes['latitude'];
      if (riderRes['longitude'] != null) custLoc['rider_lng'] = riderRes['longitude'];
    }

    // 4. Update the order
    await _client.from('orders').update({
      'delivery_partner_id': riderId,
      'status': 'out_for_delivery',
      'customer_location': custLoc,
    }).eq('id', orderId);
  }

  // ── Order Items ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      final items = await _client
          .from('order_items')
          .select('*')
          .eq('order_id', orderId);
      final List<Map<String, dynamic>> itemList =
          List<Map<String, dynamic>>.from(items);
      if (itemList.isEmpty) return [];

      final productIds =
          itemList.map((i) => i['product_id']).toSet().toList();
      final products = await _client
          .from('products')
          .select('*')
          .inFilter('id', productIds);
      final prodMap = {
        for (var p in List<Map<String, dynamic>>.from(products))
          p['id'].toString(): p
      };
      for (var item in itemList) {
        item['products'] = prodMap[item['product_id'].toString()];
      }
      return itemList;
    } catch (e) {
      return [];
    }
  }

  // ── Delivery Partners (Riders) ────────────────────────
  Future<List<Map<String, dynamic>>> getDeliveryPartners({double? shopLat, double? shopLng}) async {
    try {
      final response = await _client.from('riders').select('*').eq('is_online', true).order('name');
      List<Map<String, dynamic>> riders = List<Map<String, dynamic>>.from(response);

      if (shopLat != null && shopLng != null) {
        for (var rider in riders) {
          final double? riderLat = rider['latitude'];
          final double? riderLng = rider['longitude'];
          
          if (riderLat != null && riderLng != null) {
            double distance = _calculateDistance(shopLat, shopLng, riderLat, riderLng);
            rider['distance_km'] = distance;
          } else {
            rider['distance_km'] = 9999.9; // Push to bottom if no location
          }
        }
        
        riders.sort((a, b) => (a['distance_km'] as double).compareTo(b['distance_km'] as double));
      }

      return riders;
    } catch (e) {
      return [];
    }
  }

  // Haversine formula for distance
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.pi / 180
    final double a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }


  // ── Shops ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getShops() async {
    final response =
        await _client.from('shops').select('*').order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateShopStatus(String shopId, String status) async {
    try {
      await _client
          .from('shops')
          .update({'status': status})
          .eq('id', shopId);
    } catch (e) {
      print('Error updating shop status: $e');
    }
  }

  // ── Customer Profile ──────────────────────────────────
  Future<Map<String, dynamic>?> getCustomerProfile(
      String customerId) async {
    try {
      return await _client
          .from('customers')
          .select('*')
          .eq('id', customerId)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentShops({int limit = 3}) async {
    try {
      final response = await _client
          .from('shops')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 4}) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, shops!inner(shop_name)')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getActiveBanners() async {
    try {
      // Assuming you have a banners table. Adjust table name if different.
      final response = await _client
          .from('banners')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Return empty if table doesn't exist yet
      return [];
    }
  }

  // ── Dashboard Metrics ─────────────────────────────────
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      final orders = await getAllOrders();
      final shops = await getShops();
      final riders = await getDeliveryPartners();

      int totalOrders = orders.length;
      int readyOrders = orders.where((o) =>
          o['status'] == 'ready' ||
          o['status'] == 'pending' ||
          o['status'] == 'placed').length;
      int activeDeliveries =
          orders.where((o) => o['status'] == 'out_for_delivery').length;
      int delivered =
          orders.where((o) => o['status'] == 'delivered').length;
          
      // New counts for Donut Chart
      int pendingCount = orders.where((o) => o['status'] == 'pending' || o['status'] == 'placed').length;
      int preparingCount = orders.where((o) => o['status'] == 'accepted' || o['status'] == 'ready').length;
      int pickedUpCount = orders.where((o) => o['status'] == 'out_for_delivery').length;
      int cancelledCount = orders.where((o) => o['status'] == 'cancelled').length;

      double totalRevenue = 0;
      for (var o in orders) {
        if (o['status'] == 'delivered') {
          totalRevenue +=
              (o['total_amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return {
        'totalOrders': totalOrders,
        'readyOrders': readyOrders,
        'activeDeliveries': activeDeliveries,
        'delivered': delivered,
        'totalRevenue': totalRevenue,
        'totalShops': shops.length,
        'totalRiders': riders.length,
        'chartPending': pendingCount,
        'chartPreparing': preparingCount,
        'chartPickedUp': pickedUpCount,
        'chartDelivered': delivered,
        'chartCancelled': cancelledCount,
      };
    } catch (e) {
      return {
        'totalOrders': 0,
        'readyOrders': 0,
        'activeDeliveries': 0,
        'delivered': 0,
        'totalRevenue': 0.0,
        'totalShops': 0,
        'totalRiders': 0,
        'chartPending': 0,
        'chartPreparing': 0,
        'chartPickedUp': 0,
        'chartDelivered': 0,
        'chartCancelled': 0,
      };
    }
  }
}
