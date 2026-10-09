import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_drawer.dart';
import '../../../constants/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import 'subscription_log_controller.dart';

class SubscriptionLogScreen extends StatelessWidget {
  const SubscriptionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SubscriptionLogController());

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Log')),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No subscription logs found.', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchLogs,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.logs.length,
            itemBuilder: (context, index) {
              final log = controller.logs[index];
              return _buildLogItem(context, log, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildLogItem(BuildContext context, Map<String, dynamic> log, SubscriptionLogController controller) {
    final bool isActive = log['status'] == 'Active';
    final Color statusColor = isActive ? AppColors.success : (log['status'] == 'Pending' ? AppColors.golden : AppColors.error);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    log['package_name'] ?? 'Unknown Package',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    log['status'] ?? 'Unknown',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (log['tax'] != null && (double.tryParse(log['tax'].toString()) ?? 0.0) > 0) ...[
                        _buildBreakdownRow('Base Price', '${log['currency_symbol'] ?? '₹'}${log['base_price']}'),
                        if (log['cgst'] != null && (double.tryParse(log['cgst'].toString()) ?? 0.0) > 0)
                          _buildBreakdownRow('CGST', '${log['currency_symbol'] ?? '₹'}${log['cgst']}'),
                        if (log['sgst'] != null && (double.tryParse(log['sgst'].toString()) ?? 0.0) > 0)
                          _buildBreakdownRow('SGST', '${log['currency_symbol'] ?? '₹'}${log['sgst']}'),
                        if (log['igst'] != null && (double.tryParse(log['igst'].toString()) ?? 0.0) > 0)
                          _buildBreakdownRow('IGST', '${log['currency_symbol'] ?? '₹'}${log['igst']}'),
                        const SizedBox(
                          width: 120,
                          child: Divider(height: 8),
                        ),
                        _buildBreakdownRow('Total Price', '${log['currency_symbol'] ?? '₹'}${log['price']}', isBold: true),
                      ] else ...[
                        const Text('Price', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${log['currency_symbol'] ?? '₹'}${log['price']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Payment Method', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      log['payment_method'] ?? 'Offline',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDateColumn('Start Date', log['start_date']),
                  _buildDateColumn('Expire Date', log['expire_date']),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('Created on: ${log['created_at']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () async {
                    final apiService = Get.find<ApiService>();
                    final storage = Get.find<StorageService>();
                    final token = await storage.getToken();
                    String url = log['invoice_url'] ?? '${apiService.baseUrl}/vendor/subscription/invoice/${log['id']}';
                    if (token != null && !url.contains('?token=')) {
                      url += (url.contains('?') ? '&' : '?') + 'token=$token';
                    }
                    controller.downloadInvoice(url);
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                  label: const Text('Invoice', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateColumn(String label, String? date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(date ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              color: isBold ? Colors.black87 : Colors.grey[800],
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
