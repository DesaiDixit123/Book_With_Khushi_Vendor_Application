import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../withdrawals_controller.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/app_drawer.dart';

class MakeRequestScreen extends StatelessWidget {
  const MakeRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // If navigating directly, we might need to find the controller or put it.
    // Assuming WithdrawalsScreen put it already, but we'll use Get.find().
    // We'll use Get.put in case user navigates here directly.
    final controller = Get.put(WithdrawalsController());

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Make a Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.navyBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dividerLight),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Make a Withdrawal Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Balance : ₹${controller.balance.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                // Note Banner showing Min & Max withdrawal limits set from admin
                Obx(() {
                  final method = controller.selectedMethod;
                  final minLimit = method != null ? (method['min_limit'] ?? 0) : 50;
                  final maxLimit = method != null ? (method['max_limit'] ?? 50000) : 50000;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.maroon.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.maroon.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.maroon, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Note: Minimum withdrawal limit is ₹$minLimit and Maximum withdrawal limit is ₹$maxLimit.',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.maroon,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Amount Input
                const Text('Withdraw Amount*', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLight)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Enter Withdraw Amount',
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.dividerLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.dividerLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.maroon),
                    ),
                  ),
                ),
                // Instant Error Message
                Obx(() {
                  if (controller.amountErrorText.value.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      controller.amountErrorText.value,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),

                // Live Calculation Text
                Obx(() => Text(
                  'You will receive : ₹${controller.payableAmount.value.toStringAsFixed(2)}, Total Charge : ₹${controller.totalCharge.value.toStringAsFixed(2)}, Your Balance will be: ₹${controller.remainingBalance.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                )),
                const SizedBox(height: 20),

                // Reference Input
                const Text('Additional Reference (Optional)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLight)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.referenceController,
                  decoration: InputDecoration(
                    hintText: 'Enter Additional Reference',
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.dividerLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.dividerLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.maroon),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button with Loading & Disabled State
                Obx(() {
                  final enabled = controller.isSubmitEnabled;
                  final submitting = controller.isSubmitting.value;

                  return Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: enabled ? controller.requestWithdrawal : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          disabledBackgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Send Request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: enabled ? Colors.white : Colors.white70,
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }),
    );
  }
}
