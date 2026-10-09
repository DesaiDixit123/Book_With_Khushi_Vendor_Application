import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'subscription_controller.dart';
import '../../widgets/app_drawer.dart';
import '../../routes/app_routes.dart';
import '../../constants/app_colors.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SubscriptionController());

    return Scaffold(
      backgroundColor: AppColors.beigeCream,
      appBar: AppBar(
        title: const Text('Buy Plan'),
      ),
      drawer: const AppDrawer(),
      body: Obx(() {
        // Removed full screen loading indicator for instant UI load
        return RefreshIndicator(
          onRefresh: controller.fetchSubscriptionData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show warning only if no current membership
              if (controller.currentMembership.value == null) ...[
                _buildWarningBanner(),
                const SizedBox(height: 20),
              ],
              // Show active plan badge if membership exists
              if (controller.currentMembership.value != null) ...[
                _buildActiveMembershipBadge(controller.currentMembership.value!),
                const SizedBox(height: 20),
              ],
              Text(
                'Available Plans',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.packages.length,
                itemBuilder: (context, index) {
                  return _buildPackageCard(context, controller.packages[index]);
                },
              ),
            ],
          ),
        ),
      );
      }),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Colors.orange, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No Active Membership',
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text(
                  'You currently do not have an active membership. Purchase a plan below to start adding spaces.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMembershipBadge(Map<String, dynamic> membership) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.success, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Plan: ${membership['package_title'] ?? membership['title'] ?? 'Current Plan'}',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (membership['expire_date'] != null)
                  Text('Expires: ${membership['expire_date']}',
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, Map<String, dynamic> pkg) {
    final price = double.tryParse(pkg['price']?.toString() ?? '0') ?? 0;

    final features = [
      {
        'title': 'Spaces Included : ${pkg['number_of_space'] == 999999 ? 'Unlimited' : (pkg['number_of_space'] ?? 0)}', 
        'included': true
      },
      {
        'title': 'Slider Images Per Space : ${pkg['number_of_slider_image_per_space'] == 999999 ? 'Unlimited' : 'Up to ${pkg['number_of_slider_image_per_space'] ?? 0}'}',
        'included': true
      },
      {
        'title': 'Services Per Space : ${pkg['number_of_service_per_space'] == 999999 ? 'Unlimited' : 'Up to ${pkg['number_of_service_per_space'] ?? 0}'}',
        'included': true
      },
      {
        'title': 'Variants Per Service : ${pkg['number_of_option_per_service'] == 999999 ? 'Unlimited' : 'Up to ${pkg['number_of_option_per_service'] ?? 0}'}',
        'included': true
      },
      {
        'title': 'Amenities Per Space : ${pkg['number_of_amenities_per_space'] == 999999 ? 'Unlimited' : 'Up to ${pkg['number_of_amenities_per_space'] ?? 0}'}',
        'included': true
      },
      {
        'title': 'Support Tickets', 
        'included': (pkg['package_feature'] as List?)?.contains('Support Tickets') ?? false
      },
      {
        'title': 'Manual Booking Entry from Dashboard', 
        'included': (pkg['package_feature'] as List?)?.contains('Add Booking') ?? false
      },
      {
        'title': 'Fixed Timeslot Rental', 
        'included': (pkg['package_feature'] as List?)?.contains('Fixed Timeslot Rental') ?? false
      },
      {
        'title': 'Hourly Rental', 
        'included': (pkg['package_feature'] as List?)?.contains('Hourly Rental') ?? false
      },
      {
        'title': 'Multi-Day Rental', 
        'included': (pkg['package_feature'] as List?)?.contains('Multi Day Rental') ?? false
      },
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Header — Package name + price in one clean row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              color: AppColors.navyBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  pkg['title']?.toString() ?? 'Package',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.golden,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${pkg['price']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/${pkg['term'] ?? 'term'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Features List
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              children: features.map((feature) {
                final isIncluded = feature['included'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 1),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isIncluded ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                        ),
                        child: Icon(
                          isIncluded ? Icons.check : Icons.close,
                          color: isIncluded ? Colors.white : Colors.grey,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature['title'] as String,
                          style: TextStyle(
                            color: isIncluded ? Colors.black87 : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Buy Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final Map<String, dynamic> checkoutData = Map<String, dynamic>.from(pkg);
                  final subController = Get.find<SubscriptionController>();
                  checkoutData['subscription_gst'] = subController.subscriptionGst.value;
                  Get.toNamed(AppRoutes.checkout, arguments: checkoutData);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.maroon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
