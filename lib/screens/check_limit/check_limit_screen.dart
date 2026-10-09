import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import 'check_limit_controller.dart';

class CheckLimitScreen extends StatelessWidget {
  const CheckLimitScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CheckLimitController controller = Get.put(CheckLimitController());

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Check Limit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.navyBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchLimits(),
        color: AppColors.maroon,
        backgroundColor: Colors.white,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
          }

          final limits = controller.limitsData;
          if (limits.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Text('No limits available.', style: TextStyle(color: AppColors.textLight)),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPackageCard(controller.packageName.value),
                const SizedBox(height: 20),
                const Text(
                  'Current Limits',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSpaceLimitCard(limits['spaces']),
                const SizedBox(height: 12),
                _buildStandardLimitCard(
                  title: 'Services Per Space Limit',
                  limitValue: limits['services_per_space']?['limit'],
                  icon: Icons.design_services,
                ),
                const SizedBox(height: 12),
                _buildStandardLimitCard(
                  title: 'Options Per Service Limit',
                  limitValue: limits['options_per_service']?['limit'],
                  icon: Icons.list_alt,
                ),
                const SizedBox(height: 12),
                _buildStandardLimitCard(
                  title: 'Slider Images Per Space Limit',
                  limitValue: limits['slider_images_per_space']?['limit'],
                  icon: Icons.photo_library,
                ),
                const SizedBox(height: 12),
                _buildStandardLimitCard(
                  title: 'Amenities Per Space Limit',
                  limitValue: limits['amenities_per_space']?['limit'],
                  icon: Icons.star_border,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPackageCard(String packageName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.maroon,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyBlue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Active Package',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            packageName,
            style: const TextStyle(
              color: AppColors.golden,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceLimitCard(dynamic spaceData) {
    if (spaceData == null) return const SizedBox.shrink();

    int limit = int.tryParse(spaceData['limit'].toString()) ?? 0;
    int used = int.tryParse(spaceData['used'].toString()) ?? 0;
    double progress = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
    
    // Determine color based on usage
    Color progressColor = AppColors.success;
    if (progress > 0.8) {
      progressColor = AppColors.error; // Red if almost full
    } else if (progress > 0.5) {
      progressColor = Colors.orange; // Orange if half full
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_work, color: AppColors.maroon),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Spaces Limit',
                  style: TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '$used / $limit',
                style: const TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.beigeCream,
              color: progressColor,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardLimitCard({required String title, required dynamic limitValue, required IconData icon}) {
    String displayLimit = (limitValue == null || limitValue == 999999 || limitValue == -1) 
        ? 'Unlimited' 
        : limitValue.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.maroon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.beigeCream,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              displayLimit,
              style: const TextStyle(
                color: AppColors.navyBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
