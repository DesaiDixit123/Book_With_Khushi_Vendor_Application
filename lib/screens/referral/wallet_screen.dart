import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/snackbar_helper.dart';
import 'referral_controller.dart';
import 'bank_details_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final VendorReferralController controller = Get.put(VendorReferralController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reward Wallet'),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.fetchReferralData();
          await controller.fetchWalletTransactions();
          await controller.fetchBankDetails();
        },
        color: AppColors.navyBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance display card
              Obx(() {
                final double cash = controller.availableBalance.value * controller.pointValue.value;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.navyBlue, AppColors.maroon],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyBlue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Available Reward Balance",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${controller.availableBalance.value} Points",
                        style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "≈ ₹${cash.toStringAsFixed(2)}",
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat("Total Earned", "${controller.totalEarned.value} Pts"),
                          _buildMiniStat("Total Redeemed", "${controller.totalRedeemed.value} Pts"),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Action Buttons
              Obx(() {
                final hasBank = controller.isBankConfigured.value;
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRedeemBottomSheet(context, controller),
                        icon: const Icon(Icons.outbox, color: Colors.white),
                        label: const Text("Redeem", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.to(() => const BankDetailsScreen()),
                        icon: Icon(hasBank ? Icons.account_balance : Icons.account_balance_outlined, color: Colors.white),
                        label: Text(hasBank ? "Bank Configured" : "Setup Bank", style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasBank ? AppColors.navyBlue : Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 28),

              // Ledger Transactions List
              const Text(
                "Transaction Ledger Logs",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Obx(() {
                if (controller.isWalletLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: CircularProgressIndicator(color: AppColors.navyBlue),
                    ),
                  );
                }

                if (controller.walletTransactions.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.history_toggle_off_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("No transaction logs recorded.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.walletTransactions.length,
                  itemBuilder: (context, index) {
                    final tx = controller.walletTransactions[index];
                    final amount = tx['amount'] as num? ?? 0;
                    final isCredit = amount > 0;
                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCredit ? Colors.green.shade50 : Colors.red.shade50,
                          child: Icon(
                            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isCredit ? Colors.green : Colors.red,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          tx['description'] ?? 'Transaction',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              tx['created_at'] != null ? tx['created_at'].toString().split('T')[0] : '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (tx['redeem_request'] != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusBgColor(tx['redeem_request']['status']),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tx['redeem_request']['status'].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getStatusTextColor(tx['redeem_request']['status']),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (tx['redeem_request']['status'] == 'rejected' && tx['redeem_request']['remark'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Reason: ${tx['redeem_request']['remark']}",
                                  style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ],
                        ),
                        trailing: Text(
                          "${isCredit ? '+' : ''}$amount Pts",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isCredit ? Colors.green : Colors.red),
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showRedeemBottomSheet(BuildContext context, VendorReferralController controller) {
    if (!controller.isBankConfigured.value) {
      SnackbarHelper.showError("Please configure bank details first.");
      return;
    }

    if (controller.availableBalance.value <= 0) {
      SnackbarHelper.showError("Insufficient points! You have 0 points available in your reward wallet.");
      return;
    }

    final pointsController = TextEditingController();
    final rxError = ''.obs;

    void validateInput(String val) {
      final text = val.trim();
      if (text.isEmpty) {
        rxError.value = "Please enter points to redeem";
        return;
      }
      final pts = int.tryParse(text);
      if (pts == null || pts <= 0) {
        rxError.value = "Please enter a valid points amount";
        return;
      }
      if (pts > controller.availableBalance.value) {
        rxError.value = "Insufficient balance! You only have ${controller.availableBalance.value} Pts available.";
        return;
      }
      if (pts < controller.minRedeemPoints.value) {
        rxError.value = "Minimum redemption amount is ${controller.minRedeemPoints.value} Pts.";
        return;
      }
      rxError.value = '';
    }

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Redeem Reward Points", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Obx(() => Text(
                "Available: ${controller.availableBalance.value} Pts | Min: ${controller.minRedeemPoints.value} Pts. Rate: 1 Point = ₹${controller.pointValue.value}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              )),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: validateInput,
                decoration: const InputDecoration(
                  labelText: "Points amount",
                  prefixIcon: Icon(Icons.star),
                  border: OutlineInputBorder(),
                ),
              ),
              Obx(() {
                if (rxError.value.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      rxError.value,
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 24),
              Obx(() {
                final isSubmitting = controller.isLoading.value;
                final text = pointsController.text.trim();
                final pts = int.tryParse(text) ?? 0;
                final isValid = text.isNotEmpty &&
                    pts > 0 &&
                    pts <= controller.availableBalance.value &&
                    pts >= controller.minRedeemPoints.value &&
                    rxError.value.isEmpty;

                return ElevatedButton(
                  onPressed: (!isValid || isSubmitting)
                      ? null
                      : () async {
                          final success = await controller.submitRedeemRequest(pts);
                          if (success) {
                            Get.back();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid ? AppColors.navyBlue : Colors.grey.shade400,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("SUBMIT REQUEST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                );
              }),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Color _getStatusBgColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange.withOpacity(0.15);
      case 'approved':
        return Colors.green.withOpacity(0.15);
      case 'paid':
        return Colors.blue.withOpacity(0.15);
      case 'rejected':
        return Colors.red.withOpacity(0.15);
      default:
        return Colors.grey.withOpacity(0.15);
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade800;
      case 'approved':
        return Colors.green.shade800;
      case 'paid':
        return Colors.blue.shade800;
      case 'rejected':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }
}
