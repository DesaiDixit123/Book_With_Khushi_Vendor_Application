import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'checkout_controller.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CheckoutController());
    final pkg = controller.package;
    final price = pkg['price']?.toString() ?? '0';
    final term = pkg['term'] ?? 'term';

    final basePrice = double.tryParse(price) ?? 0.0;
    final gstRate = double.tryParse(pkg['subscription_gst']?.toString() ?? '0') ?? 0.0;
    final gstAmount = (basePrice * gstRate) / 100;
    final totalAmount = basePrice + gstAmount;

    final basePriceFormatted = basePrice % 1 == 0 ? basePrice.toInt().toString() : basePrice.toStringAsFixed(2);
    final gstAmountFormatted = gstAmount % 1 == 0 ? gstAmount.toInt().toString() : gstAmount.toStringAsFixed(2);
    final totalAmountFormatted = totalAmount % 1 == 0 ? totalAmount.toInt().toString() : totalAmount.toStringAsFixed(2);
    final gstRateFormatted = gstRate % 1 == 0 ? gstRate.toInt().toString() : gstRate.toString();

    // Calculate dates
    final startDate = DateTime.now();
    DateTime expireDate;
    switch (term) {
      case 'yearly':
        expireDate = startDate.add(const Duration(days: 365));
        break;
      case 'lifetime':
        expireDate = DateTime(startDate.year + 100);
        break;
      case 'days':
        final days = int.tryParse(pkg['trial_days']?.toString() ?? '30') ?? 30;
        expireDate = startDate.add(Duration(days: days));
        break;
      default: // monthly
        expireDate = startDate.add(const Duration(days: 30));
    }

    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.beigeCream,
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Package summary card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.navyBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    pkg['title']?.toString() ?? 'Package',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹$price',
                        style: const TextStyle(
                          color: AppColors.golden,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          ' /$term',
                          style: const TextStyle(color: Colors.white60, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  _buildInfoRow('Plan', pkg['title']?.toString() ?? '-'),
                  const SizedBox(height: 10),
                  _buildInfoRow('Start Date', dateFormat.format(startDate)),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    'Expire Date',
                    term == 'lifetime' ? 'Lifetime' : dateFormat.format(expireDate),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow('Spaces Included', pkg['number_of_space'] == 999999 ? 'Unlimited' : '${pkg['number_of_space'] ?? 0}'),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),
                  
                  _buildInfoRow('Base Price', '₹$basePriceFormatted'),
                  const SizedBox(height: 10),
                  _buildInfoRow('GST ($gstRateFormatted%)', gstRate > 0 ? '+ ₹$gstAmountFormatted' : '₹0'),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),
                  _buildInfoRow('Total Amount', '₹$totalAmountFormatted'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Method
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      color: AppColors.navyBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Razorpay option — only one option since it's configured
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.beigeCream,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.maroon, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.payment, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Razorpay',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navyBlue,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'UPI, Cards, Netbanking & Wallets',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle, color: AppColors.maroon, size: 22),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Note about test mode
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Test Mode: Use card 4111 1111 1111 1111, any future expiry, any CVV.',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.checkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.maroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Pay ₹$totalAmountFormatted via Razorpay',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              )),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
