import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'holidays_controller.dart';
import '../../widgets/app_drawer.dart';
import '../../constants/app_colors.dart';
import '../../routes/app_routes.dart';

class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  late HolidaysController controller;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    controller = Get.put(HolidaysController());
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase().trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holidays'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => controller.selectDateRange(context),
            tooltip: 'Filter by Date',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addHoliday),
        backgroundColor: AppColors.maroon,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Holiday',
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
                hintText: 'Search by date (e.g. 2026-06-01)...',
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
          // ── Date Range Filter Chip ──
          Obx(() {
            if (controller.startDate.value != null && controller.endDate.value != null) {
              final start = controller.startDate.value!.toString().split(' ')[0];
              final end = controller.endDate.value!.toString().split(' ')[0];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filtered: $start to $end',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroon),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: controller.clearFilter,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          // ── List ──────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtered = controller.holidaysList
                  .where((h) => (h['date'] ?? '').toString().toLowerCase().contains(_query))
                  .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 72, color: AppColors.navyBlue.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        _query.isNotEmpty ? 'NO RESULTS FOUND' : 'NO HOLIDAY FOUND!',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                            color: Colors.grey, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _query.isNotEmpty
                            ? 'No holiday matches "$_query"'
                            : 'Tap the button below to add a holiday date.',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.fetchHolidays,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final holiday = filtered[index];
                    return _HolidayCard(
                      holiday: holiday,
                      onDelete: () => _confirmDelete(context, controller, holiday['id']),
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

  void _confirmDelete(
      BuildContext context, HolidaysController controller, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Holiday'),
        content: const Text('Are you sure you want to delete this holiday?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteHoliday(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _HolidayCard extends StatelessWidget {
  final Map<String, dynamic> holiday;
  final VoidCallback onDelete;

  const _HolidayCard({required this.holiday, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.navyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event, color: AppColors.navyBlue, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                holiday['date'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyBlue,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
