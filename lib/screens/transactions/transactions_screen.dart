import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'transactions_controller.dart';
import '../../constants/app_colors.dart';
import '../../widgets/app_drawer.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransactionsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions History'),
      ),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.transactionsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No transactions found.', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchTransactions,
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: controller.transactionsList.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final transaction = controller.transactionsList[index];
              return _buildTransactionItem(context, transaction);
            },
          ),
        );
      }),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> transaction) {
    final rawType = transaction['transcation_type'];
    final status = transaction['payment_status']?.toString().toLowerCase() ?? '';
    
    final preBal = double.tryParse(transaction['pre_balance']?.toString() ?? '0') ?? 0.0;
    final afterBal = double.tryParse(transaction['after_balance']?.toString() ?? '0') ?? 0.0;

    // Type 1 = Booking Credit, Type 3 = Admin Added Balance Credit
    final isCredit = rawType == 1 || rawType == 3 || rawType == '1' || rawType == '3' || (afterBal > preBal && rawType != 2 && rawType != 4);

    final isCompleted = status == 'completed' || status == 'success' || status == 'approved' || status == '1';

    final amountColor = isCredit ? AppColors.success : AppColors.error;
    final amountSign = isCredit ? '+' : '-';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: amountColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: amountColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction['transaction_id']?.toString() ?? 'TRX-UNKNOWN',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Method: ${transaction['payment_method'] ?? 'System'}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                transaction['created_at']?.toString() ?? '',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$amountSign${transaction['currency_symbol'] ?? '₹'}${transaction['actual_total']}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: amountColor),
            ),
            const SizedBox(height: 4),
            Text(
              isCompleted ? 'Success' : 'Pending',
              style: TextStyle(
                color: isCompleted ? AppColors.success : AppColors.golden,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ],
    );
  }
}
