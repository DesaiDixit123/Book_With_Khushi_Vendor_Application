import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'withdrawals_controller.dart';
import '../../constants/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../routes/app_routes.dart';
class WithdrawalsScreen extends StatelessWidget {
  const WithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WithdrawalsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Withdrawals'),
      ),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.fetchWithdrawals,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildBalanceCard(context, controller),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Requests', style: Theme.of(context).textTheme.titleLarge),
                  if (controller.withdrawals.isNotEmpty)
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.transactions),
                      child: const Text('View All'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (controller.withdrawals.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('No withdrawal requests found.', style: TextStyle(color: Colors.grey))),
                )
              else
                ...controller.withdrawals.map((w) => _buildWithdrawalCard(w)),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navyBlue,
        onPressed: () => Get.toNamed(AppRoutes.makeRequest),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Request Payout', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, WithdrawalsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.maroon,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.maroon.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Text('AVAILABLE BALANCE', style: TextStyle(color: Colors.white70, letterSpacing: 1.5, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '₹${controller.balance.value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalCard(Map<String, dynamic> withdrawal) {
    Color statusColor;
    String statusText;
    switch (withdrawal['status']) {
      case 1:
        statusColor = AppColors.success;
        statusText = 'Approved';
        break;
      case 2:
        statusColor = AppColors.error;
        statusText = 'Rejected';
        break;
      default:
        statusColor = AppColors.golden;
        statusText = 'Pending';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(withdrawal['withdraw_id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(withdrawal['created_at'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Requested Amount', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('₹${withdrawal['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Payable: ₹${withdrawal['payable_amount']}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
