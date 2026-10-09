import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'coupons_controller.dart';
import '../../widgets/app_drawer.dart';
import '../../constants/app_colors.dart';
import '../../routes/app_routes.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  late CouponsController controller;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    controller = Get.put(CouponsController());
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase().trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> _filterList(List<dynamic> list) {
    if (_query.isEmpty) return list;
    return list.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final code = (c['code'] ?? '').toString().toLowerCase();
      return name.contains(_query) || code.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addCoupon),
        backgroundColor: AppColors.maroon,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Coupon',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // ── Search Bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by coupon name or code...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
          ),
          // ── List ──────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtered = _filterList(controller.couponsList);

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.confirmation_num_outlined,
                          size: 72, color: AppColors.navyBlue.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        _query.isNotEmpty ? 'NO RESULTS FOUND' : 'NO COUPON FOUND!',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                            color: Colors.grey, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _query.isNotEmpty
                            ? 'No coupon matches "$_query"'
                            : 'Tap the button below to create a coupon.',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.fetchCoupons,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final coupon = filtered[index];
                    return _CouponCard(
                      coupon: coupon,
                      onEdit: () => Get.toNamed(AppRoutes.editCoupon, arguments: coupon),
                      onDelete: () => _confirmDelete(context, coupon['id']),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: const Text('Are you sure you want to delete this coupon?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteCoupon(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Map<String, dynamic> coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CouponCard({required this.coupon, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final code = (coupon['code'] ?? '').toString();
    final type = (coupon['coupon_type'] ?? 'fixed').toString();
    final value = (coupon['value'] ?? '0').toString();
    final isPercent = type == 'percentage';

    // Calculate status based on dates
    String status = 'Active';
    Color statusColor = AppColors.success;
    
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final startDateStr = coupon['start_date'] ?? '';
      final endDateStr = coupon['end_date'] ?? '';
      
      if (startDateStr.isNotEmpty && endDateStr.isNotEmpty) {
        final startDate = DateTime.parse(startDateStr);
        final endDate = DateTime.parse(endDateStr);
        
        if (today.isBefore(startDate)) {
          status = 'Pending';
          statusColor = Colors.orange;
        } else if (today.isAfter(endDate)) {
          status = 'Expired';
          statusColor = Colors.red;
        }
      }
    } catch (e) {
      // Fallback to active if parsing fails
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.navyBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.navyBlue.withOpacity(0.3)),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyBlue, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPercent ? '$value% OFF' : '₹$value OFF',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    coupon['name'] ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Validity: ${coupon['start_date']} to ${coupon['end_date']}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.info),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outlined, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
